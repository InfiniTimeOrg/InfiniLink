//
//  FSFile.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/8/24.
//

import Foundation

struct FSFile: Identifiable {
    let id = UUID()
    var url: URL?
    var filename: String
}
