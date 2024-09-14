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
                bottomSlidingMenu
//                backButton(geometry: geometry) TODO: incorporate this into new menu
                
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
    
    private func backButton(geometry: GeometryProxy) -> some View {
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
    
    private var bottomSlidingMenu: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    ZStack {
                        if isMenuExpanded {
                            expandedMenu
                        } else {
                            collapsedMenu
                        }
                    }
                    .frame(height: isMenuExpanded ? 120 : 80)
                    .frame(width: geometry.size.width * 0.8)
                    .background(isMenuExpanded ? Color.black.opacity(0.5) : nil)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .offset(y: isMenuExpanded ? -40 : 0)
                    .gesture(
                        DragGesture()
                            .onEnded { value in
                                if value.translation.height < -10 {
                                    withAnimation(.spring()) {
                                        isMenuExpanded = true
                                    }
                                } else if value.translation.height > 10 {
                                    withAnimation(.spring()) {
                                        isMenuExpanded = false
                                    }
                                }
                            }
                    )
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private var expandedMenu: some View {
        VStack(spacing: 1) {
            HStack(spacing: 30) {
                // TODO: implement buttons
                menuButton(icon: "1.circle", action: {})
                menuButton(icon: "2.circle", action: {})
                menuButton(icon: "3.circle", action: {})
                menuButton(icon: "4.circle", action: {})
            }
            
            Button(action: {
                withAnimation(.spring()) {
                    isMenuExpanded.toggle()
                }
            }) {
                Image(systemName: "chevron.down")
                    .foregroundColor(.white)
                    .font(.system(size: 30))
            }
        }
    }
    
    private var collapsedMenu: some View {
        Button(action: {
            withAnimation(.spring()) {
                isMenuExpanded.toggle()
            }
        }) {
            Image(systemName: "chevron.up.circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 30))
        }
        .padding(.bottom, 50)
    }
    
    private func menuButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .foregroundColor(.white)
                .font(.system(size: 24))
                .frame(width: 60, height: 60)
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
