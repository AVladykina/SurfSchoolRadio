//
//  SurfPlayer.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/24/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

protocol SurfPlayerDelegate: class {
    func playerStateDidChange(_ playerState: RadioPlayerState)
    func playbackStateDidChange(_ playbackState: RadioPlaybackState)
    func trackDidUpdate(_ track: Track?)
    func trackArtworkDidUpdate(_ track: Track?)
}

class SurfPlayer {

    weak var delegate: SurfPlayerDelegate?

    let player = RadioPlayer.shared

    var station: RadioStation? {
        didSet { resetTrack(with: station) }
    }

    private(set) var track: Track?

    init() {
        player.delegate = self
    }

    func resetRadioPlayer() {
        station = nil
        track = nil
        player.radioURL = nil
    }

    func updateTrackMetadata(artistName: String, trackName: String) {
        if track == nil {
            track = Track(title: trackName, artist: artistName)
        } else {
            track?.title = trackName
            track?.artist = artistName
        }

        delegate?.trackDidUpdate(track)
    }

    func updateTrackArtwork(with image: UIImage, artworkLoaded: Bool) {
        track?.albumImage = image
        track?.albumLoaded = artworkLoaded
        delegate?.trackArtworkDidUpdate(track)
    }

    func resetTrack(with station: RadioStation?) {
        guard let station = station else { track = nil; return }
        updateTrackMetadata(artistName: station.desc, trackName: station.name)
        resetArtwork(with: station)
    }

    func resetArtwork(with station: RadioStation?) {
        guard let station = station else { track = nil; return }
        getStationImage(from: station) { image in
            self.updateTrackArtwork(with: image, artworkLoaded: false)
        }
    }

    private func getStationImage(from station: RadioStation, completionHandler: @escaping (_ image: UIImage) -> ()) {

        if station.imageURL.range(of: "http") != nil {
            ImageLoader.sharedLoader.imageForUrl(urlString: station.imageURL) { (image, stringURL) in
                completionHandler(image ?? #imageLiteral(resourceName: "albumArt"))
            }
        } else {
            let image = UIImage(named: station.imageURL) ?? #imageLiteral(resourceName: "albumArt")
            completionHandler(image)
        }
    }
}

extension SurfPlayer: RadioPlayerDelegate {

    func radioPlayer(_ player: RadioPlayer, playerStateDidChange state: RadioPlayerState) {
        delegate?.playerStateDidChange(state)
    }

    func radioPlayer(_ player: RadioPlayer, playbackStateDidChange state: RadioPlaybackState) {
        delegate?.playbackStateDidChange(state)
    }

    func radioPlayer(_ player: RadioPlayer, metadataDidChange artistName: String?, trackName: String?) {
        guard
            let artistName = artistName, !artistName.isEmpty,
            let trackName = trackName, !trackName.isEmpty else {
                resetTrack(with: station)
                return
        }

        updateTrackMetadata(artistName: artistName, trackName: trackName)
    }

    func radioPlayer(_ player: RadioPlayer, artworkDidChange artworkURL: URL?) {
        guard let artworkURL = artworkURL else { resetArtwork(with: station); return }

        ImageLoader.sharedLoader.imageForUrl(urlString: artworkURL.absoluteString) { (image, stringURL) in
            guard let image = image else { self.resetArtwork(with: self.station); return }
            self.updateTrackArtwork(with: image, artworkLoaded: true)
        }
    }
}

