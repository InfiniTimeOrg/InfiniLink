//
//  MusicController.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/7/21.
//

import Foundation
import MediaPlayer

class MusicController {
	/*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
	For now, this is a rudimentary implementation of apple's MediaPlayer framework, which unfortunately only works with Apple Music. Apple does not allow control of system volume levels at from the app level, so the volume controls do not work currently. Control of the "Now Playing" media on the device is also not supported at the app level, so we have to specifically work with Apple Music through the existing framework.
	
	In the future, if Apple's proprietary AMS (Apple Media Service) is implemented in InfiniTime, these controls should work on their own, and the track/artist/elapsed time/total time should automatically populate. Not sure how much work that would be to implement, so this may be the best we can do for a while.
	
	TODO: figure out the formatting that PineTime expects for time elapsed/total time. Hex value of 0101 = 12:32, 0102 = 04:48. Writing decimal does nothing. ASCII also gives wacky results
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*/
	
	let bleManager = BLEManager.shared
	
	var musicPlayer = MPMusicPlayerController.systemMusicPlayer
	
	struct songInfo {
		var trackName: String!
		var artistName: String!
	}
	
	enum musicState {
		case play, pause, nextTrack, prevTrack
	}
	
	func controlMusic(controlNumber: Int) {
		
		// when CoreBluetooth gets an update from the music control characteristic, parse that number and take an action, and in any case, make sure the track and artist are relatively up to date
		switch controlNumber {
		case 0:
			if musicPlayer.playbackState.rawValue == 1 {
				musicPlayer.pause()
			} else {
				musicPlayer.play()
			}
		case 2:
			// system volume controls are not accessible from an app
			break
		case 3:
			musicPlayer.skipToNextItem()
		case 4:
			musicPlayer.skipToPreviousItem()
		case 5:
			// system volume controls are not accessible from an app
			break
		default:
			break
		}
		updateMusicInformation(songInfo: getCurrentSongInfo())
	}
	
	
	func getCurrentSongInfo() -> songInfo {
		let currentTrack = musicPlayer.nowPlayingItem
		let currentSongInfo = songInfo(trackName: currentTrack?.title ?? "Not Playing", artistName: currentTrack?.artist ?? "Not Playing")
		return currentSongInfo
	}
	
	func updateMusicInformation(songInfo: MusicController.songInfo) {
		let bleWriteManager = BLEWriteManager()
		let songInfo = getCurrentSongInfo()
		
		bleWriteManager.writeToMusicApp(message: songInfo.trackName, characteristic: bleManager.musicChars.track)
		bleWriteManager.writeToMusicApp(message: songInfo.artistName, characteristic: bleManager.musicChars.artist)
	}
}
