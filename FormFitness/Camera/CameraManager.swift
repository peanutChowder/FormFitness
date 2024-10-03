import AVFoundation
import Combine
import Vision
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var liveTrackingFrame: UIImage?
    @Published var staticPose: UIImage?
    @Published var staticPoseCenter: CGPoint = .zero
    
    private let poseDetector = PoseDetector()
    private var currentPose: String = ""
    
    private var cameraViewSize: CGSize = .zero
    private var pixelBufferSize: CGSize = .zero

    private var isStaticPoseFollowing = false;
    private var poseFollowJoint: VNHumanBodyPoseObservation.JointName = .rightWrist
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            logger.error("CameraManager: Failed to get front camera device")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                logger.error("CameraManager: Failed to add camera input to session")
                return
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(output) {
                session.addOutput(output)
                
                if let connection = output.connection(with: .video) {
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = true
                    } else {
                        logger.error("CameraManager: video mirroring not supported")
                    }
                    
                    connection.videoRotationAngle = phoneOrientationToVideoAngle()
                }
            } else {
                logger.error("CameraManager: Failed to add video output to session")
                return
            }
        } catch {
            logger.error("CameraManager: Failed to create camera input: \(error.localizedDescription)")
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func setCameraViewSize(cameraViewSize: CGSize) {
        self.cameraViewSize = cameraViewSize
    }
    
    func setIsStaticPoseFollowing(to isStaticPoseFollowing: Bool) {
        logger.info("CameraManager: isStaticPoseFollowing set to \(isStaticPoseFollowing)")
        self.isStaticPoseFollowing = isStaticPoseFollowing
    }
    
    func setStaticPoseImg(pose: VNHumanBodyPoseObservation) -> UIImage? {
        if self.pixelBufferSize == .zero {
            return nil
        }
        
        // calculate a scaling factor to magnify the static pose pixel buffer by without stretching
        // the image in one axis or overflowing the screen size
        guard let originalImgSize = PerfectFormManager.shared.perfectForms[self.currentPose]?.image.size else { return nil }
        let scalar = calcMaxImageScalingWithoutOverflow(fullViewSize: UIScreen.main.bounds.size, imgSize: originalImgSize)
        logger.info("CameraManager: Static pose scaled \(scalar)x. Original size \(originalImgSize.width)x\(originalImgSize.height), screen size: \(UIScreen.main.bounds.size.width)x\(UIScreen.main.bounds.size.height)")
        let scaledPoseSize = CGSize(
            width: originalImgSize.width * scalar * UIScreen.main.scale,
            height: originalImgSize.height * scalar * UIScreen.main.scale
        )
        
        UIGraphicsBeginImageContextWithOptions(self.pixelBufferSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        context.setFillColor(UIColor.black.withAlphaComponent(0.0).cgColor)
        context.fill(CGRect(origin: .zero, size: scaledPoseSize))

        // Draw static pose
        poseDetector.drawStaticPose(context: context, staticPose: pose, imageSize: scaledPoseSize)

        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return result
    }
    
    func phoneOrientationToVideoAngle() -> CGFloat {
        let phoneOrientation = UIDevice.current.orientation
        
        switch phoneOrientation {
        case .portrait:
            return 90
        case .landscapeLeft:
            return 180
        case .landscapeRight:
            return 0
        @unknown default:
            return 0
        }
    }
    
    func changePerfectFormPose(to pose: String) {
        self.currentPose = pose
        if let newStaticPose = PerfectFormManager.shared.perfectForms[pose]?.pose {
            DispatchQueue.main.async {
                self.staticPose = self.setStaticPoseImg(pose: newStaticPose)
            }
            return
        }
    }
    
    func refreshCurrentPose() {
        if self.currentPose.isEmpty {
            return
        }
        
        changePerfectFormPose(to: self.currentPose)
    }
    
    func resetStaticPosePosition() {
        logger.debug("CameraManager: Resetting static pose position")
        DispatchQueue.main.async {
            self.staticPoseCenter = CGPoint(x: self.cameraViewSize.width / 2, y: self.cameraViewSize.height / 2)
        }
    }
    func calcMaxImageScalingWithoutOverflow(fullViewSize: CGSize, imgSize: CGSize) -> CGFloat {
        let scaleWidth = fullViewSize.width / imgSize.width
        let scaleHeight = fullViewSize.height / imgSize.height
        
        return min(scaleWidth, scaleHeight)
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let currPixelBufferSize = CGSize(width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer))
        
        if currPixelBufferSize != self.pixelBufferSize {
            self.pixelBufferSize = currPixelBufferSize
            refreshCurrentPose()
        }
        
        UIGraphicsBeginImageContextWithOptions(currPixelBufferSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
                        
        // Draw the original image
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let uiImage = UIImage(ciImage: ciImage)
        
        uiImage.draw(in: CGRect(origin: .zero, size: currPixelBufferSize))
        
        if let livePose = poseDetector.detectPose(in: pixelBuffer),
           let staticPose = PerfectFormManager.shared.perfectForms[currentPose]?.pose {
            poseDetector.drawLivePoseColorRating(pose: livePose, staticPose: staticPose, context: context, imageSize: currPixelBufferSize, staticPoseCenter: staticPoseCenter)
            
            
            if isStaticPoseFollowing {
                let screenSize = UIScreen.main.bounds.size
                let liveJointAbsoluteCoords = self.poseDetector.getJointCoordinateFromContext(joint: poseFollowJoint, pose: livePose, context: context, size: screenSize)
                
                
                if liveJointAbsoluteCoords != .zero {
                    if let normalizedHandOffset = poseDetector.calcNormalizedStaticJointOffset(staticPose: staticPose, joint: poseFollowJoint) {
                        
                        let staticPoseAdjustedX = liveJointAbsoluteCoords.x - normalizedHandOffset.x * screenSize.width
                        let staticPoseAdjustedY = liveJointAbsoluteCoords.y + normalizedHandOffset.y * screenSize.height
                        DispatchQueue.main.async {
                            self.staticPoseCenter = CGPoint(x: staticPoseAdjustedX, y: staticPoseAdjustedY)
                        }
                    }
                }
            }
        }
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        DispatchQueue.main.async {
            self.liveTrackingFrame = result
        }
    }
 }

