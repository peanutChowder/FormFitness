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
    
    @State private var isResetButtonSpinning = false
    
    var body: some View {
        Group {
            if orientation.isPortrait {
                bottomSlidingMenu
            } else if orientation.isLandscape {
                sideSlidingMenu
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
    
    private func menuContent(geometry: GeometryProxy, isPortrait: Bool) -> some View {
        ZStack {
            if isExpanded {
                expandedMenu(isPortrait: isPortrait)
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
    
    private func expandedMenu(isPortrait: Bool) -> some View {
        Group {
            if isPortrait {
                VStack(spacing: 1) {
                    HStack(spacing: 30) {
                        menuButtons
                    }
                    .padding(.bottom, 8)
                    
                    closeButton(systemName: "chevron.down")
                }
            } else {
                HStack(spacing: 1) {
                    VStack(spacing: 30) {
                        menuButtons
                    }
                    closeButton(systemName: "chevron.right")
                }
            }
        }
    }
    
    private var menuButtons: some View {
        Group {
            // Button for resetting pose scaling + translations
            menuButton(icon: "arrow.clockwise", action: {
                // Reset static pose scale & location by triggering LivePoseView onChange handler that calls
                // cameraManager.resetStaticPosePosition()
                isStaticPoseResetClicked = true
                poseOverlayScale = 1.0
            })
            
            // Button to toggle which way pose is facing
            menuButton(icon: "arrow.left.arrow.right", action: {
                isStaticPoseMirrored.toggle()
            })
            
            // Button to toggle pose drag/scale gestures
            menuButton(icon: isStaticPoseLocked ? "lock.fill" : "lock.open.fill", action: {
                    isStaticPoseLocked.toggle()
                
                // cannot allow pose following and custom user resizing simultaneously
                if (!isStaticPoseLocked) {
                    isStaticPoseFollowing = false
                }
            })
            
            // Button to toggle pose following
            menuButton(icon: isStaticPoseFollowing ? "person.fill" : "person", action: {
                isStaticPoseFollowing.toggle()
                
                // cannot allow pose following and custom user resizing simultaneously
                if (isStaticPoseFollowing) {
                    isStaticPoseLocked = true
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
