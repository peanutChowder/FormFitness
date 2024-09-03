//
//  ContentView.swift
//  FormFitness
//
//  Created by Jacob Feng on 8/31/24.
//

import SwiftUI

struct Exercise: Identifiable {
    let id = UUID()
    let name: String
    let imageName: String
    var isFavorite: Bool = false
}

class ExerciseStore: ObservableObject {
    @Published var exercises: [Exercise] = [
        Exercise(name: "Push-ups", imageName: "pushups"),
        Exercise(name: "Squats", imageName: "squats"),
        Exercise(name: "", imageName: "lunges"),
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

struct ContentView: View {
    @StateObject private var exerciseStore = ExerciseStore()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ExerciseListView(exercises: exerciseStore.exercises, store: exerciseStore)
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("Exercises")
                }
                .tag(0)
            
            FavoritesView(favorites: exerciseStore.favoriteExercises, store: exerciseStore)
                .tabItem {
                    Image(systemName: "star.fill")
                    Text("Favorites")
                }
                .tag(1)
        }
    }
}

struct ExerciseListView: View {
    let exercises: [Exercise]
    @ObservedObject var store: ExerciseStore
    @State private var searchText = ""
    
    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        NavigationView {
            List(filteredExercises) { exercise in
                ExerciseRow(exercise: exercise, store: store)
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText)
        }
    }
}

struct FavoritesView: View {
    let favorites: [Exercise]
    @ObservedObject var store: ExerciseStore
    
    var body: some View {
        NavigationView {
            List(favorites) { exercise in
                ExerciseRow(exercise: exercise, store: store)
            }
            .navigationTitle("Favorites")
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    @ObservedObject var store: ExerciseStore
    @State private var showingPlayOverlay = false
    
    var body: some View {
        HStack(spacing: 12) {
            Button(action: {
                showingPlayOverlay = true
            }) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.blue)
            }
            .frame(width: 44, height: 44)
            
            Button(action: {
                store.toggleFavorite(for: exercise)
            }) {
                Image(systemName: exercise.isFavorite ? "star.fill" : "star")
                    .font(.system(size: 24))
                    .foregroundColor(.yellow)
            }
            .frame(width: 44, height: 44)
            
            Text(exercise.name)
                .font(.headline)
            
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 36, height: 36)
                Image(exercise.imageName)
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(Color.white)
                    .frame(width: 30, height: 30)
            }
        }
        .padding(.vertical, 8)
        .sheet(isPresented: $showingPlayOverlay) {
            // TODO: add camera layout
            Text("Exercise Play Overlay")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
