//
//  PoseDetector.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/1/24.
//

import UIKit
import Vision

class PoseDetector {
    private let livePoseWidth = 7.0
    private let staticPoseWidth = 10.0
    private struct PoseColors {
        // live pose colors
        static let livePoseLimb: CGColor = CGColor(red: 66/255, green: 245/255, blue: 123/255, alpha: 1)
        static let livePoseHead: CGColor = CGColor(red: 250/255, green: 182/255, blue: 245/255, alpha: 1)
        static let livePoseHands: CGColor = CGColor(red: 220/255, green: 182/255, blue: 245/255, alpha: 1)
        static let livePoseFeet: CGColor = CGColor(red: 180/255, green: 182/255, blue: 245/255, alpha: 1)
        
        // static pose colors
        static let staticPoseLimb: CGColor = CGColor(red: 66/255, green: 182/255, blue: 245/255, alpha: 1)
        static let staticPoseHead: CGColor = CGColor(red: 250/255, green: 182/255, blue: 245/255, alpha: 1)
        static let staticPoseHands: CGColor = CGColor(red: 220/255, green: 182/255, blue: 245/255, alpha: 1)
        static let staticPoseFeet: CGColor = CGColor(red: 180/255, green: 182/255, blue: 245/255, alpha: 1)
        
    }
    
    
    func detectPose(in pixelBuffer: CVPixelBuffer, orientation: CGImagePropertyOrientation = .up) -> VNHumanBodyPoseObservation? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: orientation, options: [:])
        
        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            logger.debug("PoseDetector: Pose detection failed: \(error)")
            return nil
        }
    }
    
    func drawStaticPose(context: CGContext, perfectFormPose: VNHumanBodyPoseObservation? = nil, imageSize: CGSize) {
        // Draw perfect form pose lines
        if let perfectFormPose = perfectFormPose {
            context.setStrokeColor(PoseColors.staticPoseLimb)
            context.setLineWidth(staticPoseWidth)
            drawPoseOverlay(
                pose: perfectFormPose,
                on: context,
                imageSize: imageSize,
                headColor: PoseColors.staticPoseHead,
                handColor: PoseColors.staticPoseHands,
                feetColor: PoseColors.staticPoseFeet
            )
        }
    }
    
    func drawLivePose(pose: VNHumanBodyPoseObservation, context: CGContext, imageSize: CGSize) {
        context.setStrokeColor(PoseColors.livePoseLimb)
        context.setLineWidth(livePoseWidth)
        drawPoseOverlay(
            pose: pose,
            on: context,
            imageSize: imageSize,
            headColor: PoseColors.livePoseHead,
            handColor: PoseColors.livePoseHands,
            feetColor: PoseColors.livePoseFeet
        )
    }
    
    #warning("experimental")
    func drawLivePoseColorRating(
        pose: VNHumanBodyPoseObservation,
        staticPose: VNHumanBodyPoseObservation,
        context: CGContext,
        imageSize: CGSize,
        staticPoseCenter: CGPoint
    ) {
        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            (.nose, .neck),
            (.neck, .leftShoulder),
            (.neck, .rightShoulder),
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            (.neck, .root),
            (.root, .leftHip),
            (.root, .rightHip),
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle)
        ]
        
        for (start, end) in connections {
            drawLineColorRating(from: start, to: end, in: pose, staticPose: staticPose, on: context, size: imageSize, staticPoseCenter: staticPoseCenter)
        }
        
        // Draw joint indicators
        let joints: [VNHumanBodyPoseObservation.JointName] = [.nose, .neck, .leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist, .root, .leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
        
        for joint in joints {
            drawJointIndicatorColorRating(for: joint, in: pose, staticPose: staticPose, on: context, size: imageSize, jointIndicatorRadius: 5, staticPoseCenter: staticPoseCenter)
        }
    }
    
    func getJointCoordinateFromContext(joint: VNHumanBodyPoseObservation.JointName,
                                       pose: VNHumanBodyPoseObservation,
                                       context: CGContext,
                                       size: CGSize
    ) -> CGPoint {
        guard let point = try? pose.recognizedPoint(joint),
              point.confidence > 0.1 else {
            return .zero
        }
        let x = point.location.x * size.width
        let y = (1 - point.location.y) * size.height
        
        return CGPoint(x: x, y: y)
    }
    
    private func drawPoseOverlay(pose: VNHumanBodyPoseObservation, on context: CGContext, imageSize: CGSize, headColor: CGColor, handColor: CGColor, feetColor: CGColor) {
        let connections: [(VNHumanBodyPoseObservation.JointName, VNHumanBodyPoseObservation.JointName)] = [
            (.nose, .neck),
            (.neck, .leftShoulder),
            (.neck, .rightShoulder),
            (.leftShoulder, .leftElbow),
            (.leftElbow, .leftWrist),
            (.rightShoulder, .rightElbow),
            (.rightElbow, .rightWrist),
            (.neck, .root),
            (.root, .leftHip),
            (.root, .rightHip),
            (.leftHip, .leftKnee),
            (.leftKnee, .leftAnkle),
            (.rightHip, .rightKnee),
            (.rightKnee, .rightAnkle)
        ]
        
        // Draw pose lines
        for (start, end) in connections {
            drawLine(from: start, to: end, in: pose, on: context, size: imageSize)
        }
        
        drawJointIndicator(for: .nose, in: pose, on: context, size: imageSize, jointIndicatorRadius: 40, color: headColor)
        drawJointIndicator(for: .rightWrist, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: handColor)
        drawJointIndicator(for: .leftWrist, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: handColor)
        drawJointIndicator(for: .leftAnkle, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: feetColor)
        drawJointIndicator(for: .rightAnkle, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: feetColor)
    }
    
    #warning("Experimental")
    private func drawJointIndicatorColorRating(for joint: VNHumanBodyPoseObservation.JointName,
                                               in pose: VNHumanBodyPoseObservation,
                                               staticPose: VNHumanBodyPoseObservation,
                                               on context: CGContext,
                                               size: CGSize,
                                               jointIndicatorRadius: CGFloat,
                                               staticPoseCenter: CGPoint
    ) {
        guard let point = try? pose.recognizedPoint(joint),
              point.confidence > 0.1 else {
            return
        }
        
        let x = point.location.x * size.width
        let y = (1 - point.location.y) * size.height
        
        let matchPercentage = jointMatchPercentage(joint: joint, in: pose, with: staticPose, staticPoseCenter: staticPoseCenter)
        let color = colorForMatchPercentage(matchPercentage)
        
        context.setFillColor(color.cgColor)
        context.addArc(center: CGPoint(x: x, y: y), radius: jointIndicatorRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        context.fillPath()
    }
    
    private func drawJointIndicator(for joint: VNHumanBodyPoseObservation.JointName,
                                    in pose: VNHumanBodyPoseObservation,
                                    on context: CGContext,
                                    size: CGSize,
                                    jointIndicatorRadius: CGFloat,
                                    color: CGColor) {
        guard let point = try? pose.recognizedPoint(joint),
              point.confidence > 0.1 else {
            return
        }
        
        let x = point.location.x * size.width
        let y = (1 - point.location.y) * size.height
        
        context.setFillColor(color)
        context.addArc(center: CGPoint(x: x, y: y), radius: jointIndicatorRadius, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        context.fillPath()
    }
    
    func testDrawDotAtOrigin(context: CGContext) {
        context.setFillColor(UIColor.systemPink.cgColor)
        context.addArc(center: CGPoint(x: 0, y: 0), radius: 60, startAngle: 0, endAngle: CGFloat.pi * 2, clockwise: true)
        context.fillPath()
    }
    
#warning("experimental")
    private func jointMatchPercentage(
        joint: VNHumanBodyPoseObservation.JointName,
        in pose: VNHumanBodyPoseObservation,
        with staticPose: VNHumanBodyPoseObservation,
        staticPoseCenter: CGPoint
    ) -> CGFloat {
        guard let liveJointPoint = try? pose.recognizedPoint(joint),
              let staticJointPoint = try? staticPose.recognizedPoint(joint),
              liveJointPoint.confidence > 0.1 && staticJointPoint.confidence > 0.1 else {
            return 0
        }
        
        let maxDistance: CGFloat = 0.5 // Maximum distance for 0% match
        let distance = hypot(
            liveJointPoint.location.x - staticJointPoint.location.x + (UIScreen.main.bounds.size.width / 2 - staticPoseCenter.x) / UIScreen.main.bounds.size.width,
            liveJointPoint.location.y - staticJointPoint.location.y - (UIScreen.main.bounds.size.height / 2 - staticPoseCenter.y) / UIScreen.main.bounds.size.height
        )
        
        let matchPercentage = 1 - (distance / maxDistance)
        return max(0, min(1, matchPercentage)) // Clamp between 0 and 1
    }
    
#warning("experimental")
    private func colorForMatchPercentage(_ percentage: CGFloat) -> UIColor {
        let red: CGFloat
        let green: CGFloat
        
        if percentage <= 0.5 {
            // Gradient from red to yellow
            red = 1.0
            green = percentage * 2
        } else {
            // Gradient from yellow to green
            red = 2.0 - (percentage * 2)
            green = 1.0
        }
        
        return UIColor(red: red, green: green, blue: 0, alpha: 1)
    }
    
#warning("experimental")
    private func drawLineColorRating(from startJoint: VNHumanBodyPoseObservation.JointName,
                                     to endJoint: VNHumanBodyPoseObservation.JointName,
                                     in pose: VNHumanBodyPoseObservation,
                                     staticPose: VNHumanBodyPoseObservation,
                                     on context: CGContext,
                                     size: CGSize,
                                     staticPoseCenter: CGPoint
    ) {
        guard let startPoint = try? pose.recognizedPoint(startJoint),
              let endPoint = try? pose.recognizedPoint(endJoint),
              startPoint.confidence > 0.1 && endPoint.confidence > 0.1 else {
            return
        }
        
        let startX = startPoint.location.x * size.width
        let startY = (1 - startPoint.location.y) * size.height
        let endX = endPoint.location.x * size.width
        let endY = (1 - endPoint.location.y) * size.height
        
        let startMatchPercentage = jointMatchPercentage(joint: startJoint, in: pose, with: staticPose, staticPoseCenter: staticPoseCenter)
        let endMatchPercentage = jointMatchPercentage(joint: endJoint, in: pose, with: staticPose, staticPoseCenter: staticPoseCenter)
        
        let startColor = colorForMatchPercentage(startMatchPercentage)
        let endColor = colorForMatchPercentage(endMatchPercentage)
        
        drawGradientLine(from: CGPoint(x: startX, y: startY),
                         to: CGPoint(x: endX, y: endY),
                         startColor: startColor,
                         endColor: endColor,
                         in: context)
    }
    
    private func drawGradientLine(from startPoint: CGPoint,
                                  to endPoint: CGPoint,
                                  startColor: UIColor,
                                  endColor: UIColor,
                                  in context: CGContext) {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let startColorComponents = startColor.cgColor.components ?? [0, 0, 0, 1]
        let endColorComponents = endColor.cgColor.components ?? [0, 0, 0, 1]
        
        let colorComponents: [CGFloat] = startColorComponents + endColorComponents
        let locations: [CGFloat] = [0.0, 1.0]
        
        guard let gradient = CGGradient(colorSpace: colorSpace,
                                        colorComponents: colorComponents,
                                        locations: locations,
                                        count: 2) else {
            return
        }
        
        context.saveGState()
        context.setLineWidth(livePoseWidth)
        context.setLineCap(.round)
        
        context.move(to: startPoint)
        context.addLine(to: endPoint)
        context.replacePathWithStrokedPath()
        context.clip()
        
        context.drawLinearGradient(gradient,
                                   start: startPoint,
                                   end: endPoint,
                                   options: [])
        
        context.restoreGState()
    }
    
    private func drawLine(from startPoint: VNHumanBodyPoseObservation.JointName,
                          to endPoint: VNHumanBodyPoseObservation.JointName,
                          in pose: VNHumanBodyPoseObservation,
                          on context: CGContext,
                          size: CGSize) {
        guard let startPoint = try? pose.recognizedPoint(startPoint),
              let endPoint = try? pose.recognizedPoint(endPoint),
              startPoint.confidence > 0.1 && endPoint.confidence > 0.1 else {
            return
        }
        
        let startX = startPoint.location.x * size.width
        let startY = (1 - startPoint.location.y) * size.height
        let endX = endPoint.location.x * size.width
        let endY = (1 - endPoint.location.y) * size.height
        
        context.move(to: CGPoint(x: startX, y: startY))
        context.addLine(to: CGPoint(x: endX, y: endY))
        context.strokePath()
    }
    
    func calculatePoseOffset(livePose: VNHumanBodyPoseObservation, staticPose: VNHumanBodyPoseObservation, initialOffset: CGPoint) -> CGPoint {
        let targetJoint: VNHumanBodyPoseObservation.JointName = .rightAnkle
        
        guard let livePoint = try? livePose.recognizedPoint(targetJoint),
              let staticPoint = try? staticPose.recognizedPoint(targetJoint),
              livePoint.confidence > 0.1 && staticPoint.confidence > 0.1 else {
            return .zero
        }
        
        let currentOffset = CGPoint(x: livePoint.location.x - staticPoint.location.x,
                                    y: livePoint.location.y - staticPoint.location.y)
        
        let relativeOffset = CGPoint(x: currentOffset.x - initialOffset.x,
                                     y: currentOffset.y - initialOffset.y)
        return relativeOffset
    }
    
    func calcNormalizedStaticJointOffset(staticPose: VNHumanBodyPoseObservation, joint: VNHumanBodyPoseObservation.JointName) -> CGPoint? {
        guard let pointRelativeToTopLeft = try? staticPose.recognizedPoint(joint) else {
            return nil
        }
        
        if pointRelativeToTopLeft.confidence > 0.1 {
            return CGPoint(x: CGFloat(pointRelativeToTopLeft.location.x - 0.5),
                           y: CGFloat(pointRelativeToTopLeft.location.y - 0.5))
        } else {
            return nil
        }
    }
}

struct PerfectFormPose {
    let image: UIImage
    let pose: VNHumanBodyPoseObservation
}
