//
//  LivePoseView.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/2/24.
//

import SwiftUI
import AVFoundation
import Vision

struct LivePoseView: View {
    var exercise: Exercise
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
    @State private var isStaticPoseResetClicked = false
    
    @GestureState private var fingerLocation: CGPoint? = nil
    @GestureState private var startLocation: CGPoint? = nil
    @State private var lastDragPosition: CGPoint? = nil
    
    var body: some View {
        GeometryReader { geometry in
            if showRotationPromptView {
                RotationPromptView(supportedOrientations: getSupportedOrientationsString())
            } else {
                ZStack {
                    cameraView()
                    SlidingMenu(
                        isExpanded: $isMenuExpanded,
                        orientation: orientation,
                        isStaticPoseFollowing: $isStaticPoseFollowing,
                        isStaticPoseLocked: $isStaticPoseLocked,
                        isStaticPoseMirrored: $isStaticPoseMirrored,
                        poseOverlayScale: $staticPoseScale,
                        isStaticPoseResetClicked: $isStaticPoseResetClicked
                    )
                    .onChange(of: isStaticPoseFollowing) {
                        logger.info("LivePoseView: isStaticPoseFollowing set to '\(isStaticPoseFollowing)'")
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
                    .onChange(of: isStaticPoseResetClicked, {
                        isStaticPoseResetClicked = false
                        self.cameraManager.resetStaticPosePosition()
                        staticPosePosition = cameraManager.staticPoseCenter
                    })
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    cameraManager.setCameraViewSize(cameraViewSize: geometry.size)
                    cameraManager.resetStaticPosePosition()
                    staticPosePosition = cameraManager.staticPoseCenter
                }
            }
            
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
        }
        .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
            let newOrientation = UIDevice.current.orientation
            if newOrientation != orientation {
                orientation = newOrientation
                logger.error("orientation changed")
                
                if exercise.supportedOrientations.contains(orientation) {
                    showRotationPromptView = false
                } else {
                    showRotationPromptView = true
                }
            }
        }
        .onAppear {
            orientation = UIDevice.current.orientation
            PerfectFormManager.shared.loadStaticForm(exerciseImg: exercise.imageName)
            cameraManager.changePerfectFormPose(to: exercise.imageName)
            
            if exercise.supportedOrientations.contains(orientation) {
                showRotationPromptView = false
            } else {
                showRotationPromptView = true
            }
        }
    }
    
    private func getSupportedOrientationsString() -> [String] {
        var supportedOrientationsStr: [String] = []
        let landscapeOrientations: Set<UIDeviceOrientation> = [.landscapeRight, .landscapeLeft]
        if landscapeOrientations.isSubset(of: exercise.supportedOrientations) {
            supportedOrientationsStr.append("landscape")
        }
        if exercise.supportedOrientations.contains(.portrait) {
            supportedOrientationsStr.append("portrait")
        }
        
        return supportedOrientationsStr
    }
    
    private func cameraView() -> some View {
        ZStack {
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
                            .position(isStaticPoseFollowing ? cameraManager.staticPoseCenter : staticPosePosition)
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

struct RotationPromptView: View {
    let supportedOrientations: [String]
    var body: some View {
        VStack {
            Image(systemName: "rotate.3d")
                .font(.system(size: 50))
                .padding()
            Text("Prop your phone up in \(supportedOrientations.joined(separator: " or ")).")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
