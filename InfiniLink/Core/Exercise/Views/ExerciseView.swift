//
//  ExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/6/24.
//

import SwiftUI
import CoreData

struct ExerciseView: View {
    @ObservedObject var exerciseViewModel = ExerciseViewModel.shared
    @ObservedObject var bleManager = BLEManager.shared
    @ObservedObject var chartManager = ChartManager.shared
    
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        VStack {
            if exerciseViewModel.currentExercise != nil {
                ActiveExerciseView()
            } else {
                List {
                    if !bleManager.hasLoadedCharacteristics {
                        Section {
                            Text(DeviceManager.shared.name + " needs to be connected before you can start an exercise.")
                        }
                    }
                    Section(footer: Text("You can start a new exercise by choosing one from the list below.")) {
                        NavigationLink {
                            AllExercisesView()
                        } label: {
                            Text("My Exercises")
                        }
                    }
                    Section {
                        ForEach(exerciseViewModel.exercises, id: \.id) { exercise in
                            Button {
                                exerciseViewModel.startExercise(exercise)
                            } label: {
                                Label(exercise.name, systemImage: exercise.icon)
                            }
                            .disabled(!bleManager.hasLoadedCharacteristics)
                        }
                    } header: {
                        if bleManager.hasLoadedCharacteristics {
                            Text("All Exercises")
                        }
                    }
                }
                .navigationTitle("Exercise")
            }
        }
    }
}

#Preview {
    NavigationView {
        ExerciseView()
    }
}
