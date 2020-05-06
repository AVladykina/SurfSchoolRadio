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

func login() {

    let method = "auth.getMobileSession"

    let urlParameter = "method=\(method)&api_key=" + NetworkConstants.apiKey + "&password=" + NetworkConstants.password + "&username=" + NetworkConstants.userName + "&api_sig=" + NetworkConstants.apiSig
    print("urlParameter = \(urlParameter)")
    let fullURL = "\(NetworkConstants.baseURL)\(urlParameter)"

    let session = URLSession.shared

    var request = URLRequest(url: URL(string: fullURL)!)

    request.httpMethod = "POST"

    let task = session.dataTask(with: request) { (data, response, error) in

        do {

            print(String(data: data!, encoding: String.Encoding.utf8)!)


        }
    }

    task.resume()

}
