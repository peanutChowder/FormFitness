import AVFoundation
import Combine
import Vision
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var setupError: String?
    @Published var liveTrackingFrame: UIImage?
    @Published var staticPose: UIImage?
    @Published var poseOffset: CGPoint = .zero
    @Published var tempPosition: CGPoint = .zero
    
    private var cameraViewSize: CGSize = .zero

    private var initialPoseOffset: CGPoint?
    private let movementScaleFactor: CGFloat = 0.5 // Adjust this value to control movement sensitivity

    private var cancellables = Set<AnyCancellable>()
    private let poseDetector = PoseDetector()
    private var currentPose: String = ""
    private var pixelBufferSize: CGSize = .zero
    
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
    
    func setStaticPoseImg(pose: VNHumanBodyPoseObservation) -> UIImage? {
        if self.pixelBufferSize == .zero {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(self.pixelBufferSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        #warning ("TODO: fix image sizing")
        context.setFillColor(UIColor.black.withAlphaComponent(0.0).cgColor)
        context.fill(CGRect(origin: .zero, size: self.pixelBufferSize))
        
        // Draw static pose
        poseDetector.drawStaticPose(context: context, perfectFormPose: pose, imageSize: self.pixelBufferSize)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Pass static pose image to UI
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
            poseDetector.drawLivePose(pose: livePose, context: context, imageSize: currPixelBufferSize)
            
            // TODO: delete -- testing
//            poseDetector.testDrawDotAtOrigin(context: context)
            
            #warning("TODO: temporary setup for pose offset calculation")
            // TODO: seems like cameraViewSize is the proper scaling factor
            let tempPoint = self.poseDetector.getJointCoord(for: .rightWrist, in: livePose, on: context, size: cameraViewSize)
            
            
            if tempPoint != .zero {
                if let normalizedHandOffset = poseDetector.calcNormalizedStaticJointOffset(staticPose: staticPose, joint: .rightWrist) {
                    
                    let xi = tempPoint.x + normalizedHandOffset.x * cameraViewSize.width
                    let yi = tempPoint.y + normalizedHandOffset.y * cameraViewSize.height
                    DispatchQueue.main.async {
                        self.tempPosition = CGPoint(x: xi, y: yi)
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

