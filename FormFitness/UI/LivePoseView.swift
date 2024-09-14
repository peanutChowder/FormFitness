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
    
    @State private var isStaticPoseLocked = true // TODO: incorporate this
    @State private var poseOverlayOffset: CGSize = .zero
    @State private var poseOverlayScale: CGFloat = 1.0
    
    @State private var isMenuExpanded = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                cameraView()
                SlidingMenu(isExpanded: $isMenuExpanded, presentationMode: _presentationMode, orientation: orientation)
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
            orientation = UIDevice.current.orientation
            PerfectFormManager.shared.loadStaticForm(exerciseImg: exerciseImg)
            cameraManager.changePerfectFormPose(to: exerciseImg)
        }
    }
    
    private func cameraView() -> some View {
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
                            .offset(poseOverlayOffset)
                            .scaleEffect(poseOverlayScale)
                            .gesture(
                                DragGesture()
                                    .onChanged { value in
                                        poseOverlayOffset = value.translation
                                    }
                            )
                            .gesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        poseOverlayScale = value
                                    }
                            )
                    }
                }
            }
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
        view.videoPreviewLayer.connection?.videoRotationAngle = phoneOrientationToVideoAngle()
        return view
    }
    
    func phoneOrientationToVideoAngle() -> CGFloat {
        let phoneOrientation = UIDevice.current.orientation
        
        switch phoneOrientation {
        case .portrait:
            return 90
        case .landscapeLeft:
            logger.critical("left")
            return 180
        case .landscapeRight:
            logger.critical("right")
            return 0
        @unknown default:
            return 0
        }
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
