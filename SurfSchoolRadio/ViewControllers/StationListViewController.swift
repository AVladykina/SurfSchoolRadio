//
//  StationListViewController.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/20/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit
import AVFoundation

class StationListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    weak var nowPlayingViewController: NowPlayingViewController?
   
    let surfPlayer = SurfPlayer()
    
    var stations = [RadioStation]() {
        didSet {
            guard stations != oldValue else { return }
            stationsDidUpdate()
        }
    }
    
    var searchedStations = [RadioStation]()
    
    var previousStation: RadioStation?
    
    
    var searchController: UISearchController = {
        return UISearchController(searchResultsController: nil)
    }()
    
    var refreshControl: UIRefreshControl = {
        return UIRefreshControl()
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cellNib = UINib(nibName: "NothingFoundCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "NothingFound")
        
        surfPlayer.delegate = self as? SurfPlayerDelegate
        
        
        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none
        
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
             print("audioSession could not be activated") 
        }
        
        setupSearchController()
        
        tableView.dataSource = self
       
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Surf Radio"
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "NowPlaying", let nowPlayingVC = segue.destination as? NowPlayingViewController else { return }
    
        title = ""
        
        let newStation: Bool
        
        if let indexPath = (sender as? IndexPath) {
            surfPlayer.station = searchController.isActive ? searchedStations[indexPath.row] : stations[indexPath.row]
            newStation = surfPlayer.station != previousStation
            previousStation = surfPlayer.station
        } else {
            
            newStation = false
        }
        
        nowPlayingViewController = nowPlayingVC
        nowPlayingVC.load(station: surfPlayer.station, track: surfPlayer.track, isNewStation: newStation)
        nowPlayingVC.delegate = self as? NowPlayingViewControllerDelegate
    }
    
    private func stationsDidUpdate() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            guard let currentStation = self.surfPlayer.station else { return }
    
            if self.stations.firstIndex(of: currentStation) == nil { self.resetCurrentStation() }
        }
    }
    
    private func resetCurrentStation() {
        surfPlayer.resetRadioPlayer()
        navigationItem.rightBarButtonItem = nil
    }
    

}


extension StationListViewController: UITableViewDataSource {
    
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if searchController.isActive {
            return searchedStations.count
        } else {
            return stations.isEmpty ? 1 : stations.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if stations.isEmpty {
            let cell = tableView.dequeueReusableCell(withIdentifier: "NothingFound", for: indexPath)
            cell.backgroundColor = .clear
            cell.selectionStyle = .none
            return cell
            
        } else {
    
            let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationTableViewCell2
        
        
            let station = searchController.isActive ? searchedStations[indexPath.row] : stations[indexPath.row]
            cell.configureStationCell(station: station)
            
            return cell
        }
    }
    
}

extension StationListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        performSegue(withIdentifier: "NowPlaying", sender: indexPath)
    }
}


extension StationListViewController: UISearchResultsUpdating {
    
    
    func setupSearchController() {
        guard searchable else { return }
        
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()
        
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableHeaderView?.backgroundColor = UIColor.clear
        definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = false
        
        searchController.searchBar.barTintColor = UIColor.clear
        searchController.searchBar.tintColor = UIColor.white
        
        
        tableView.setContentOffset(CGPoint(x: 0.0, y: searchController.searchBar.frame.size.height), animated: false)
        
            let searchTextField = searchController.searchBar.value(forKey: "_searchField") as? UITextField
            searchTextField?.keyboardAppearance = .dark
        }
    
    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }
        
        searchedStations.removeAll(keepingCapacity: false)
        searchedStations = stations.filter { $0.name.range(of: searchText, options: [.caseInsensitive]) != nil }
        self.tableView.reloadData()
    }
}






