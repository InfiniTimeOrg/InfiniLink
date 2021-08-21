//
//  BLEMusic.swift
//  Infini-iOS
//
//  Created by Alex Emry on 8/7/21.
//

import Foundation

extension BLEManager{
	func controlMusic(controlNumber: Int) {

		let musicController = MusicController()
		
		// when CoreBluetooth gets an update from the music control characteristic, parse that number and take an action, and in any case, make sure the track and artist are relatively up to date
		switch controlNumber {
		case 0:
			if musicController.getPlaybackStatus() == 1 {
				musicController.pause()
			} else {
				musicController.play()
			}
		case 2:
			print("volUp") // system volume controls are not accessible from an app
		case 3:
			musicController.nextTrack()
		case 4:
			musicController.prevTrack()
		case 5:
			print("volDown") // system volume controls are not accessible from an app
		default:
			break
		}
		updateMusicInformation(songInfo: musicController.getCurrentSongInfo())
	}
	func updateMusicInformation(songInfo: MusicController.songInfo) {
		let musicController = MusicController()
		let songInfo = musicController.getCurrentSongInfo()
		
		writeASCIIToPineTime(message: songInfo.trackName, characteristic: musicChars.track)
		writeASCIIToPineTime(message: songInfo.artistName, characteristic: musicChars.artist)
	}
}
