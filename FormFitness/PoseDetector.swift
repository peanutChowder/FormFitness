//
//  PoseDetector.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/1/24.
//

import UIKit
import Vision

class PoseDetector {
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
    
    func drawPoseOverlay(pose: VNHumanBodyPoseObservation, on image: CVPixelBuffer, perfectFormPose: VNHumanBodyPoseObservation? = nil) -> UIImage? {
        let imageSize = CGSize(width: CVPixelBufferGetWidth(image), height: CVPixelBufferGetHeight(image))
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw the original image
        let ciImage = CIImage(cvPixelBuffer: image)
        let uiImage = UIImage(ciImage: ciImage)
        uiImage.draw(in: CGRect(origin: .zero, size: imageSize))
        
        // Draw live pose lines
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(3.0)
        drawPoseOverlay(pose: pose, on: context, imageSize: imageSize)
        
        // Draw perfect form pose lines
        if let perfectFormPose = perfectFormPose {
            context.setStrokeColor(UIColor.blue.cgColor)
            context.setLineWidth(10.0)
            drawPoseOverlay(pose: perfectFormPose, on: context, imageSize: imageSize)
        }
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    private func drawPoseOverlay(pose: VNHumanBodyPoseObservation, on context: CGContext, imageSize: CGSize) {
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
        
        // Draw pose circle indicators for head, hands, and feet
        let headColor = CGColor(red: 3/255, green: 240/255, blue: 252/255, alpha: 1)
        let handColor = CGColor(red: 3/255, green: 180/255, blue: 252/255, alpha: 1)
        let feetColor = CGColor(red: 3/255, green: 140/255, blue: 252/255, alpha: 1)
        drawJointIndicator(for: .nose, in: pose, on: context, size: imageSize, jointIndicatorRadius: 40, color: headColor)
        drawJointIndicator(for: .rightWrist, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: handColor)
        drawJointIndicator(for: .leftWrist, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: handColor)
        drawJointIndicator(for: .leftAnkle, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: feetColor)
        drawJointIndicator(for: .rightAnkle, in: pose, on: context, size: imageSize, jointIndicatorRadius: 20, color: feetColor)
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
}

struct PerfectFormPose {
    let image: UIImage
    let pose: VNHumanBodyPoseObservation
}
