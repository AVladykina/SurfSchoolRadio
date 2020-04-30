//
//  NowPlayingViewController.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/18/20.
//  Copyright © 2020 Surf. All rights reserved.
//


import UIKit
import MediaPlayer
import AVFoundation



protocol NowPlayingViewControllerDelegate: class {
    func didPressPlayingButton()
    func didPressStopButton()
    func didPressNextButton()
    func didPressPreviousButton()
}


class NowPlayingViewController: UIViewController {

    weak var delegate: NowPlayingViewControllerDelegate?
    
    @IBOutlet weak var albumImageView: UIImageView!
    
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var songLabel: UILabel!
    @IBOutlet weak var artistLabel: UILabel!
    
    @IBOutlet weak var volumeView: UIView!
    
    
    private var currentStation: RadioStation!
    private var currentTrack: Track!
    
    private var newStation = true
    
    private var mpVolumeSlider: UISlider?
    
    private let radioPlayer = RadioPlayer.shared
   
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = currentStation.name
    
        albumImageView.image = UIImage(named: "currentTrack.albumImage")
        

        setupVolumeSlider()
        
        newStation ? stationDidChange() : playerStateDidChange(radioPlayer.state, animate: false)
         }
    
    

    func setupVolumeSlider() {
        for subview in MPVolumeView().subviews {
            guard let volumeSlider = subview as? UISlider else { continue }
            mpVolumeSlider = volumeSlider
        }
        
        guard let mpVolumeSlider = mpVolumeSlider else { return }
        
        volumeView.addSubview(mpVolumeSlider)
        
        mpVolumeSlider.translatesAutoresizingMaskIntoConstraints = false
        mpVolumeSlider.leftAnchor.constraint(equalTo: volumeView.leftAnchor).isActive = true
        mpVolumeSlider.rightAnchor.constraint(equalTo: volumeView.rightAnchor).isActive = true
        mpVolumeSlider.centerYAnchor.constraint(equalTo: volumeView.centerYAnchor).isActive = true
        
        mpVolumeSlider.setThumbImage(#imageLiteral(resourceName: "slider-ball"), for: .normal)
    }
    
    
    func stationDidChange() {
        radioPlayer.radioURL = URL(string: currentStation.streamURL)
            albumImageView.image = currentTrack.albumImage
            title = currentStation.name
    }

    
    @IBAction func playingPressed(_ sender: Any) {
        delegate?.didPressPlayingButton()
    }
    
    @IBAction func stopPressed(_ sender: Any) {
        delegate?.didPressStopButton()
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        delegate?.didPressNextButton()
    }
    
    @IBAction func previousPressed(_ sender: Any) {
        delegate?.didPressPreviousButton()
    }
    
    
    func load(station: RadioStation?, track: Track?, isNewStation: Bool = true) {
        guard let station = station else { return }
        
        currentStation = station
        currentTrack = track
        newStation = isNewStation
    }
    
    func updateTrackMetadata(with track: Track?) {
        guard let track = track else { return }
        
        currentTrack.artist = track.artist
        currentTrack.title = track.title
        
        updateLabels()
    }
    
    func updateTrackAlbum(with track: Track?) {
        guard let track = track else { return }
        
        currentTrack.albumImage = track.albumImage
        currentTrack.albumLoaded = track.albumLoaded
        
        albumImageView.image = currentTrack.albumImage
        
        view.setNeedsDisplay()
    }
    
    private func isPlayingDidChange(_ isPlaying: Bool) {
        playButton.isSelected = isPlaying
        
    }
    
    func playbackStateDidChange(_ playbackState: RadioPlaybackState, animate: Bool) {
        
        let message: String?
        
        switch playbackState {
        case .paused:
            message = "Station Paused..."
        case .playing:
            message = nil
        case .stopped:
            message = "Station Stopped..."
        }
        
        updateLabels(with: message, animate: animate)
        isPlayingDidChange(radioPlayer.isPlaying)
    }
    
    func playerStateDidChange(_ state: RadioPlayerState, animate: Bool) {
        
        let message: String?
        
        switch state {
        case .loading:
            message = "Loading Station ..."
        case .urlNotSet:
            message = "Station URL not valide"
        case .readyToPlay, .loadingFinished:
            playbackStateDidChange(radioPlayer.playbackState, animate: animate)
            return
        case .error:
            message = "Error Playing"
        }
        
        updateLabels(with: message, animate: animate)
    }
    
    func updateLabels(with statusMessage: String? = nil, animate: Bool = true) {
        
        guard let statusMessage = statusMessage else {
            
            songLabel.text = currentTrack.title
            artistLabel.text = currentTrack.artist
            return
        }
        guard songLabel.text != statusMessage else { return }
        
        songLabel.text = statusMessage
        artistLabel.text = currentStation.name
        
    }
}



