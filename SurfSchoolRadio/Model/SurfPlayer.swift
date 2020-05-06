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
    func trackAlbumDidUpdate(_ track: Track?)
}

class SurfPlayer {
    
    weak var delegate: SurfPlayerDelegate?
    
    let surfPlayer = RadioPlayer.shared
    
    var station: RadioStation? {
        didSet { resetTrack(with: station) }
    }
    
    private(set) var track: Track?
    
    init() {
        surfPlayer.delegate = self as? RadioPlayerDelegate
    }
    
    func resetRadioPlayer() {
        station = nil
        track = nil
        surfPlayer.radioURL = nil
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
    
    
    func updateTrackAlbum(with image: UIImage, albumLoaded: Bool) {
        track?.albumImage = image
        track?.albumLoaded = albumLoaded
        delegate?.trackAlbumDidUpdate(track)
    }
    
    
    func resetTrack(with station: RadioStation?) {
        guard let station = station else { track = nil; return }
        updateTrackMetadata(artistName: station.desc, trackName: station.name)
        resetAlbum(with: station)
    }
    
    
    func resetAlbum(with station: RadioStation?) {
        guard let station = station else { track = nil; return }
        getStationImage(from: station) { image in
            self.updateTrackAlbum(with: image, albumLoaded: false)
        }
    }
    
    
    private func getStationImage(from station: RadioStation, completionHandler: @escaping (_ image: UIImage) -> ()) {
        
        if station.imageURL.range(of: "http") != nil {
            
            downloadImage( station.imageURL) { (image, stringURL) in
                completionHandler(image ?? #imageLiteral(resourceName: "albumArt"))
            }
            
        } else {
            
            let image = UIImage(named: station.imageURL) ?? #imageLiteral(resourceName: "albumArt")
            completionHandler(image)
        }
    }
    
    
    func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
        URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
    }
    
    func downloadImage(_ urlString: String, completionHandler: @escaping(_ image: UIImage?, _ url: String) -> ()) {
        let fileUrl = URL(string: urlString)
        getData(from: fileUrl!) { data, response, error in
            guard let data = data, error == nil else { return }
            print(response?.suggestedFilename ?? fileUrl!.lastPathComponent)
            DispatchQueue.main.async() {
                self.track?.albumImage = UIImage(data: data)
            }
        }
    }
}



