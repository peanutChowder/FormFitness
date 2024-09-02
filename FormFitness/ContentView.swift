//
//  ContentView.swift
//  FormFitness
//
//  Created by Jacob Feng on 8/31/24.
//

import SwiftUI
import AVFoundation
import Vision

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var isLandscape: Bool {
        return verticalSizeClass == .compact || horizontalSizeClass == .regular
    }
    
    var body: some View {
        ZStack {
            if let error = cameraManager.setupError {
                Text("Camera Error: \(error)")
                    .foregroundColor(.red)
                    .padding()
            } else {
                if isLandscape {
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
    }
}

struct RotationPromptView: View {
    var body: some View {
        VStack {
            Image(systemName: "rotate.right")
                .font(.system(size: 50))
                .padding()
            Text("Please rotate your device to landscape mode")
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
