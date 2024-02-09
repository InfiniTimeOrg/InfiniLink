//
//  MusicController.swift
//  InfiniLink
//
//  Created by Alex Emry on 8/7/21.
//

import Foundation
import MediaPlayer
import NotificationCenter

class MusicController {
	/*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
	For now, this is a rudimentary implementation of apple's MediaPlayer framework, which unfortunately only works with Apple Music. Apple does not allow control of system volume levels at from the app level, so the volume controls do not work currently. Control of the "Now Playing" media on the device is also not supported at the app level, so we have to specifically work with Apple Music through the existing framework.
	
	In the future, if Apple's proprietary AMS (Apple Media Service) is implemented in InfiniTime, these controls should work on their own, and the track/artist/elapsed time/total time should automatically populate. Not sure how much work that would be to implement, so this may be the best we can do for a while.
	
	TODO: figure out the formatting that PineTime expects for time elapsed/total time. Hex value of 0101 = 12:32, 0102 = 04:48. Writing decimal does nothing. ASCII also gives wacky results
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*/
	static let shared = MusicController()
	let bleManager = BLEManager.shared
    let bleManagerVal = BLEManagerVal.shared
	
	var musicPlayer = MPMusicPlayerController.systemMusicPlayer
    var musicPlaying = 0
    
    let volumeSlots : Float = 15.0
	
	struct songInfo {
		var trackName: String!
		var artistName: String!
	}
	
	enum musicState {
		case play, pause, nextTrack, prevTrack
	}
	init() {
		musicPlayer.beginGeneratingPlaybackNotifications()
		NotificationCenter.default.addObserver(self, selector: #selector(self.onNotificationReceipt(_:)), name: .MPMusicPlayerControllerPlaybackStateDidChange, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(self.onNotificationReceipt(_:)), name: .MPMusicPlayerControllerNowPlayingItemDidChange, object: nil)
	}
	
	@objc func onNotificationReceipt(_ notification: NSNotification) {
		musicPlaying = musicPlayer.playbackState.rawValue
		updateMusicInformation(songInfo: getCurrentSongInfo())
	}
	
	func controlMusic(controlNumber: Int) {
		
		// when CoreBluetooth gets an update from the music control characteristic, parse that number and take an action, and in any case, make sure the track and artist are relatively up to date
        
        
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(false)
        } catch let error as NSError {
            print("Unable to activate audio session:  \(error.localizedDescription)")
        }
        musicPlaying = musicPlayer.playbackState.rawValue
        
		switch controlNumber {
		case 0:
            musicPlayer.play(); musicPlaying = 1
        case 1:
            musicPlayer.pause(); musicPlaying = 2
		case 3:
            musicPlayer.skipToNextItem()
		case 4:
			musicPlayer.skipToPreviousItem()
		case 5:
            if session.outputVolume + (1 / volumeSlots) > 1.0 {MPVolumeView.setVolume(1.0)} else {MPVolumeView.setVolume(session.outputVolume + (1 / volumeSlots))}
        case 6:
            if session.outputVolume - (1 / volumeSlots) < 0.0 {MPVolumeView.setVolume(0.0)} else {MPVolumeView.setVolume(session.outputVolume - (1 / volumeSlots))}
		case 224:
			updateMusicInformation(songInfo: getCurrentSongInfo())
		default:
			break
		}
        updateMusicInformation(songInfo: getCurrentSongInfo())
	}
	
	
	func getCurrentSongInfo() -> songInfo {
		let currentTrack = musicPlayer.nowPlayingItem
		let currentSongInfo = songInfo(trackName: currentTrack?.title ?? NSLocalizedString("not_playing", comment: ""), artistName: currentTrack?.artist ?? NSLocalizedString("not_playing", comment: ""))
		return currentSongInfo
	}
	
    func updateMusicInformation(songInfo: MusicController.songInfo) {
        let bleWriteManager = BLEWriteManager()
        
		let songInfo = getCurrentSongInfo()
		
		bleWriteManager.writeToMusicApp(message: songInfo.trackName, characteristic: bleManagerVal.musicChars.track)
		bleWriteManager.writeToMusicApp(message: songInfo.artistName, characteristic: bleManagerVal.musicChars.artist)
        
        var playbackTime = musicPlayer.currentPlaybackTime; if playbackTime == musicPlayer.nowPlayingItem?.playbackDuration {playbackTime = 0.0}
        bleWriteManager.writeHexToMusicApp(message: convertTime(value: playbackTime), characteristic: bleManagerVal.musicChars.position)
        bleWriteManager.writeHexToMusicApp(message: convertTime(value: musicPlayer.nowPlayingItem?.playbackDuration ?? 0.0), characteristic: bleManagerVal.musicChars.length)
        
        if musicPlaying == 1 {
            bleWriteManager.writeHexToMusicApp(message: [0x01], characteristic: bleManagerVal.musicChars.status)
        } else {
            bleWriteManager.writeHexToMusicApp(message: [0x00], characteristic: bleManagerVal.musicChars.status)
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
