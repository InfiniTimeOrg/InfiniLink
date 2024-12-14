//
//  TableView.swift
//  InfiniLink
//
//  Created by Liam Willey on 12/1/24.
//

import SwiftUI

struct TableView: View {
    let data: [[String]]
    
    var body: some View {
        VStack(alignment: .leading) {
            ForEach(0..<data.count, id: \.self) { rowIndex in
                HStack {
                    ForEach(0..<data[rowIndex].count, id: \.self) { colIndex in
                        Text(data[rowIndex][colIndex])
                            .frame(minWidth: 100, alignment: .leading)
                            .padding(5)
                            .border(Color.gray)
                    }
                }
            }
        }
        .padding()
    }
}
