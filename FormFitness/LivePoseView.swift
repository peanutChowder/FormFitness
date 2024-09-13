//
//  LivePoseView.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/2/24.
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


struct LivePoseView: View {
    var exerciseImg: String
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var cameraManager = CameraManager()
    @State private var orientation = UIDeviceOrientation.unknown
    @State private var showRotationPromptView = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Pose overlay & rotation screen
                if showRotationPromptView {
                    RotationPromptView()
                } else {
                    ZStack {
                        if let currentFrame = cameraManager.liveTrackingFrame {
                            Image(uiImage: currentFrame)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .edgesIgnoringSafeArea(.all)
                        } else {
                            CameraView(session: cameraManager.session)
                                .edgesIgnoringSafeArea(.all)
                        }
                        if let staticPose = cameraManager.staticPose {
                            Image(uiImage: staticPose)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .edgesIgnoringSafeArea(.all)
                        }
                    }
                }
                
                // Back button
                VStack {
                    Spacer()
                    HStack {
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.leading, 20)
                        .padding(.bottom, geometry.safeAreaInsets.bottom + 20)
                        Spacer()
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .modifier(DeviceRotationViewModifier { newOrientation in
            orientation = newOrientation
            showRotationPromptView = switch newOrientation {
            case .portrait, .landscapeLeft, .landscapeRight:
                false
            default:
                true
            }
            logger.debug("LivePoseView: Orientation changed: \(newOrientation.rawValue), showRotationPromptView: \(showRotationPromptView)")
        })
        .onAppear {
            PerfectFormManager.shared.loadStaticForm(exerciseImg: exerciseImg)
            cameraManager.changePerfectFormPose(to: exerciseImg)
        }
    }
}

struct RotationPromptView: View {
    var body: some View {
        VStack {
            Image(systemName: "rotate.3d")
                .font(.system(size: 50))
                .padding()
            Text("Prop your phone up in portrait or landscape")
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
