//
//  VolumeAPI.swift
//  InfiniLink
//
//  Created by Liam Willey on 10/23/26.
//

import AVFoundation
import MediaPlayer
import JavaScriptCore

@objc protocol VolumeAPIExports: JSExport {
    var musicStream: VolumeStreamAPI { get }
}

// This is here for compatability (PinePartner's music stream)
final class VolumeAPI: NSObject, VolumeAPIExports {
    var musicStream: VolumeStreamAPI {
        return VolumeStreamAPI()
    }
}

@objc protocol VolumeStreamAPIExports: JSExport {
    var volume: Int { get set }
    
    func adjustVolume(_ direction: Int)
}

// 15 steps, like the volume buttons
final class VolumeStreamAPI: NSObject, VolumeStreamAPIExports {
    private let steps: Float = 15
    
    var volume: Int {
        get {
            if MockWatch.isAvailable {
                return MockMusicPlayer.shared.volume
            }
            return Int((AVAudioSession.sharedInstance().outputVolume * steps).rounded())
        }
        set {
            let volume = min(max(Float(newValue) / steps, 0), 1)
            DispatchQueue.main.async {
                if MockWatch.isAvailable {
                    MockMusicPlayer.shared.volume = Int(volume * self.steps)
                    return
                }
                MPVolumeView.setVolume(volume)
            }
        }
    }
    
    func adjustVolume(_ direction: Int) {
        volume += direction.signum()
    }
}
