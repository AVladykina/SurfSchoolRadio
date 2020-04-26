//
//  RadioPlayer.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/23/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import AVFoundation

// MARK: - RadioPlayingState

@objc public enum RadioPlaybackState: Int {
    
    case playing
    case paused
    case stopped
    
    public var description: String {
        switch self {
        case .playing: return "Player is playing"
        case .paused: return "Player is paused"
        case .stopped: return "Player is stopped"
        }
    }
}

// MARK: - RadioPlayerState


@objc public enum RadioPlayerState: Int {
    
    case urlNotSet
    case readyToPlay
    case loading
    case loadingFinished
    case error
    
    public var description: String {
        switch self {
        case .urlNotSet: return "URL is not set"
        case .readyToPlay: return "Ready to play"
        case .loading: return "Loading"
        case .loadingFinished: return "Loading finished"
        case .error: return "Error"
        }
    }
}

// MARK: - RadioPlayerDelegate


@objc public protocol RadioPlayerDelegate: class {
    
    func radioPlayer(_ player: RadioPlayer, playerStateDidChange state: RadioPlayerState)
    func radioPlayer(_ player: RadioPlayer, playbackStateDidChange state: RadioPlaybackState)
    @objc optional func radioPlayer(_ player: RadioPlayer, itemDidChange url: URL?)
    @objc optional func radioPlayer(_ player: RadioPlayer, metadataDidChange artistName: String?, trackName: String?)
    @objc optional func radioPlayer(_ player: RadioPlayer, artworkDidChange artworkURL: URL?)
    
}



open class RadioPlayer: NSObject {
    
    public static let shared = RadioPlayer()

    open weak var delegate: RadioPlayerDelegate?
    
    open var radioURL: URL? {
        didSet {
            radioURLDidChange(with: radioURL)
        }
    }
    
    open var isAutoPlay = true
    
    open var enableAlbum = true
    
    open var artworkSize = 100
    
    
    open var isPlaying: Bool {
        switch playbackState {
        case .playing:
            return true
        case .stopped, .paused:
            return false
        }
    }
    
    open var state = RadioPlayerState.urlNotSet {
        didSet {
            guard oldValue != state else { return }
            delegate?.radioPlayer(self, playerStateDidChange: state)
        }
    }
    
    open var playbackState = RadioPlaybackState.stopped {
        didSet {
            guard oldValue != playbackState else { return }
            delegate?.radioPlayer(self, playbackStateDidChange: playbackState)
        }
    }
    
    open var volume: Float? {
        get {
            return player?.volume
        }
        set {
            guard
                let newValue = newValue,
                0.0...1.0 ~= newValue else { return }
            player?.volume = newValue
        }
    }
    
    var player: AVPlayer?
    var lastPlayerItem: AVPlayerItem?
    var playerItem: AVPlayerItem? {
        didSet {
            playerItemDidChange()
        }
    }
    

    let reachability = Reachability()!

    var isConnected = false

    // MARK: - Initialization

    override init() {
        super.init()
    
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
    
         setupNotifications()
    
        try? reachability.startNotifier()
        NotificationCenter.default.addObserver(self, selector: #selector(reachabilityChanged(note:)), name: .reachabilityChanged, object: reachability)
        isConnected = reachability.connection != .none
    }

    // MARK: - Control Methods

    
    open func play() {
        guard let player = player else { return }
        if player.currentItem == nil, playerItem != nil {
            player.replaceCurrentItem(with: playerItem)
        }
    
        player.play()
        playbackState = .playing
    }


    open func pause() {
        guard let player = player else { return }
        player.pause()
        playbackState = .paused
    }

    
    open func stop() {
        guard let player = player else { return }
        playbackState = .stopped
        player.replaceCurrentItem(with: nil)
        
    }

    
    open func togglePlaying() {
        isPlaying ? pause() : play()
    }

   

    private func radioURLDidChange(with url: URL?) {
        resetPlayer()
        guard let url = url else { state = .urlNotSet; return }
        
        state = .loading
        
        preparePlayer(with: AVAsset(url: url)) { (success, asset) in
            guard success, let asset = asset else {
                self.resetPlayer()
                self.state = .error
                return
            }
            self.setupPlayer(with: asset)
        }
    }

    private func setupPlayer(with asset: AVAsset) {
        if player == nil {
            player = AVPlayer()
        }
        
        playerItem = AVPlayerItem(asset: asset)
    }

    
    func playerItemDidChange() {
        
        guard lastPlayerItem != playerItem else { return }
        
        if let item = lastPlayerItem {
            pause()
            
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: item)
            item.removeObserver(self, forKeyPath: "status")
            item.removeObserver(self, forKeyPath: "playbackBufferEmpty")
            item.removeObserver(self, forKeyPath: "playbackLikelyToKeepUp")
            item.removeObserver(self, forKeyPath: "timedMetadata")
        }
    
        lastPlayerItem = playerItem
        
        
        if let item = playerItem {
            
            item.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackBufferEmpty", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "playbackLikelyToKeepUp", options: NSKeyValueObservingOptions.new, context: nil)
            item.addObserver(self, forKeyPath: "timedMetadata", options: NSKeyValueObservingOptions.new, context: nil)
            
            player?.replaceCurrentItem(with: item)
            if isAutoPlay { play() }
        }
        
        delegate?.radioPlayer?(self, itemDidChange: radioURL)
    }

    
    func preparePlayer(with asset: AVAsset?, completionHandler: @escaping (_ isPlayable: Bool, _ asset: AVAsset?)->()) {
        guard let asset = asset else {
            completionHandler(false, nil)
            return
        }
        
        let requestedKey = ["playable"]
        
        asset.loadValuesAsynchronously(forKeys: requestedKey) {
            
            DispatchQueue.main.async {
                var error: NSError?
                
                let keyStatus = asset.statusOfValue(forKey: "playable", error: &error)
                if keyStatus == AVKeyValueStatus.failed || !asset.isPlayable {
                    completionHandler(false, nil)
                    return
                }
                
                completionHandler(true, asset)
            }
        }
    }


    func reloadItem() {
        player?.replaceCurrentItem(with: nil)
        player?.replaceCurrentItem(with: playerItem)
    }

    func resetPlayer() {
        stop()
        playerItem = nil
        lastPlayerItem = nil
        player = nil
    }

    deinit {
        resetPlayer()
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Notifications

    func setupNotifications() {

        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(handleInterruption), name: AVAudioSession.interruptionNotification, object: nil)
        
        
    }

    // MARK: - Responding to Interruptions

    @objc func handleInterruption(notification: Notification) {
        
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                return
        }
        switch type {
        case .began:
            DispatchQueue.main.async { self.pause() }
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { break }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            DispatchQueue.main.async { options.contains(.shouldResume) ? self.play() : self.pause() }
        @unknown default:
            break
        }
        
    }

    @objc func reachabilityChanged(note: Notification) {
        
        guard let reachability = note.object as? Reachability else { return }
        
        if reachability.connection != .none, !isConnected {
            checkNetworkInterruption()
        }
        
        isConnected = reachability.connection != .none
    }

    
    func checkNetworkInterruption() {
        guard
            let item = playerItem,
            !item.isPlaybackLikelyToKeepUp,
            reachability.connection != .none else { return }
        
        player?.pause()
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
            if !item.isPlaybackLikelyToKeepUp { self.reloadItem() }
            self.isPlaying ? self.player?.play() : self.player?.pause()
        }
    }
   
}



