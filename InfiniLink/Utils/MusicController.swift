//
//  MusicController.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/7/21.
//

import Foundation
import MediaPlayer
import NotificationCenter
import SwiftUI

class MusicController {
    static let shared = MusicController()
    
    private let session = AVAudioSession.sharedInstance()
    private let bleManager = BLEManager.shared
    private let bleWriteManager = BLEWriteManager()
    private let volumeNotch: Float = (1 / 15)
    private var musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var musicPlaying = 0
    
    struct SongInfo {
        var trackName: String = ""
        var artistName: String = ""
    }
    
    enum MusicState {
        case play, pause, nextTrack, prevTrack
    }
    
    @AppStorage("allowMusicControl") var allowMusicControl = true
    @AppStorage("allowVolumeControl") var allowVolumeControl = true
    
    init() {
        musicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onPlaybackChange(_:)), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onNowPlayingChange(_:)), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
        
        initSession()
    }
    
    @objc func onPlaybackChange(_ notification: NSNotification) {
        musicPlaying = musicPlayer.playbackState.rawValue
        updateMusicInformation()
    }
    @objc func onNowPlayingChange(_ notification: NSNotification) {
        updateMusicInformation()
    }
    
    func initSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            do {
                try self?.session.setCategory(.playback, options: .mixWithOthers)
                try self?.session.setActive(true)
            } catch {
                log("Unable to configure audio session: \(error.localizedDescription)", caller: "MusicController")
                return
            }
        }
    }
    
    func controlMusic(controlNumber: Int) {
        guard allowMusicControl else { return }
        
        musicPlaying = musicPlayer.playbackState.rawValue
        
        switch controlNumber {
        case 0:
            musicPlayer.play()
            musicPlaying = 1
        case 1:
            pause()
        case 3:
            musicPlayer.skipToNextItem()
        case 4:
            musicPlayer.skipToPreviousItem()
        case 5:
            changeVolume(up: true)
        case 6:
            changeVolume(up: false)
        default:
            break
        }
        
        updateMusicInformation()
    }
    
    func changeVolume(up: Bool) {
        guard allowVolumeControl else { return }
        
        let sessionVolume = session.outputVolume
        
        let volume = up ? min(sessionVolume + volumeNotch, 1.0) : max(sessionVolume - volumeNotch, 0.0)
        MPVolumeView.setVolume(volume)
    }
    
    func getCurrentSongInfo() -> SongInfo {
        let currentTrack = self.musicPlayer.nowPlayingItem
        return SongInfo(trackName: currentTrack?.title ?? "Not Playing", artistName: currentTrack?.artist ?? "")
    }
    
    func updateMusicInformation() {
        let songInfo = getCurrentSongInfo()
        
        guard
            let statusChar = bleManager.musicChars.status,
            let trackChar = bleManager.musicChars.track,
            let artistChar = bleManager.musicChars.artist,
            let positionChar = bleManager.musicChars.position,
            let lengthChar = bleManager.musicChars.length
        else {
            log("Music characteristics not available, skipping update", caller: "MusicController")
            return
        }
        
        bleWriteManager.writeHexToMusicApp(message: musicPlaying == 1 ? [0x01] : [0x00],
                                           characteristic: statusChar)
        bleWriteManager.writeToMusicApp(message: songInfo.trackName, characteristic: trackChar)
        bleWriteManager.writeToMusicApp(message: songInfo.artistName, characteristic: artistChar)
        
        guard let nowPlayingItem = musicPlayer.nowPlayingItem else { return }
        
        var playbackTime = musicPlayer.currentPlaybackTime
        if playbackTime == nowPlayingItem.playbackDuration {
            playbackTime = 0.0
        }
        
        bleWriteManager.writeHexToMusicApp(message: convertTime(value: playbackTime),
                                           characteristic: positionChar)
        bleWriteManager.writeHexToMusicApp(message: convertTime(value: nowPlayingItem.playbackDuration),
                                           characteristic: lengthChar)
    }
    
    func pause() {
        guard musicPlayer.playbackState != .paused  else { return }
        
        musicPlayer.pause()
        musicPlaying = 2
    }
    
    func convertTime(value: Double) -> [UInt8] {
        guard value.isFinite && !value.isNaN else {
            return [0, 0, 0, 0]
        }
        
        let val32: UInt32 = UInt32(floor(value))
        
        let byte1 = UInt8(val32 & 0x000000FF)
        let byte2 = UInt8((val32 & 0x0000FF00) >> 8)
        let byte3 = UInt8((val32 & 0x00FF0000) >> 16)
        let byte4 = UInt8((val32 & 0xFF000000) >> 24)
        
        return [byte4, byte3, byte2, byte1]
    }
}

extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            slider?.value = volume
        }
    }
}
