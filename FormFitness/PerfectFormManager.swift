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
    
    func loadPerfectForms() {
        // Load your perfect form images here
        let poses = ["downward-dog", "test"]
        
        logger.debug("Loading poses")
        for pose in poses {
            if let image = UIImage(named: pose) {
                if let pixelBuffer = image.pixelBuffer(),
                   let detectedPose = poseDetector.detectPose(in: pixelBuffer) {
                    perfectForms[pose] = PerfectFormPose(image: image, pose: detectedPose)
                    logger.debug("Loaded \(pose)")
                } else {
                    logger.error("Failed to load pose \(pose) into CVPixelBuffer")
                }
            } else {
                logger.error("Failed to load pose \(pose) image")
            }
        }
    }
}
