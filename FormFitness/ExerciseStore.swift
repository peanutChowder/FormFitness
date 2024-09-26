//
//  ExerciseStore.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/15/24.
//

import Foundation
import Combine
import UIKit

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    var iconName: String? = ""
    var supportedOrientations: [UIDeviceOrientation] = [.portrait, .landscapeLeft, .landscapeRight]
    var isFavorite: Bool = false
}

class ExerciseStore: ObservableObject {
    @Published var exercises: [Exercise] = [
        Exercise(name: "Downwawrd Dog", imageName: "downward-dog", iconName: "downward-dog-icon"),
        Exercise(name: "Plank", imageName: "plank3", iconName: "plank-icon", supportedOrientations: [.landscapeLeft, .landscapeRight]),
        Exercise(name: "Warrior 1", imageName: "warrior-1", iconName: "warrior-1-icon", supportedOrientations: [.landscapeLeft, .landscapeRight]),
        Exercise(name: "Warrior 2", imageName: "warrior-2", iconName: "warrior-2-icon", supportedOrientations: [.landscapeLeft, .landscapeRight]),
        Exercise(name: "Child's Pose", imageName: "childs-pose", iconName: "childs-pose-icon", supportedOrientations: [.landscapeLeft, .landscapeRight]),
        Exercise(name: "Tree Pose", imageName: "tree-pose", iconName: "tree-pose-icon", supportedOrientations: [.landscapeLeft, .landscapeRight]),
        Exercise(name: "Bridge Pose", imageName: "bridge-pose", iconName: "bridge-pose-icon", supportedOrientations: [.landscapeLeft, .landscapeRight]),
        Exercise(name: "Cobra Pose", imageName: "cobra", iconName: "cobra-icon"),
        Exercise(name: "Triangle Pose", imageName: "triangle", iconName: "triangle-icon")
    ]
    
    var favoriteExercises: [Exercise] {
        exercises.filter { $0.isFavorite }
    }
    
    func toggleFavorite(for exercise: Exercise) {
        if let index = exercises.firstIndex(where: { $0.id == exercise.id }) {
            exercises[index].isFavorite.toggle()
        }
    }
}
