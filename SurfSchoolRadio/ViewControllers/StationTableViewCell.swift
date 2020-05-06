//
//  StationTableViewCell.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/22/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

class StationTableViewCell: UITableViewCell {

    @IBOutlet weak var stationImageView: UIImageView!
    
    @IBOutlet weak var stationNameLabel: UILabel!
    @IBOutlet weak var stationDescLabel: UILabel!
    
    var downloadTask: URLSessionDownloadTask?
    
        func configureStationCell (station: RadioStation) {
    
            stationNameLabel.text = station.name
            stationDescLabel.text = station.desc

            DispatchQueue.main.async {
                if let url = URL(string: station.imageURL) {
                    if let data = try? Data(contentsOf: url) {
                        self.stationImageView.image = UIImage(data: data)
    
                    }
                }
            }
        }

    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 78/255, green: 82/255, blue: 93/255, alpha: 0.6)
        selectedBackgroundView  = selectedView
        
        stationImageView.image = UIImage(named: "stationImage")
        stationNameLabel.text = "Station name"
        stationDescLabel.text = "Station Desc"
        stationImageView.contentMode = .scaleAspectFill
        stationImageView.clipsToBounds = true
        
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        downloadTask?.cancel()
        downloadTask = nil
        stationNameLabel.text  = nil
        stationDescLabel.text  = nil
        stationImageView.image = nil
    }
    
    
}
