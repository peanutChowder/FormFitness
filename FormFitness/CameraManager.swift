//
//  CameraManager.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/1/24.
//

import AVFoundation
import Combine

class CameraManager: ObservableObject {
    @Published var session = AVCaptureSession()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupSession()
    }
    
    private func setupSession() {
        session.beginConfiguration()
        
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                print("camera access!!!")
            } else {
                print("Camera access denied")
            }
        }
        
        
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: camera) else {
            print("Failed to set up camera")
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        session.commitConfiguration()
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }
    
    func toggleCamera() {
        session.beginConfiguration()
        
        // Remove existing input
        guard let currentInput = session.inputs.first as? AVCaptureDeviceInput else { return }
        session.removeInput(currentInput)
        
        // Add new input
        let newPosition: AVCaptureDevice.Position = currentInput.device.position == .back ? .front : .back
        guard let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: newPosition),
              let newInput = try? AVCaptureDeviceInput(device: newCamera) else { return }
        
        if session.canAddInput(newInput) {
            session.addInput(newInput)
        }
        
        session.commitConfiguration()
    }
}
