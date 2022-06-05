//
//  StepsView.swift
//  InfiniLink
//
//  Created by Alex Emry on 10/21/21.
//  
//
    
import SwiftUI

struct StepView: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        return GeometryReader { g in
            VStack {
                List() {
                    
                    Section() {
                        HStack {
                            StepProgress()
                                .padding()
                                .frame(width: (g.size.width / 1.8), height: (g.size.width / 1.8), alignment: .center)
                        }
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section() {
                        VStack {
                            Spacer(minLength: 20.0)
                            StepWeekly()
                                .frame(height: (g.size.width / 2.2), alignment: .center)
                        }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    
                    Section() {
                        HStack {
                            StepCalendar()
                                .padding()
                                .frame(alignment: .init(horizontal: .center, vertical: .top))
                                .frame(height: (g.size.width), alignment: .center)
                        }
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
                .navigationBarItems(trailing: (
                    Button {
                        SheetManager.shared.sheetSelection = .stepSettings
                        SheetManager.shared.showSheet = true
                    } label: {
                        Image(systemName: "gear")
                            .imageScale(.medium)
                            .padding(.vertical)
                    }
                ))
                .navigationBarTitle(Text(NSLocalizedString("steps", comment: ""))) //.font(.subheadline), displayMode: .inline)
            }
        }
    }
}
