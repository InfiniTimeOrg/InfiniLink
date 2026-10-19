//
//  WatchFaceCatalog.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/18/26.
//

import SwiftUI

struct WatchFaceEntry: Codable, Hashable, Identifiable {
    var id: UInt8 { index }
    var index: UInt8 // The watch face's value in InfiniTime's WatchFace enum
    let name: String
    var isCustom = false
    var imageFile: String? // An optional photo of the face used as its preview
}

class WatchFaceCatalog: ObservableObject {
    static let shared = WatchFaceCatalog()

    static let builtIn = [
        WatchFaceEntry(index: 0, name: "Digital"),
        WatchFaceEntry(index: 1, name: "Analog"),
        WatchFaceEntry(index: 2, name: "PineTimeStyle"),
        WatchFaceEntry(index: 3, name: "Terminal"),
        WatchFaceEntry(index: 4, name: "Infineat"),
        WatchFaceEntry(index: 5, name: "Casio G7710"),
        WatchFaceEntry(index: 6, name: "Pride Flag")
    ]

    @Published var customFaces: [WatchFaceEntry] = [] {
        didSet { save() }
    }
    @Published var hiddenIndices: Set<UInt8> = [] {
        didSet { save() }
    }

    var visibleFaces: [WatchFaceEntry] {
        (Self.builtIn + customFaces).filter { !hiddenIndices.contains($0.index) }
    }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "customWatchFaces"), let faces = try? JSONDecoder().decode([WatchFaceEntry].self, from: data) {
            customFaces = faces
        }
        if let hidden = defaults.array(forKey: "hiddenWatchFaces") as? [Int] {
            hiddenIndices = Set(hidden.map { UInt8($0) })
        }
    }

    func name(for index: UInt8) -> String {
        (Self.builtIn + customFaces).first { $0.index == index }?.name ?? String(format: NSLocalizedString("Watch Face %d", comment: ""), Int(index))
    }

    // Custom faces come after the built in ones, so the index is just the position
    private func reindex(_ faces: [WatchFaceEntry]) -> [WatchFaceEntry] {
        faces.enumerated().map { offset, face in
            var face = face
            face.index = UInt8(clamping: Self.builtIn.count + offset)
            return face
        }
    }

    func addCustomFace(name: String) {
        customFaces = reindex(customFaces + [WatchFaceEntry(index: 0, name: name, isCustom: true)])
    }

    func moveCustomFaces(from source: IndexSet, to destination: Int) {
        var faces = customFaces
        faces.move(fromOffsets: source, toOffset: destination)
        customFaces = reindex(faces)
    }

    func removeCustomFaces(at offsets: IndexSet) {
        offsets.forEach { deleteImage(customFaces[$0].imageFile) }
        var faces = customFaces
        faces.remove(atOffsets: offsets)
        customFaces = reindex(faces)
    }

    func resetToDefaults() {
        customFaces.forEach { deleteImage($0.imageFile) }
        customFaces = []
        hiddenIndices = []
    }

    private static var imageDirectory: URL {
        let url = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0].appendingPathComponent("WatchFaces")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    private func deleteImage(_ file: String?) {
        guard let file else { return }
        try? FileManager.default.removeItem(at: Self.imageDirectory.appendingPathComponent(file))
    }

    func setImage(_ image: UIImage?, for index: UInt8) {
        guard let position = customFaces.firstIndex(where: { $0.index == index }) else { return }

        deleteImage(customFaces[position].imageFile)
        customFaces[position].imageFile = nil
        if let data = image?.jpegData(compressionQuality: 0.8) {
            let file = UUID().uuidString + ".jpg"
            if (try? data.write(to: Self.imageDirectory.appendingPathComponent(file))) != nil {
                customFaces[position].imageFile = file
            }
        }
    }

    // Previews redraw every second, so cache the photos
    private var imageCache = [String: UIImage]()

    func image(for index: UInt8) -> UIImage? {
        guard let file = customFaces.first(where: { $0.index == index })?.imageFile else { return nil }
        if let cached = imageCache[file] {
            return cached
        }
        let image = UIImage(contentsOfFile: Self.imageDirectory.appendingPathComponent(file).path)
        imageCache[file] = image
        return image
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(try? JSONEncoder().encode(customFaces), forKey: "customWatchFaces")
        defaults.set(hiddenIndices.map { Int($0) }, forKey: "hiddenWatchFaces")
    }
}
