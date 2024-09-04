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

struct RowIcon: View {
    let imageName: String
    let imageSize: CGFloat
    let circleSize: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: circleSize, height: circleSize)
            
            Image(imageName)
                .resizable()
                .scaledToFit()
                .foregroundColor(color)
                .frame(width: imageSize, height: imageSize)
        }
    }
}

struct RowButton: View {
    let sysName: String
    let iconSize: CGFloat
    let color: Color
    
    var body: some View {
        ZStack {
            Image(systemName: sysName)
                .font(.system(size: iconSize))
                .foregroundColor(color)
        }
    }
}

struct ExerciseRow: View {
    let exercise: Exercise
    @ObservedObject var store: ExerciseStore
    @State private var showingPlayOverlay = false
    @State private var showingExerciseOverview = false
    
    var body: some View {
        HStack(spacing: 12) {
            RowButton(sysName: "play.circle.fill", iconSize: 44, color: .blue)
                .onTapGesture {
                    showingPlayOverlay = true
                    logger.log("Play button clicked for: \(exercise.name)")
                }
            
            Text(exercise.name)
                .font(.headline)
            
            Spacer()
            
            RowButton(sysName: exercise.isFavorite ? "star.fill" : "star", iconSize: 20, color: .yellow)
                .onTapGesture {
                    logger.debug("Favorite button clicked for: \(exercise.name)")
                    store.toggleFavorite(for: exercise)
                }
            
            RowIcon(imageName: exercise.imageName, imageSize: 34, circleSize: 40, color: Color.white)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            logger.debug("Exercise card clicked for: \(exercise.name)")
            showingExerciseOverview = true
            
        }
        .sheet(isPresented: $showingPlayOverlay) {
            // TODO: add camera layout
            Text("Exercise Play Overlay")
        }
        .sheet (isPresented: $showingExerciseOverview) {
            // TODO: add overview page & connect card tap to open page
            Text("Exercise overview page")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
