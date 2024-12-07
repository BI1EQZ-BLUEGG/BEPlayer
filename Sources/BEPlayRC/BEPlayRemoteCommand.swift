//
//  BEPlayRemoteCommand.swift
//  BEPlayer
//
//  Created by bluegg on 2024/12/7.
//

import AVFoundation
import MediaPlayer
import UIKit

public class BEPlayRemoteCommand {

    public static let shared = BEPlayRemoteCommand()
    
    /// 事件回调
    public var onCommand: ((BEPlayRemoteCommand.Action) -> Void)?
    
    /// 是否启用
    public var isEnabled: Bool = false {
        didSet {
            isEnabled
            ? UIApplication.shared.beginReceivingRemoteControlEvents()
            : UIApplication.shared.endReceivingRemoteControlEvents()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var isScreenOn: Bool = false
    
    private var info: [String: Any] = [:]
    
    private init() {
        registerScreenNotifications()
        setupRemoteCommandCenter()
    }
    
    public func clean() {
        info.removeAll()
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [:]
    }
    
    public func update(
        title: String? = nil,
        artist: String? = nil,
        albumTitle: String? = nil,
        time: TimeInterval? = nil,
        duration: TimeInterval? = nil,
        rate: Float? = nil,
        lyrics: String? = nil,
        image: UIImage? = nil
    ) {
        if !isEnabled { return }
        
        if let title {
            info[MPMediaItemPropertyTitle] = title
        }
        if let artist {
            info[MPMediaItemPropertyArtist] = artist
        }
        if let albumTitle {
            info[MPMediaItemPropertyAlbumTitle] = albumTitle
        }
        if let time {
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
        }
        if let duration {
            info[MPMediaItemPropertyPlaybackDuration] = duration
        }
//        if let rate {
//            info[MPMediaItemPropertyRating] = rate
//        }
        if let lyrics {
            info[MPMediaItemPropertyLyrics] = lyrics
        }
        if let image {
            let artwork = MPMediaItemArtwork(boundsSize: image.size, requestHandler: {_ in return image })
            info[MPMediaItemPropertyArtwork] = artwork
        }
        if !info.isEmpty {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = info
        }
    }

    private func registerScreenNotifications() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidTurnOn),
            name: UIScreen.didConnectNotification, object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(screenDidTurnOff),
            name: UIScreen.didDisconnectNotification, object: nil)
    }
    
    private func registerAppStateNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(appState(_:)), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appState(_:)), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appState(_:)), name: UIApplication.willResignActiveNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appState(_:)), name: UIApplication.didBecomeActiveNotification, object: nil)
        
    }

    private func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.onCommand?(.play)
            return .success
        }

        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.onCommand?(.pause)
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.onCommand?(.next)
            return .success
        }

        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.onCommand?(.previous)
            return .success
        }

        commandCenter.togglePlayPauseCommand.addTarget { [weak self] abc in
            self?.onCommand?(.togglePlayPause)
            return .success
        }

        commandCenter.likeCommand.addTarget { [weak self] _ in
            self?.onCommand?(.like)
            return .success
        }
    }
}

extension BEPlayRemoteCommand {

    @objc private func screenDidTurnOn() {
        isScreenOn = true
    }

    @objc private func screenDidTurnOff() {
        isScreenOn = false
    }
    
    @objc private func appState(_ notification: Notification) {
        switch notification.name {
        case UIApplication.didEnterBackgroundNotification:
            break
        case UIApplication.willEnterForegroundNotification:
            break
        case UIApplication.willResignActiveNotification:
            break
        case UIApplication.didBecomeActiveNotification:
            break
        default:
            break
        }
    }
}

extension BEPlayRemoteCommand {

    public enum Action {
        case play, pause, togglePlayPause, next, previous, like, mark
    }
}
