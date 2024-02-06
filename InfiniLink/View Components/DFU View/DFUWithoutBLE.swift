//
//  DFUWithoutBLE.swift
//  DFUWithoutBLE
//
//  Created by Alex Emry on 9/15/21.
//
//
    

import Foundation
import SwiftUI

struct DFUWithoutBLE: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 24).weight(.bold))
            Text(subtitle)
                .foregroundColor(.gray)
                .font(.body.weight(.medium))
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    DFUWithoutBLE(title: NSLocalizedString("bluetooth_not_available", comment: ""), subtitle: NSLocalizedString("please_enable_bluetooth_try_again", comment: ""))
}
