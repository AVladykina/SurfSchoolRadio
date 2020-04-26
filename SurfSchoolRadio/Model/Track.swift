//
//  Track.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/22/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

struct Track {
    var title: String
    var artist: String
    var albumImage: UIImage?
    var albumLoaded = false
    
    init(title: String, artist: String) {
        self.title = title
        self.artist = artist
    }
}
