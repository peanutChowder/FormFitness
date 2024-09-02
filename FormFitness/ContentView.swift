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
    
    var body: some View {
        ZStack {
            if let error = cameraManager.setupError {
                Text("Camera Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                if isLandscapeRight {
                    if let currentFrame = cameraManager.currentFrame {
                        Image(uiImage: currentFrame)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        CameraView(session: cameraManager.session)
                            .edgesIgnoringSafeArea(.all)
                    }
                } else {
                    RotationPromptView()
                }
            }
        }
        .onRotate { newOrientation in
            orientation = newOrientation
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

#Preview {
    ContentView()
}
