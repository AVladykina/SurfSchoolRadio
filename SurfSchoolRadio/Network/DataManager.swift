//
//  DataManager.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 5/4/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit

struct DataManager {


    // Helper struct to get local JSON

    static func getStationDataWithSuccess(success: @escaping ((_ metaData: Data?) -> Void)) {

        DispatchQueue.global(qos: .userInitiated).async {
                getDataFromFileWithSuccess() { data in
                    success(data)
                }
            }
    }

    // Load local JSON Data

    static func getDataFromFileWithSuccess(success: (_ data: Data?) -> Void) {
        guard let filePathURL = Bundle.main.url(forResource: "stations", withExtension: "json") else {
            print("The local JSON file could not be found")
            success(nil)
            return
        }

        do {
            let data = try Data(contentsOf: filePathURL, options: .uncached)
            success(data)
        } catch {
            fatalError()
        }
    }
}

