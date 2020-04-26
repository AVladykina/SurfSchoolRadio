//
//  DataManager.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/26/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

struct DataManager {
    
    
    static func getStationDataWithSuccess(success: @escaping ((_ metaData: Data?) -> Void)) {
        
        DispatchQueue.global(qos: .userInitiated).async {

                guard let stationDataURL = URL(string: NetworkConstants.baseURL) else {
                     print("stationDataURL not a valid URL")
                    success(nil)
                    return
                }
                
                loadDataFromURL(url: stationDataURL) { data, error in
                    success(data)
                }
        }
    }
    
    
    static func loadDataFromURL(url: URL, completion: @escaping (_ data: Data?, _ error: Error?) -> Void) {
        
        let sessionConfig = URLSessionConfiguration.default
        sessionConfig.allowsCellularAccess = true
        sessionConfig.timeoutIntervalForRequest = 15
        sessionConfig.timeoutIntervalForResource = 30
        sessionConfig.httpMaximumConnectionsPerHost = 1
        
        let session = URLSession(configuration: sessionConfig)
        
    
        let loadDataTask = session.dataTask(with: url) { data, response, error in
            
            guard error == nil else {
                completion(nil, error!)
                print("API ERROR: \(error!)")
                return
            }
            
            guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
                completion(nil, nil)
                 print("API: HTTP status code has unexpected value")
                return
            }
            
            guard let data = data else {
                completion(nil, nil)
                print("API: No data received")
                return
            }
            
            completion(data, nil)
        }
        
        loadDataTask.resume()
    }
}
