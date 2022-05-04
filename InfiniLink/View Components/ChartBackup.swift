//
//  ChartBackup.swift
//  InfiniLink
//
//  Created by Micah Stanley on 11/15/21.
//

import Foundation
import SwiftUI

struct ChartBackup: View {
    
    @ObservedObject var bleManager = BLEManager.shared
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack {
            HStack {
                Text("Charts")
                    .font(.largeTitle)
                    .padding(.leading)
                    .padding(.vertical)
                    .frame(alignment: .leading)
                Button {
                    SheetManager.shared.sheetSelection = .chartSettings
                    SheetManager.shared.showSheet = true
                } label: {
                    Image(systemName: "gear")
                        .imageScale(.large)
                        .padding(.vertical)
                }
                Spacer()
            }
//            TimeRangeTabs()
            StatusTabs()
            CurrentChart()
        }
    }
}

struct ChartView_Previews: PreviewProvider {
    static var previews: some View {
        ChartView()
            //.environmentObject(PageSwitcher())
            .environmentObject(BLEManager())
    }
}
