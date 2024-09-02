//
//  ContentView.swift
//  FormFitness
//
//  Created by Jacob Feng on 8/31/24.
//

import SwiftUI
import AVFoundation
import Vision

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @State private var orientation = UIDeviceOrientation.unknown
    
    var isLandscapeRight: Bool {
        return orientation == .landscapeRight
    }
    @State private var selectedPose = "warrior"
    @State private var availablePoses: [String] = []

    
    var body: some View {
        ZStack {
            if let error = cameraManager.setupError {
                Text("Camera Error: \(error)")
                    .foregroundColor(.black)
                    .padding()
            } else if isLandscapeRight {
                if let currentFrame = cameraManager.currentFrame {
                    Image(uiImage: currentFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .edgesIgnoringSafeArea(.all)
                } else {
                    CameraView(session: cameraManager.session)
                        .edgesIgnoringSafeArea(.all)
                }
                
                VStack {
                    Spacer()
                    if availablePoses.isEmpty {
                        Text("No poses available")
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.7))
                    } else {
                        Picker("Select Pose", selection: $selectedPose) {
                            ForEach(availablePoses, id: \.self) { pose in
                                Text(pose.capitalized)
                                    .foregroundColor(.black) // Ensure text is visible
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding()
                        .background(Color.white.opacity(0.7))
                    }
                }
            } else {
                RotationPromptView()
            }
        }.onRotate { newOrientation in
            orientation = newOrientation
        }
        .onChange(of: selectedPose) { _, newPose in
            cameraManager.changePerfectFormPose(to: newPose)
        }
        .onAppear {
            PerfectFormManager.shared.loadPerfectForms()
            self.availablePoses = Array(PerfectFormManager.shared.perfectForms.keys)
            if let firstPose = availablePoses.first {
                self.selectedPose = firstPose
            }
            
            // Diagnostic logger.debug
            logger.debug("Available poses: \(availablePoses)")
        }
    }
}

struct RotationPromptView: View {
    var body: some View {
        VStack {
            Image(systemName: "rotate.right")
                .font(.system(size: 50))
                .padding()
            Text("Please rotate your device so that the camera is on the right.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
    }
}

struct CameraView: UIViewRepresentable {
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
             AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
    
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

struct PerfectFormPose {
    let image: UIImage
    let pose: VNHumanBodyPoseObservation
}

#Preview {
    ContentView()
}
