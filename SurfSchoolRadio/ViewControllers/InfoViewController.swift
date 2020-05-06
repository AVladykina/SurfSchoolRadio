//
//  InfoViewController.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 5/6/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var longDescTextView: UITextView!

    var currentStation: RadioStation!
    var downloadTask: URLSessionDownloadTask?

    override func viewDidLoad() {
        super.viewDidLoad()

        setupStationText()
        setupStationLogo()
    }

    deinit {
        downloadTask?.cancel()
        downloadTask = nil
    }

    func setupStationText() {
        nameLabel.text = currentStation.name
        descLabel.text = currentStation.desc
        nameLabel.attributedText = NSAttributedString()
        longDescTextView.text = currentStation.longDesc
    }


    func setupStationLogo() {
        let imageURL = currentStation.imageURL

        if imageURL.range(of: "http") != nil {
            if let url = URL(string: currentStation.imageURL) {
                imageView.loadImageWithURL(url: url) { _ in }
            }
        } else if imageURL != "" {
            imageView.image = UIImage(named: imageURL)
        } else {
            imageView.image = UIImage(named: "stationImage")
        }
    }
}

