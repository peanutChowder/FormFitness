//
//  ExerciseStore.swift
//  FormFitness
//
//  Created by Jacob Feng on 9/15/24.
//

import Foundation
import Combine

class ExerciseStore: ObservableObject {
    @Published var exercises: [Exercise] = [
        Exercise(name: "Push-ups", imageName: "pushups"),
        Exercise(name: "Squats", imageName: "squats"),
        Exercise(name: "Downwawrd Dog", imageName: "downward-dog", iconName: "downward-dog-icon"),
        Exercise(name: "Plank", imageName: "plank3"),
        Exercise(name: "Warrior 1", imageName: "warrior-1", iconName: "warrior-1-icon")
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
