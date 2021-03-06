//
//  StationListViewController.swift
//  SurfSchoolRadio
//
//  Created by Nastya on 4/20/20.
//  Copyright © 2020 Surf. All rights reserved.
//

import UIKit
import MediaPlayer
import AVFoundation

class StationListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var playButton: UIButton!

    @IBOutlet weak var stopButton: UIButton!

    let radioPlayer = SurfPlayer()

    weak var nowPlayingViewController: NowPlayingViewController?

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

        let cellNib = UINib(nibName: "StationTableViewCell", bundle: nil)
        tableView.register(cellNib, forCellReuseIdentifier: "StationCell")

        radioPlayer.delegate = self

        loadStationsFromJSON()

        tableView.backgroundColor = .clear
        tableView.backgroundView = nil
        tableView.separatorStyle = .none

        setupPullToRefresh()

        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("audioSession could not be activated")
        }

        setupSearchController()
        setupRemoteCommandCenter()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        title = "Surf Radio"
    }

    @IBAction func playPressed(_ sender: Any) {
        radioPlayer.player.togglePlaying()
    }
    
    @IBAction func stoppPressed(_ sender: Any) {
        radioPlayer.player.stop()
    }
    
    func setupPullToRefresh() {
        refreshControl.backgroundColor = .black
        refreshControl.tintColor = .white
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }

    @objc func refresh(sender: AnyObject) {
        loadStationsFromJSON()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.refreshControl.endRefreshing()
            self.view.setNeedsDisplay()
        }
    }

    func loadStationsFromJSON() {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        DataManager.getStationDataWithSuccess() { (data) in
            defer {
                DispatchQueue.main.async { UIApplication.shared.isNetworkActivityIndicatorVisible = false }
            }
            guard let data = data, let jsonDictionary = try? JSONDecoder().decode([String: [RadioStation]].self, from: data), let stationsArray = jsonDictionary["station"] else {
                return
            }
            self.stations = stationsArray
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "NowPlaying", let nowPlayingVC = segue.destination as? NowPlayingViewController else { return }

        title = ""

        let newStation: Bool

        if let indexPath = (sender as? IndexPath) {
            radioPlayer.station = searchController.isActive ? searchedStations[indexPath.row] : stations[indexPath.row]
            newStation = radioPlayer.station != previousStation
            previousStation = radioPlayer.station
        } else {
            newStation = false
        }

        nowPlayingViewController = nowPlayingVC
        nowPlayingVC.load(station: radioPlayer.station, track: radioPlayer.track, isNewStation: newStation)
        nowPlayingVC.delegate = self
    }

    private func stationsDidUpdate() {
        DispatchQueue.main.async {
            self.tableView.reloadData()
            guard let currentStation = self.radioPlayer.station else { return }
            if self.stations.firstIndex(of: currentStation) == nil { self.resetCurrentStation() }
        }
    }

    private func resetCurrentStation() {
        radioPlayer.resetRadioPlayer()
        navigationItem.rightBarButtonItem = nil
    }

    private func getIndex(of station: RadioStation?) -> Int? {
        guard let station = station, let index = stations.firstIndex(of: station) else { return nil }
        return index
    }

    func setupRemoteCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()
        commandCenter.playCommand.addTarget { event in
            return .success
        }
        commandCenter.pauseCommand.addTarget { event in
            return .success
        }
        commandCenter.nextTrackCommand.addTarget { event in
            return .success
        }
        commandCenter.previousTrackCommand.addTarget { event in
            return .success
        }
    }
}

extension StationListViewController: UITableViewDataSource {
    @objc(tableView:heightForRowAtIndexPath:)
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 90.0
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
            let cell = tableView.dequeueReusableCell(withIdentifier: "StationCell", for: indexPath) as! StationTableViewCell

            cell.backgroundColor = UIColor.clear

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
        searchController.searchResultsUpdater = self
        searchController.dimsBackgroundDuringPresentation = false
        searchController.searchBar.sizeToFit()

        tableView.tableHeaderView = searchController.searchBar
        tableView.tableHeaderView?.backgroundColor = UIColor.clear
        definesPresentationContext = true
        searchController.hidesNavigationBarDuringPresentation = false

        searchController.searchBar.barTintColor = UIColor.clear
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let searchText = searchController.searchBar.text else { return }

        searchedStations.removeAll(keepingCapacity: false)
        searchedStations = stations.filter { $0.name.range(of: searchText, options: [.caseInsensitive]) != nil }
        self.tableView.reloadData()
    }
}

extension StationListViewController: SurfPlayerDelegate {

    func playerStateDidChange(_ playerState: RadioPlayerState) {
        nowPlayingViewController?.playerStateDidChange(playerState, animate: true)
    }

    func playbackStateDidChange(_ playbackState: RadioPlaybackState) {
        nowPlayingViewController?.playbackStateDidChange(playbackState, animate: true)
    }

    func trackDidUpdate(_ track: Track?) {
        nowPlayingViewController?.updateTrackMetadata(with: track)
    }

    func trackArtworkDidUpdate(_ track: Track?) {
        nowPlayingViewController?.updateTrackArtwork(with: track)
    }
}

extension StationListViewController: NowPlayingViewControllerDelegate {

    func didPressPlayingButton() {
        radioPlayer.player.togglePlaying()
    }

    func didPressStopButton() {
        radioPlayer.player.stop()
    }

    func didPressNextButton() {
        guard let index = getIndex(of: radioPlayer.station) else { return }
        radioPlayer.station = (index + 1 == stations.count) ? stations[0] : stations[index + 1]
        handleRemoteStationChange()
    }

    func didPressPreviousButton() {
        guard let index = getIndex(of: radioPlayer.station) else { return }
        radioPlayer.station = (index == 0) ? stations.last : stations[index - 1]
        handleRemoteStationChange()
    }

    func handleRemoteStationChange() {
        if let nowPlayingVC = nowPlayingViewController {
            nowPlayingVC.load(station: radioPlayer.station, track: radioPlayer.track)
            nowPlayingVC.stationDidChange()
        } else if let station = radioPlayer.station {
            radioPlayer.player.radioURL = URL(string: station.streamURL)
        }
    }
}
