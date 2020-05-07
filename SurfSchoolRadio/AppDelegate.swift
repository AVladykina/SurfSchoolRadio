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

        if let navigationController = window?.rootViewController as? UINavigationController {
            stationsViewController = navigationController.viewControllers.first as? StationListViewController
        }

        return true
    }


    func applicationWillTerminate(_ application: UIApplication) {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.

    UIApplication.shared.endReceivingRemoteControlEvents()

    }
}
