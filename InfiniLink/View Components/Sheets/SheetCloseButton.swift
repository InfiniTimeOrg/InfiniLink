//
//  SheetCloseButton.swift
//  InfiniLink
//
//  Created by Alex Emry on 9/24/21.
//  
//
    

import SwiftUI

struct SheetCloseButton: View {
    var body: some View {
        Button(action: {SheetManager.shared.showSheet = false}) {
            Image(systemName: "xmark")
                .imageScale(.medium)
                .padding(12)
                .font(.body.weight(.semibold))
                .foregroundColor(Color.darkGray)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
        }
    }
}
