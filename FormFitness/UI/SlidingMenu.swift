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
    @Binding var poseOverlayOffset: CGSize
    @Binding var poseOverlayScale: CGFloat
    
    // use this to exit the LivePoseView (back to main menu)
    @Environment(\.presentationMode) var presentationMode
    
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
            width: isPortrait ? geometry.size.width * 0.8 : (isExpanded ? 100 : 80),
            height: isPortrait ? (isExpanded ? 150 : 80) : geometry.size.height * 0.8
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
            menuButton(icon: "arrow.clockwise", action: {
                // animate button
                withAnimation(.timingCurve(0.37, 0, 0.63, 1, duration: 0.5)) { isResetButtonSpinning = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    isResetButtonSpinning = false
                 }
                
                // reset static pose scale & location
                poseOverlayOffset = .zero
                poseOverlayScale = 1.0
            })
            .rotationEffect(isResetButtonSpinning ? .degrees(270) : .degrees(0))

            menuButton(icon: "arrow.left.arrow.right", action: {
                isStaticPoseMirrored.toggle()
            })
            
            menuButton(icon: isStaticPoseLocked ? "lock.fill" : "lock.open.fill", action: {
                    isStaticPoseLocked.toggle()
                
                // cannot allow pose following and custom user resizing simultaneously
                if (!isStaticPoseLocked) {
                    isStaticPoseFollowing = false
                }
            })
            
            menuButton(icon: isStaticPoseFollowing ? "person.fill" : "person", action: {
                isStaticPoseFollowing.toggle()
                
                // cannot allow pose following and custom user resizing simultaneously
                if (isStaticPoseFollowing) {
                    isStaticPoseLocked = true
                }
            })
            
//            menuButton(icon: "door.left.hand.open", action: {
//                presentationMode.wrappedValue.dismiss()
//            })
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
