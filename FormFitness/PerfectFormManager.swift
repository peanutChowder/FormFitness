//
//  PerfectFormPose.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/2/24.
//

import UIKit
import Vision

class PerfectFormManager {
    static let shared = PerfectFormManager()
    
    private(set) var perfectForms: [String: PerfectFormPose] = [:]
    private let poseDetector = PoseDetector()
    
    private init() {}
    
    func loadStaticForm(exerciseImg: String) {
        if let image = UIImage(named: exerciseImg) {
            if let pixelBuffer = image.pixelBuffer(),
               let detectedPose = poseDetector.detectPose(in: pixelBuffer) {
                perfectForms[exerciseImg] = PerfectFormPose(image: image, pose: detectedPose)
                logger.debug("PerfectFormManager: loaded \(exerciseImg)")
            } else {
                logger.error("PerfectFormManager: Failed to load pose \(exerciseImg) into CVPixelBuffer")
            }
        } else {
            logger.error("PerfectFormManager: Failed to load pose \(exerciseImg) image")
        }
    }
}
