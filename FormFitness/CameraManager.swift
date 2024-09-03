import AVFoundation
import Combine
import Vision
import UIKit

class CameraManager: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var setupError: String?
    @Published var currentFrame: UIImage?
    
    private var cancellables = Set<AnyCancellable>()
    private let poseDetector = PoseDetector()
    private var currentPerfectFormPose: String = "downward-dog"
    
    override init() {
        super.init()
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            setupError = "Failed to get front camera device"
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                setupError = "Failed to add camera input to session"
                return
            }
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            if session.canAddOutput(output) {
                session.addOutput(output)
            } else {
                setupError = "Failed to add video output to session"
                return
            }
        } catch {
            setupError = "Failed to create camera input: \(error.localizedDescription)"
            return
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func changePerfectFormPose(to pose: String) {
           currentPerfectFormPose = pose
       }
   }

   extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
       func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
           guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
           
           if let pose = poseDetector.detectPose(in: pixelBuffer),
              let perfectFormPose = PerfectFormManager.shared.perfectForms[currentPerfectFormPose]?.pose,
              let poseImage = poseDetector.drawPoseOverlay(pose: pose, on: pixelBuffer, perfectFormPose: perfectFormPose) {
               DispatchQueue.main.async {
                   self.currentFrame = poseImage
               }
           }
       }
   }
