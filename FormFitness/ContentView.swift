//
//  ContentView.swift
//  FormFitness
//
//  Created by Jacob Feng on 8/31/24.
//

import SwiftUI
import AVFoundation

struct ContentView: View {
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            CameraView(session: cameraManager.session)
                .edgesIgnoringSafeArea(.all)
            
            VStack {
                Text("Hello world")
                Spacer()
                Button("Toggle Camera") {
                    cameraManager.toggleCamera()
                }
                .padding()
                .background(Color.white.opacity(0.7))
                .cornerRadius(10)
                .padding(.bottom, 50)
            }
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
        view.videoPreviewLayer.connection?.videoOrientation = .portrait
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}

#Preview {
    ContentView()
}
