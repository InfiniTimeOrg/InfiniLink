//
//  AppearanceView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/15/24.
//

import SwiftUI

enum AppIcon: CaseIterable {
    case `default`
    case one
    
    init(from name: String) {
        switch name {
        case "AppIcon-1": self = .one
        default: self = .default
        }
    }
    
    var name: String? {
        switch self {
        case .default:
            return nil
        case .one:
            return "AppIcon-1"
        }
    }
    
    var description: String {
        switch self {
        case .default:
            return "InfiniLink"
        case .one:
            return "InfiniLink 2"
        }
    }
    
    var icon: Image {
        switch self {
        case .default:
            return Image("appIcon")
        case .one:
            return Image("appIcon-1")
        }
    }
}

struct AppearanceView: View {
    @State private var selectedIcon: AppIcon = .default
    
    func getCurrentIcon() {
        if let iconName = UIApplication.shared.alternateIconName {
            selectedIcon = AppIcon(from: iconName)
        } else {
            selectedIcon = .default
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
                print("Could not update icon \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        List {
            Section("App Icon") {
                ForEach(AppIcon.allCases, id: \.self) { icon in
                    Button {
                        if icon != selectedIcon {
                            updateIcon(with: icon.name ?? "AppIcon")
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
