//
//  SlidingMenu.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/14/24.
//

import SwiftUI

struct SlidingMenu: View {
    // sliding menu open/close
    @Binding var isExpanded: Bool
    // display menu on bottom or side depending on orientation
    let orientation: UIDeviceOrientation
    
    // static pose attributes to be modified by menu
    @Binding var isStaticPoseFollowing: Bool
    @Binding var isStaticPoseLocked: Bool
    @Binding var isStaticPoseMirrored: Bool
    @Binding var poseOverlayScale: CGFloat
    @Binding var isStaticPoseResetClicked: Bool
    @Binding var isReferenceImgShowing: Bool
        
    // attributes for flashing description of clicked button
    @State private var flashMessage: String?
    @State private var isShowingFlash = false
    @State private var messageTimer: Timer?
    
    var body: some View {
        ZStack {
            Group {
                if orientation.isPortrait {
                    bottomSlidingMenu
                } else if orientation.isLandscape {
                    sideSlidingMenu
                }
            }
            
            if isShowingFlash, let message = flashMessage {
                Text(message)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .transition(.opacity)
            }
        }
    }
    
    private var bottomSlidingMenu: some View {
        GeometryReader { geometry in
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    menuContent(geometry: geometry, isPortrait: true)
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.bottom)
        }
    }
    
    private var sideSlidingMenu: some View {
        GeometryReader { geometry in
            HStack {
                Spacer()
                VStack {
                    Spacer()
                    menuContent(geometry: geometry, isPortrait: false)
                    Spacer()
                }
            }
            .edgesIgnoringSafeArea(.trailing)
        }
    }
    
    private func showFlashMessage(_ message: String) {
        // Cancel existing timers to prevent spam
        messageTimer?.invalidate()
        
        // Update the message and show it
        flashMessage = message
        withAnimation {
            isShowingFlash = true
        }
        
        // Set a new timer
        messageTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
            withAnimation {
                self.isShowingFlash = false
            }
        }
    }
    
    private func menuContent(geometry: GeometryProxy, isPortrait: Bool) -> some View {
        ZStack {
            if isExpanded {
                expandedMenu(isPortrait: isPortrait, geometry: geometry)
            } else {
                collapsedMenu(isPortrait: isPortrait)
            }
        }
        .frame(
            width: isPortrait ? geometry.size.width * 0.9 : (isExpanded ? 100 : 80),
            height: isPortrait ? (isExpanded ? 100 : 80) : geometry.size.height * 0.9
        )
        .background(isExpanded ? Color.black.opacity(0.5) : nil)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .offset(isPortrait ? CGSize(width: 0, height: isExpanded ? -40 : 0) : CGSize(width: isExpanded ? -40 : 0, height: 0))
    }
    
    private func expandedMenu(isPortrait: Bool, geometry: GeometryProxy) -> some View {
        Group {
            if isPortrait {
                VStack(spacing: 1) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 30) {
                            menuButtons
                        }
                        .padding(.horizontal, 20)
                    }
                    .frame(height: 60)
                    .padding(.bottom, 8)
                    
                    closeButton(systemName: "chevron.down")
                }
            } else {
                HStack(spacing: 1) {
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 30) {
                            menuButtons
                        }
                        .padding(.vertical, 20)
                    }
                    .frame(width: 60)
                    
                    closeButton(systemName: "chevron.right")
                }
            }
        }
    }
    
    private var menuButtons: some View {
        Group {
            // Button for resetting pose scaling + translations
            menuButton(icon: "arrow.clockwise", action: {
                isStaticPoseResetClicked = true
                poseOverlayScale = 1.0
                showFlashMessage("Reset pose")
                
            })
            
            // Button to toggle which way pose is facing
            menuButton(icon: "arrow.left.arrow.right", action: {
                isStaticPoseMirrored.toggle()
                showFlashMessage("Mirrored pose")
            })
            
            // Button to toggle pose drag/scale gestures
            menuButton(icon: isStaticPoseLocked ? "lock.fill" : "lock.open.fill", action: {
                isStaticPoseLocked.toggle()
                if (isStaticPoseLocked) {
                    showFlashMessage("Pose dragging locked")
                } else {
                    showFlashMessage("Pose dragging unlocked")
                }
                
                // cannot allow pose following and custom user resizing simultaneously
                if (!isStaticPoseLocked) {
                    isStaticPoseFollowing = false
                }
            })
            
            // Button to toggle pose following
            menuButton(icon: isStaticPoseFollowing ? "person.fill" : "person", action: {
                isStaticPoseFollowing.toggle()
                
                if (isStaticPoseFollowing) {
                    showFlashMessage("Auto pose follow on")
                } else {
                    showFlashMessage("Auto pose follow off")
                }
                
                // cannot allow pose following and custom user resizing simultaneously
                if (isStaticPoseFollowing) {
                    isStaticPoseLocked = true
                }
            })
            
            // Button for toggling the static pose's reference image
            menuButton(icon: isReferenceImgShowing ? "rectangle.stack.fill.badge.person.crop" : "rectangle.stack.badge.person.crop", action: {
                isReferenceImgShowing.toggle()
                
                if (isReferenceImgShowing) {
                    showFlashMessage("Showing reference image")
                } else {
                    showFlashMessage("Reference image hidden")
                }
            })
            
        }
    }
    
    private func collapsedMenu(isPortrait: Bool) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: isPortrait ? "chevron.up.circle.fill" : "chevron.left.circle.fill")
                .foregroundColor(.white)
                .font(.system(size: 30))
        }
        .padding(isPortrait ? .bottom : .trailing, 50)
    }
    
    private func closeButton(systemName: String) -> some View {
        Button(action: {
            withAnimation(.spring()) {
                isExpanded.toggle()
            }
        }) {
            Image(systemName: systemName)
                .foregroundColor(.white)
                .font(.system(size: 30))
        }
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

struct ExitButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressed = false
                action()
            }
        }) {
            Image(systemName: "xmark")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
    }
}
