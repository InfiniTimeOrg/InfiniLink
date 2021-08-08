//
//  MusicController.swift
//  Infini-iOS
//
//  Created by xan-m on 8/7/21.
//

import Foundation
import MediaPlayer

class MusicController: NSObject, ObservableObject{
	/*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*
	For now, this is a rudimentary implementation of apple's MediaPlayer framework, which unfortunately only works with Apple Music. Apple does not allow control of system volume levels at from the app level, so the volume controls do not work currently. Control of the "Now Playing" media on the device is also not supported at the app level, so we have to specifically work with Apple Music through the existing framework.
	
	In the future, if Apple's proprietary AMS (Apple Media Service) is implemented in InfiniTime, these controls should work on their own, and the track/artist/elapsed time/total time should automatically populate. Not sure how much work that would be to implement, so this may be the best we can do for a while.
	
	TODO: figure out the formatting that PineTime expects for time elapsed/total time. Hex value of 0101 = 12:32, 0102 = 04:48. Writing decimal does nothing. ASCII also gives wacky results
	*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*~*/
	
	var musicPlayer = MPMusicPlayerController.systemMusicPlayer
	
	let volumeView = MPVolumeView()
	
	struct songInfo {
		var trackName: String!
		var artistName: String!
		//var currentDuration: Int
	}
	
	override init() {
		super.init()
	}
	
	func getPlaybackStatus() -> Int {
		musicPlayer.playbackState.rawValue
	}
	
	func pause() {
		musicPlayer.pause()
	}
	
	func play() {
		musicPlayer.play()
	}
	
	func nextTrack() {
		musicPlayer.skipToNextItem()
	}
	
	func prevTrack() {
		musicPlayer.skipToPreviousItem()
	}
	
	func getCurrentSongInfo() -> songInfo {
		let currentTrack = musicPlayer.nowPlayingItem
		let currentSongInfo = songInfo(trackName: currentTrack?.title ?? "Not Playing", artistName: currentTrack?.artist ?? "Not Playing")
		return currentSongInfo
	}
}
