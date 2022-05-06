//
//  CustomizeFavoritesView.swift
//  InfiniLink
//
//  Created by John Stanley on 5/2/22.
//
    

import SwiftUI

struct CustomizeFavoritesView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    //@State var allFavorites = ["Steps", "Heart", "Battery", "More Steps", "More Heart", "More Battery"]
    @AppStorage("favorites") var favorites: Array = ["Steps", "Heart"]
    

    var body: some View {
        return VStack {
            List() {
                Section() {
                    ForEach(favorites, id: \.self) { user in
                        Text(user)
                    }
                        .onDelete(perform: remove)
                        .onMove(perform: move)
                }
                Section() {
                    ForEach(unusedFavorites(), id: \.self) { user in
                        HStack {
                            if #available(iOS 15.0, *) {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.green)
                                    .symbolRenderingMode(.multicolor)
                                    .onTapGesture {
                                        favorites.append(user)
                                    }
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .imageScale(.large)
                                    .foregroundColor(.green)
                                    .onTapGesture {
                                        favorites.append(user)
                                    }
                            }

                            Text("  " + user)
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        }
                    }

                }

            }
            .environment(\.editMode, true ? .constant(.active) : .constant(.inactive))
            .navigationBarTitle(Text("Customize Favorites").font(.subheadline), displayMode: .inline)
        }
    }
    func move(from source: IndexSet, to destination: Int) {
        favorites.move(fromOffsets: source, toOffset: destination)
    }
    func remove(atOffsets offsets: IndexSet) {
        offsets.forEach { favorites.remove(at: $0) }
    }
    
    func unusedFavorites() -> [String] {
       var unusedFavoritesTemp: [String] = []
        
        for user in deviceData.allFavorites {
            if (favorites.firstIndex(of: user) == nil) {
                unusedFavoritesTemp.append(String(user))
            }
        }
        return(unusedFavoritesTemp)
    }


}

struct Widget: View {
    @Environment(\.colorScheme) var scheme
    var widgetName: String
    
    var body: some View {
        if widgetName == "Steps" {
            StepsWidget()
        } else if widgetName == "Heart" {
            HeartWidget()
        } else if widgetName == "Battery" {
            BatteryWidget()
        } else {
            Text("Error: No Widget Found.")
        }
    }
}

struct StepsWidget: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @AppStorage("stepCountGoal") var stepCountGoal = 10000
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: StepView()) {
            VStack {
                HStack {
                    Image(systemName: "figure.walk")
                        .foregroundColor(.blue)
                    Text(NSLocalizedString("steps", comment: ""))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    //bleManager.stepCount
                    Text(String(bleManagerVal.stepCount))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("with a goal of \(stepCountGoal)")
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}


struct HeartWidget: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: HeartView()) {
            VStack {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text("Heart Rate")
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text(String(Int(bleManagerVal.heartBPM)))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text(NSLocalizedString("bpm", comment: ""))
                        .foregroundColor(.gray)
                        .bold()
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}

struct BatteryWidget: View {
    @ObservedObject var bleManagerVal = BLEManagerVal.shared
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var scheme
    var body: some View {
        NavigationLink(destination: BatteryView()) {
            VStack {
                HStack {
                    Image(systemName: "battery." + String(Int(round(Double(String(format: "%.0f",   bleManager.batteryLevel))! / 25) * 25)))
                        .imageScale(.large)
                        .foregroundColor(.green)
                    Text("Battery")
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Spacer(minLength: 24)
                HStack(alignment: .bottom) {
                    Text(String(format: "%.0f", bleManager.batteryLevel))
                        .foregroundColor(scheme == .dark ? .white : .black)
                        .font(.system(size: 28))
                        .bold()
                    Text("%")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(5)
        }
    }
}
