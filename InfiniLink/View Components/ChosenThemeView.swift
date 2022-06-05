//
//  ChosenThemeView.swift
//  InfiniLink
//
//  Created by John Stanley on 5/5/22.
//

import SwiftUI

struct SettingsChosenThemeView: View {
    @Binding var chosenTheme: String
    let themes: [String] = ["System Default", "Light", "Dark"]
    
    var body: some View {
        VStack {
            Picker(NSLocalizedString("avaliable_themes", comment: ""), selection: $chosenTheme) {
                ForEach(themes, id: \.self) {
                    Text($0)
                }
            }
            .pickerStyle(.wheel)
        }
        .navigationBarTitle(Text(NSLocalizedString("choose_app_theme", comment: ""))) //.font(.subheadline), displayMode: .inline)
    }
}

struct SettingsChosenThemeView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsChosenThemeView(chosenTheme: .constant("System Default"))
    }
}
