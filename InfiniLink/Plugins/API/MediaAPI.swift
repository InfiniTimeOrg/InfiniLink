//
//  MediaAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import MediaPlayer
import JavaScriptCore

@objc protocol MediaAPIExports: JSExport {
    var state: [String: Any]? { get }
    var volume: Int { get set }

    func play()
    func pause()
    func next()
    func previous()
    func seek(_ seconds: Double)
    func addEventListener(_ event: String, _ callback: JSValue)
    func removeEventListener(_ event: String, _ callback: JSValue)
}

protocol PluginMusicPlayer: AnyObject {
    var currentPlaybackTime: TimeInterval { get set }

    func play()
    func pause()
    func skipToNextItem()
    func skipToPreviousItem()
    func beginGeneratingPlaybackNotifications()
}

extension MPMusicPlayerController: PluginMusicPlayer {}

// iOS only lets apps see and control Apple Music
final class MediaAPI: NSObject, MediaAPIExports {
    private weak var runner: PluginRunner?

    init(runner: PluginRunner) {
        self.runner = runner
    }

    // Main queue only
    static func currentState() -> [String: Any]? {
        if MockWatch.isAvailable {
            return MockMusicPlayer.shared.state
        }

        let player = MPMusicPlayerController.systemMusicPlayer
        guard let item = player.nowPlayingItem else { return nil }

        return [
            "isPlaying": player.playbackState == .playing,
            "position": Int(player.currentPlaybackTime.isFinite ? player.currentPlaybackTime : 0),
            "duration": Int(item.playbackDuration),
            "title": item.title ?? NSNull(),
            "artist": item.artist ?? NSNull(),
            "album": item.albumTitle ?? NSNull()
        ]
    }

    private func player(_ block: @escaping (PluginMusicPlayer) -> Void) {
        DispatchQueue.main.async {
            block(MockWatch.isAvailable ? MockMusicPlayer.shared : MPMusicPlayerController.systemMusicPlayer)
        }
    }

    var state: [String: Any]? {
        return DispatchQueue.main.sync { Self.currentState() }
    }

    var volume: Int {
        get {
            return VolumeStreamAPI().volume
        }
        set {
            VolumeStreamAPI().volume = newValue
        }
    }

    func play() {
        player { $0.play() }
    }

    func pause() {
        player { $0.pause() }
    }

    func next() {
        player { $0.skipToNextItem() }
    }

    func previous() {
        player { $0.skipToPreviousItem() }
    }

    func seek(_ seconds: Double) {
        guard seconds.isFinite, seconds >= 0 else {
            runner?.throwError("seek() takes a number of seconds")
            return
        }

        player { $0.currentPlaybackTime = seconds }
    }

    func addEventListener(_ event: String, _ callback: JSValue) {
        guard event == "change" else {
            runner?.throwError("Invalid event \(event)")
            return
        }

        runner?.mediaListeners.append(callback)
        player { $0.beginGeneratingPlaybackNotifications() }
    }

    func removeEventListener(_ event: String, _ callback: JSValue) {
        runner?.mediaListeners.removeAll { $0.isEqual(to: callback) }
    }
}
