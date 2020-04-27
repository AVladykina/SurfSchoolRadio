//
//  AppDelegate.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/15/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    
    weak var stationsViewController: StationListViewController?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UIApplication.shared.beginReceivingRemoteControlEvents()
        
        RadioPlayer.shared.isAutoPlay = true
        RadioPlayer.shared.enableAlbum = true
        RadioPlayer.shared.albumSize = 600
        

        if let navigationController = window?.rootViewController as? UINavigationController {
            stationsViewController = navigationController.viewControllers.first as? StationListViewController
        }
        
        return true
    }
}
