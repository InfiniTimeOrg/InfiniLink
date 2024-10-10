//
//  ActiveExerciseView.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import SwiftUI

struct ActiveExerciseView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp)]) var heartPoints: FetchedResults<HeartDataPoint>
    
    @Binding var exercise: Exercise?
    
    @State var timer: Timer?
    
    @State var time = 0
    
    var body: some View {
        if let exercise {
            VStack {
                HStack(spacing: 6) {
                    Image(systemName: exercise.icon)
                    Text(exercise.name)
                }
                .padding(12)
                .padding(.horizontal, 6)
                .font(.body.weight(.medium))
                .background(Material.regular)
                .clipShape(Capsule())
                Spacer()
                // TODO: create timer based text
                Text("00" + ":" + "04" + ":" + "43")
                    .font(.system(size: 60).weight(.bold))
                if let last = heartPoints.compactMap({ $0.value }).last {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text(String(format: "%.0f", last))
                    }
                }
                Spacer()
                HStack {
                    // TODO: add pause
                    Spacer()
                    Button {
                        self.exercise = nil
                    } label: {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 25))
                            .padding(25)
                            .background(Color.red)
                            .foregroundStyle(Color.white)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
            }
            .padding()
            .onAppear {
                timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                    time += 1
                }
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    ActiveExerciseView(exercise: .constant(Exercise(id: "volleyball", name: "Volleyball", icon: "figure.volleyball")))
}
