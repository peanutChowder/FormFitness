import AVFoundation
import Combine
import Vision
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var setupError: String?
    @Published var liveTrackingFrame: UIImage?
    @Published var staticPose: UIImage?
    
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
    
    func setStaticPoseImg(pose: VNHumanBodyPoseObservation) -> UIImage? {
        if self.pixelBufferSize == .zero {
            return nil
        }
        
        UIGraphicsBeginImageContextWithOptions(self.pixelBufferSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // TODO: remove background
        context.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
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
        
        if let pose = poseDetector.detectPose(in: pixelBuffer) {
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
            
            poseDetector.drawLivePose(pose: pose, context: context, imageSize: currPixelBufferSize)
            let result = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            DispatchQueue.main.async {
                self.liveTrackingFrame = result
            }
        }
    }
}
