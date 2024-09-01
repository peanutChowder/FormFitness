//
//  PoseDetector.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/1/24.
//

import Foundation
import SwiftUI
import Vision
import AVFoundation


struct PoseDetector {
    func detectPose(in image: CVPixelBuffer) -> VNHumanBodyPoseObservation? {
        let request = VNDetectHumanBodyPoseRequest()
        let handler = VNImageRequestHandler(cvPixelBuffer: image, orientation: .up, options: [:])
        
        do {
            try handler.perform([request])
            return request.results?.first
        } catch {
            print("Failed to perform pose detection: \(error)")
            return nil
        }
    }
    
    func drawPoseOverlay(pose: VNHumanBodyPoseObservation, on image: CVPixelBuffer) -> UIImage? {
        let imageSize = CGSize(width: CVPixelBufferGetWidth(image), height: CVPixelBufferGetHeight(image))
        
        UIGraphicsBeginImageContextWithOptions(imageSize, false, 1.0)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Draw the original image
        let ciImage = CIImage(cvPixelBuffer: image)
        let uiImage = UIImage(ciImage: ciImage)
        uiImage.draw(in: CGRect(origin: .zero, size: imageSize))
        
        // Draw pose lines
        context.setStrokeColor(UIColor.green.cgColor)
        context.setLineWidth(3.0)
        
        drawLine(from: .nose, to: .neck, in: pose, on: context, size: imageSize)
        drawLine(from: .neck, to: .leftShoulder, in: pose, on: context, size: imageSize)
        drawLine(from: .neck, to: .rightShoulder, in: pose, on: context, size: imageSize)
        drawLine(from: .leftShoulder, to: .leftElbow, in: pose, on: context, size: imageSize)
        drawLine(from: .leftElbow, to: .leftWrist, in: pose, on: context, size: imageSize)
        drawLine(from: .rightShoulder, to: .rightElbow, in: pose, on: context, size: imageSize)
        drawLine(from: .rightElbow, to: .rightWrist, in: pose, on: context, size: imageSize)
        drawLine(from: .neck, to: .root, in: pose, on: context, size: imageSize)
        drawLine(from: .root, to: .leftHip, in: pose, on: context, size: imageSize)
        drawLine(from: .root, to: .rightHip, in: pose, on: context, size: imageSize)
        drawLine(from: .leftHip, to: .leftKnee, in: pose, on: context, size: imageSize)
        drawLine(from: .leftKnee, to: .leftAnkle, in: pose, on: context, size: imageSize)
        drawLine(from: .rightHip, to: .rightKnee, in: pose, on: context, size: imageSize)
        drawLine(from: .rightKnee, to: .rightAnkle, in: pose, on: context, size: imageSize)
        
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result
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
        
        context.move(to: CGPoint(x: startPoint.location.x * size.width, y: (1 - startPoint.location.y) * size.height))
        context.addLine(to: CGPoint(x: endPoint.location.x * size.width, y: (1 - endPoint.location.y) * size.height))
        context.strokePath()
    }
}
