//
//  LastfmAPI.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/30/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import Foundation

public class LastfmAPI {

    static public let shared = LastfmAPI()

    private init(){}

    public enum LastfmAPIError :Error, LocalizedError {
        case parse
        case urlCreation
        case radioStream

        public var errorDescription: String?{
            switch self {
            case .parse:
                return "JSON Parsing error"
            case .urlCreation:
                return "URL creating error"
            case .radioStream:
                return "Radio streaming error"
            }
        }
    }

    enum LastFMLoginError: Error {
        case loginError
    }

    public enum APIMethods {
        enum Radio : String {
            case radioTune = "radio.tune"
        }
        enum Album : String {
            case getInfo = "album.getInfo"
            case search = "album.search"
        }

        enum Track : String {
            case getInfo = "track.getInfo"
            case search = "track.search"
            case updateNowPlaying = "track.updateNowPlaying"
        }

        enum Artist : String {
            case getInfo = "artist.getInfo"
            case getTopAlbums = "artist.getTopAlbums"
            case getTopTracks = "artist.getTopTracks"
            case search = "artist.search"
        }


        enum Auth : String {
            case getMobileSession = "auth.getMobileSession"
            case getSession = "auth.getSession"
            case getToken = "auth.getToken"
        }
    }



    func createURL(with queryItems:URLQueryItem?...) throws ->(URL) {
        var _queryItems: [URLQueryItem] = []
        for item in queryItems {
            if let item = item {
                _queryItems.append(item)
            }
        }
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = NetworkConstants.baseURL
        let apiKeyQuery = URLQueryItem(name: "api_key", value: NetworkConstants.apiKey)
        let formatQuery = URLQueryItem(name: "format", value: "json")
        _queryItems.append(apiKeyQuery)
        _queryItems.sort{ $0.name < $1.name}
        _queryItems.append(formatQuery)
        urlComponents.queryItems = _queryItems
        guard let url = urlComponents.url else {throw LastfmAPIError.urlCreation}
        return url
    }

    public static func auth(completion: @escaping ((username:String,key:String)?)->()) {

        let apiSig = NetworkConstants.apiSig

        let methodQuery = URLQueryItem(name: "method", value: LastfmAPI.APIMethods.Auth.getMobileSession.rawValue)
        let usernameQuery = URLQueryItem(name: "username", value: NetworkConstants.userName)
        let passwordQuery = URLQueryItem(name: "password", value: NetworkConstants.password)
        let apiSigQuery = URLQueryItem(name: "api_sig", value: apiSig)

        guard let url = try? LastfmAPI.shared.createURL(with: methodQuery, usernameQuery, passwordQuery, apiSigQuery) else {completion(nil);return}
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            do{
                guard error == nil else {throw error!}
                guard let data = data else {throw LastFMLoginError.loginError}
                guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastFMLoginError.loginError}
                guard let session = json["session"] as? [String:AnyObject] else {throw LastFMLoginError.loginError}
                guard let key = session["key"] as? String else {throw LastFMLoginError.loginError}
                guard let name = session["name"] as? String else {throw LastFMLoginError.loginError}
                completion((name, key))
            } catch let error {
                print(error.localizedDescription)
                completion(nil)
            }
            }.resume()
    }



    func getModel<T:Decodable>(_ t:T.Type, url:URL, path:[String]?, arrayName:String?, completion:@escaping (T?, Error?)->()) {
        URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
            do{
                if let error = error{
                    throw error
                }
                guard let data = data else {throw LastfmAPIError.parse}
                guard var json = try! JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] else {throw LastfmAPIError.parse}

                if (json["error"] as? Int) != nil{
                    let error: Error = LastfmAPIError.parse
                    throw error
                }

                try? path?.forEach{
                    guard let underRoot = json[$0] as? [String:AnyObject] else {throw LastfmAPIError.parse}
                    json = underRoot
                }

                let array: [[String:AnyObject]]?
                if let arrayName = arrayName{
                    array = json[arrayName] as? [[String:AnyObject]]
                } else {array = nil}

                let cleanJSON = try JSONSerialization.data(withJSONObject: array ?? json, options: [])

                let result = try JSONDecoder().decode(T.self, from: cleanJSON)
                completion(result, nil)
            } catch let error{
                completion(nil, error)
            }
        }).resume()
    }
}
