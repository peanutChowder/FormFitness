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
    
    // static pose attributes
    @State private var isStaticPoseLocked = true
    @State private var isStaticPoseMirrored = false
    @State private var staticPosePosition: CGPoint = .zero
    @State private var staticPoseScale: CGFloat = 1.0
    @State private var isStaticPoseFollowing = false
    
    @State private var isMenuExpanded = false
    
    @GestureState private var fingerLocation: CGPoint? = nil
    @GestureState private var startLocation: CGPoint? = nil
    @State private var lastDragPosition: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                cameraView()
                VStack {
                    HStack {
                        ExitButton {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(20)
                        Spacer()
                    }
                    Spacer()
                }
                SlidingMenu(
                    isExpanded: $isMenuExpanded,
                    orientation: orientation,
                    isStaticPoseFollowing: $isStaticPoseFollowing,
                    isStaticPoseLocked: $isStaticPoseLocked,
                    isStaticPoseMirrored: $isStaticPoseMirrored,
                    poseOverlayScale: $staticPoseScale
                )
                .onChange(of: isStaticPoseFollowing) {
                    self.cameraManager.setIsStaticPoseFollowing(to: isStaticPoseFollowing)
                    self.cameraManager.resetStaticPosePosition()
                    if isStaticPoseFollowing {
                        staticPosePosition = cameraManager.staticPoseCenter
                    }
                }
                .onChange(of: isStaticPoseLocked) {
                    self.cameraManager.resetStaticPosePosition()
                    if isStaticPoseLocked {
                        staticPosePosition = cameraManager.staticPoseCenter
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .onAppear {
                cameraManager.setCameraViewSize(cameraViewSize: geometry.size)
                cameraManager.resetStaticPosePosition()
                staticPosePosition = cameraManager.staticPoseCenter
            }
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
            if showRotationPromptView {
                RotationPromptView()
            } else {
                GeometryReader { geometry in
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
                                .position(staticPosePosition)
                                .scaleEffect(staticPoseScale)
                                .scaleEffect(x: isStaticPoseMirrored ? -1 : 1, y: 1, anchor: .center)
                                .gesture(
                                    DragGesture()
                                        .updating($fingerLocation) { value, fingerLocation, _ in
                                            fingerLocation = value.location
                                        }
                                        .updating($startLocation) { value, startLocation, _ in
                                            if startLocation == nil {
                                                startLocation = staticPosePosition
                                            }
                                        }
                                        .onChanged { value in
                                            if !isStaticPoseLocked && !isStaticPoseFollowing {
                                                if lastDragPosition == nil {
                                                    lastDragPosition = value.startLocation
                                                }
                                                let translation = CGPoint(
                                                    x: value.location.x - (lastDragPosition?.x ?? 0),
                                                    y: value.location.y - (lastDragPosition?.y ?? 0)
                                                )
                                                staticPosePosition = CGPoint(
                                                    x: staticPosePosition.x + (isStaticPoseMirrored ? -translation.x : translation.x),
                                                    y: staticPosePosition.y + translation.y
                                                )
                                                lastDragPosition = value.location
                                            }
                                        }
                                        .onEnded { _ in
                                            lastDragPosition = nil
                                        }
                                )
                                .gesture(
                                    MagnificationGesture()
                                        .onChanged { value in
                                            if !isStaticPoseLocked {
                                                staticPoseScale = value
                                            }
                                        }
                                )
                                .onAppear() {
                                    staticPosePosition = cameraManager.staticPoseCenter
                                }
                        }
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
            return 180
        case .landscapeRight:
            return 0
        @unknown default:
            return 0
        }
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {}
}
