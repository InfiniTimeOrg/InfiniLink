//
//  AppearanceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/15/24.
//

import SwiftUI

enum AppIcon: CaseIterable {
    case one
    case two
    case three
    
    init(from name: String) {
        switch name {
        case "AppIcon-2":
            self = .two
        case "AppIcon-3":
            self = .three
        default:
            self = .one
        }
    }
    
    var name: String? {
        switch self {
        case .one:
            return nil
        case .two:
            return "AppIcon-2"
        case .three:
            return "AppIcon-3"
        }
    }
    
    var description: String {
        switch self {
        case .one:
            return "InfiniLink 1"
        case .two:
            return "InfiniLink 2"
        case .three:
            return "InfiniLink 3"
        }
    }
    
    var icon: Image {
        switch self {
        case .one:
            return Image(.appIconRendered)
        case .two:
            return Image(.appIcon2Rendered)
        case .three:
            return Image(.appIcon3Rendered)
        }
    }
}

struct AppearanceView: View {
    @State private var selectedIcon: AppIcon = .one
    
    @AppStorage("colorScheme") var colorScheme = "system"
    
    func getCurrentIcon() {
        if let iconName = UIApplication.shared.alternateIconName {
            selectedIcon = AppIcon(from: iconName)
        } else {
            selectedIcon = .one
        }
    }
    
    func updateIcon(with iconName: String?) {
        Task {
            do {
                guard UIApplication.shared.alternateIconName != iconName else {
                    return
                }
                try await UIApplication.shared.setAlternateIconName(iconName)
            } catch {
                log("Error updating app icon: \(error.localizedDescription)", caller: "AppearanceView")
            }
            
            getCurrentIcon()
        }
    }
    
    var body: some View {
        List {
            Section("Appearance") {
                Picker("Color Scheme", selection: $colorScheme) {
                    Text("System")
                        .tag("system")
                    Text("Dark")
                        .tag("dark")
                    Text("Light")
                        .tag("light")
                }
            }
            Section("App Icon") {
                ForEach(AppIcon.allCases, id: \.self) { icon in
                    Button {
                        if icon != selectedIcon {
                            updateIcon(with: icon.name ?? nil)
                        }
                    } label: {
                        HStack(spacing: 10) {
                            icon.icon
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 50)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            Text(icon.description)
                                .font(.title3)
                                .foregroundStyle(Color.primary)
                            Spacer()
                            if selectedIcon == icon {
                                Image(systemName: "checkmark")
                                    .font(.body.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Appearance")
        .onAppear {
            getCurrentIcon()
        }
    }
}

#Preview {
    AppearanceView()
}
