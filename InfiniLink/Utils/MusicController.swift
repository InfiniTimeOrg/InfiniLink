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
    
    let bleManager = BLEManager.shared
    
    var musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var musicPlaying = 0
    
    let volumeSlots: Float = 15.0
    
    struct SongInfo {
        var trackName: String!
        var artistName: String!
    }
    
    enum MusicState {
        case play, pause, nextTrack, prevTrack
    }
    
    @AppStorage("allowMusicControl") var allowMusicControl = true
    @AppStorage("allowVolumeControl") var allowVolumeControl = true
    
    private init() {
        initialize()
    }
    
    @objc func onNotificationReceipt(_ notification: NSNotification) {
        musicPlaying = musicPlayer.playbackState.rawValue
        updateMusicInformation(songInfo: getCurrentSongInfo())
    }
    
    func initialize() {
        musicPlayer.beginGeneratingPlaybackNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(self.onNotificationReceipt(_:)), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.onNotificationReceipt(_:)), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
    }
    
    func controlMusic(controlNumber: Int) {
        if allowMusicControl {
            // When CoreBluetooth gets an update from the music control characteristic, parse that number and take an action, and in any case, make sure the track and artist are up-to-date
            
            let session = AVAudioSession.sharedInstance()
            
            do {
                try session.setCategory(.playback, options: .mixWithOthers)
                try session.setActive(false)
            } catch {
                log("Unable to activate audio session: \(error.localizedDescription)", caller: "MusicController")
            }
            musicPlaying = musicPlayer.playbackState.rawValue
            
            switch controlNumber {
            case 0:
                musicPlayer.play()
                musicPlaying = 1
            case 1:
                musicPlayer.pause()
                musicPlaying = 2
            case 3:
                musicPlayer.skipToNextItem()
            case 4:
                musicPlayer.skipToPreviousItem()
            case 5:
                if allowVolumeControl {
                    let newVolume = min(session.outputVolume + (1 / volumeSlots), 1.0)
                    MPVolumeView.setVolume(newVolume)
                }
            case 6:
                if allowVolumeControl {
                    let newVolume = max(session.outputVolume - (1 / volumeSlots), 0.0)
                    MPVolumeView.setVolume(newVolume)
                }
            default:
                break
            }
            
            updateMusicInformation(songInfo: getCurrentSongInfo())
        }
    }
    
    
    func getCurrentSongInfo() -> SongInfo {
        var currentSongInfo: SongInfo = SongInfo(trackName: "", artistName: "")
        
        DispatchQueue.main.async {
            let currentTrack = self.musicPlayer.nowPlayingItem
            currentSongInfo = SongInfo(trackName: currentTrack?.title ?? "Not Playing", artistName: currentTrack?.artist ?? "")
        }
        
        return currentSongInfo
    }
    
    func updateMusicInformation(songInfo: MusicController.SongInfo) {
        let bleWriteManager = BLEWriteManager()
        
        let songInfo = getCurrentSongInfo()
        
        bleWriteManager.writeToMusicApp(message: songInfo.trackName, characteristic: bleManager.musicChars.track)
        bleWriteManager.writeToMusicApp(message: songInfo.artistName, characteristic: bleManager.musicChars.artist)
        
        var playbackTime = musicPlayer.currentPlaybackTime; if playbackTime == musicPlayer.nowPlayingItem?.playbackDuration {playbackTime = 0.0}
        bleWriteManager.writeHexToMusicApp(message: convertTime(value: playbackTime), characteristic: bleManager.musicChars.position)
        bleWriteManager.writeHexToMusicApp(message: convertTime(value: musicPlayer.nowPlayingItem?.playbackDuration ?? 0.0), characteristic: bleManager.musicChars.length)
        
        if musicPlaying == 1 {
            bleWriteManager.writeHexToMusicApp(message: [0x01], characteristic: bleManager.musicChars.status)
        } else {
            bleWriteManager.writeHexToMusicApp(message: [0x00], characteristic: bleManager.musicChars.status)
        }
    }
    
    func convertTime(value: Double) -> [UInt8] {
        let val32 : UInt32 = UInt32(floor(value))
        
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
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
