//
//  PoseDetector.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/1/24.
//

import UIKit
import Vision

class PoseDetector {
    func detectPose(in pixelBuffer: CVPixelBuffer) -> VNHumanBodyPoseObservation? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            logger.debug("Failed to perform pose detection: \(error)")
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
        drawPoseLines(pose: pose, on: context, size: imageSize)
        
        // Draw perfect form pose lines
        if let perfectFormPose = perfectFormPose {
            context.setStrokeColor(UIColor.blue.cgColor)
            context.setLineWidth(2.0)
            drawPoseLines(pose: perfectFormPose, on: context, size: imageSize)
        }
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
    }
    
    private func drawPoseLines(pose: VNHumanBodyPoseObservation, on context: CGContext, size: CGSize) {
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
            drawLine(from: start, to: end, in: pose, on: context, size: size)
        }
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
