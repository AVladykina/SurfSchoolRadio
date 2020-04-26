//
//  RadioStation.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/18/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

struct RadioStation: Codable {
    
    var name: String
    var streamURL: String
    var imageURL: String
    var desc: String
    var longDesc: String
    
    init(dictionary: Dictionary <String, Any>) {
        self.name = dictionary["name"] as? String ?? ""
        self.streamURL = dictionary["streamURL"] as? String ?? ""
        self.imageURL = dictionary["imageURL"] as? String ?? ""
        self.desc = dictionary["desc"] as? String ?? ""
        self.longDesc = dictionary["longDesc"] as? String ?? ""
    }
    
}

extension RadioStation: Equatable {
    
    static func == (lhs: RadioStation, rhs: RadioStation) -> Bool {
        return (lhs.name == rhs.name) && (lhs.streamURL == rhs.streamURL) && (lhs.imageURL == rhs.imageURL) && (lhs.desc == rhs.desc) && (lhs.longDesc == rhs.longDesc)
    }
}

