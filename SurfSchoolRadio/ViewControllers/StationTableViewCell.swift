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

    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
        
        let selectedView = UIView(frame: CGRect.zero)
        selectedView.backgroundColor = UIColor(red: 78/255, green: 82/255, blue: 93/255, alpha: 0.6)
        selectedBackgroundView  = selectedView
    }

    func configureStationCell (station: RadioStation) {

        stationNameLabel.text = station.name
        stationDescLabel.text = station.desc

//        DispatchQueue.main.async {
//            if let url = URL(string: station.imageURL) {
//                if let data = try? Data(contentsOf: url) {
//                    self.stationImageView.image = UIImage(data: data)
//
//                }
//            }
//        }
        let imageURL = station.imageURL as NSString
        if imageURL.contains("http"), let url = URL(string: station.imageURL) {
            stationImageView.loadImageWithURL(url: url) { (image) in
            }
        } else if imageURL != "" {
            stationImageView.image = UIImage(named: imageURL as String)
        } else {
            stationImageView.image = UIImage(named: "stationImage")
        }
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

extension UIImageView {

    func loadImageWithURL(url: URL, callback: @escaping (UIImage) -> ()) {
        let session = URLSession.shared

        let downloadTask = session.downloadTask(with: url, completionHandler: {
            [weak self] url, response, error in

            if error == nil && url != nil {
                if let data = NSData(contentsOf: url!) {
                    if let image = UIImage(data: data as Data) {

                        DispatchQueue.main.async(execute: {

                            if let strongSelf = self {
                                strongSelf.image = image
                                callback(image)
                            }
                        })
                    }
                }
            }
        })

        downloadTask.resume()
    }
}
