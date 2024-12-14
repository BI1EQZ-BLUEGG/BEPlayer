//
//  BEPlayerViewController.swift
//  BEPlayerExamples
//
//  Created by bluegg on 2024/12/5.
//

import BELoader
import BEPlayRC
import BEPlayer
import UIKit
import AVFoundation

class BEPlayerViewController: UIViewController {

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var labelProgress: UILabel!
    
    @IBOutlet weak var labelTime: UILabel!

    @IBOutlet weak var labelDuration: UILabel!

    @IBOutlet weak var indicatorLoading: UIActivityIndicatorView!

    @IBOutlet weak var sliderProgress: UISlider!

    @IBOutlet weak var viewBoarder: UIView!

    @IBOutlet weak var buttonPrevious: UIButton!

    @IBOutlet weak var buttonPlayPause: UIButton!

    @IBOutlet weak var buttonNext: UIButton!

    @IBOutlet weak var buttonRetry: UIButton!

    @IBOutlet weak var segmentRate: UISegmentedControl!

    @IBOutlet weak var segmentMode: UISegmentedControl!

    lazy var player: BEPlayer = {
        let p = BEPlayer()
        p.delegate = self
        p.resourceLoader = BEResourceLoader()
        return p
    }()

    var album: [BEPlayerItem] = []

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?)
    {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setup()
    }

    @IBAction func onSliderTouchDown(_ sender: UISlider) {
        sender.tag = -1
    }

    @IBAction func onSliderValueChanged(_ sender: UISlider) {
        labelTime.text = Double(sender.value).toHMSTime
    }

    @IBAction func onSliderTouchUpInside(_ sender: UISlider) {
        player.seek(to: Float64(sender.value))
        sender.tag = 0
    }

    @IBAction func onSliderTouchUpOutside(_ sender: UISlider) {
        onSliderTouchUpInside(sender)
    }

    @IBAction func onRetryAction(_ sender: UIButton) {
        player.play()
    }

    @IBAction func cleanCache(_ sender: UIButton) {
        sender.isEnabled = false
        BEResourceManager.share().cleanAll {
            DispatchQueue.main.async {
                sender.isEnabled = true
            }
        }
    }

    @IBAction func onEnableLockScreenChange(_ sender: UISwitch) {
        BEPlayRemoteCommand.shared.isEnabled = sender.isOn
        if sender.isOn {
            BEPlayRemoteCommand.shared.onCommand = { [weak self] cmd in
                guard let self else { return }
                switch cmd {
                case .play: self.player.play()
                case .pause: self.player.pause()
                case .togglePlayPause:
                    if self.player.status == .playing {
                        self.player.play()
                    } else {
                        self.player.pause()
                    }
                case .next: self.player.playNext()
                case .previous: self.player.playPrevious()
                case .like: break
                case .mark: break
                }
            }
        }
    }

    @IBAction func onPlayModeChange(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            player.playMode = .listOnce
        case 1:
            player.playMode = .listRepeat
        case 2:
            player.playMode = .repeat
        case 3:
            player.playMode = .once
        case 4:
            player.playMode = .shuffle
        default:
            break
        }
    }

    @IBAction func onPlayRateChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            player.rate = 0.5
        case 1:
            player.rate = 0.75
        case 2:
            player.rate = 1.0
        case 3:
            player.rate = 1.5
        case 4:
            player.rate = 1.75
        case 5:
            player.rate = 2.0
        default:
            player.rate = 1.0
        }
    }

    func setupView() {
        buttonPlayPause.setImage(.init(systemName: "play"), for: .normal)
        buttonPlayPause.setImage(.init(systemName: "pause"), for: .selected)

        segmentMode.selectedSegmentIndex = 0
        segmentRate.selectedSegmentIndex = 2
    }

    func setup() {
        
        let album = mediaURLs.compactMap({
            BEPlayerItem(
                url: URL(string: $0)!,
                title: $0.components(separatedBy: "/").last ?? "-")
        })
        
        player.playMode = .listOnce
        player.updateAlbum(album, playAt: 0)
        if let view = player.playerView {
            viewBoarder.addSubview(view)
            let _ =
                NSLayoutConstraint(
                    item: view, attribute: .leading, relatedBy: .equal,
                    toItem: viewBoarder, attribute: .leading, multiplier: 1.0,
                    constant: 0
                ).isActive = true
            let _ =
                NSLayoutConstraint(
                    item: player.playerView, attribute: .top, relatedBy: .equal,
                    toItem: viewBoarder, attribute: .top, multiplier: 1.0,
                    constant: 0
                ).isActive = true
            let _ =
                NSLayoutConstraint(
                    item: player.playerView, attribute: .trailing,
                    relatedBy: .equal, toItem: viewBoarder, attribute: .trailing,
                    multiplier: 1.0, constant: 0
                ).isActive = true
            let _ =
                NSLayoutConstraint(
                    item: player.playerView, attribute: .bottom, relatedBy: .equal,
                    toItem: viewBoarder, attribute: .bottom, multiplier: 1.0,
                    constant: 0
                ).isActive = true
        }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
    }

    @IBAction func nextAction(_ sender: UIButton) {
        player.playNext()
    }

    @IBAction func playOrPauseActoin(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if buttonPlayPause.isSelected {
            player.play()
        } else {
            player.pause()
        }
    }

    @IBAction func previousAction(_ sender: UIButton) {
        player.playPrevious()
    }
}

extension BEPlayerViewController: BEPlayerDelegate {

    func player(_ player: BEPlayer, status: BEPlayerStatus) {
        print(#function, status.rawValue)
        switch status {
        case .unknow:

            indicatorLoading.startAnimating()
        case .ready:

            sliderProgress.minimumValue = 0
            sliderProgress.maximumValue = Float(
                CMTimeGetSeconds(player.duration))
            labelTime.text = "00:00"
            labelDuration.text = CMTimeGetSeconds(player.duration).toHMSTime

        case .loading:
            indicatorLoading.isHidden = false
            indicatorLoading.startAnimating()
            buttonPlayPause.isSelected = false
        case .paused:

            buttonPlayPause.isSelected = false
        case .playing:

            indicatorLoading.stopAnimating()
            indicatorLoading.isHidden = true
            buttonPlayPause.isSelected = true
        case .finished:
            BEPlayRemoteCommand.shared.clean()
        case .error:

            indicatorLoading.stopAnimating()
            buttonRetry.isHidden = false
            print(player.error!)
        default:
            break
        }
    }

    func player(_ player: BEPlayer, progress seconds: Float64) {
        if sliderProgress.tag == 0 {
            sliderProgress.value = Float(seconds)
            labelTime.text = "\(seconds.toHMSTime)"
        }
        
        BEPlayRemoteCommand.shared.update(
            title: "title \(seconds.toHMSTime)",
            artist: "artist",
            albumTitle: "album title",
            time: TimeInterval(seconds),
            duration: player.duration.seconds,
            image: UIImage(named: "cover")
        )
    }

    func player(_ player: BEPlayer, didPlayAt index: Int) {
        sliderProgress.value = 0
        BEPlayRemoteCommand.shared.clean()
        BEPlayRemoteCommand.shared.update(title: "第\(index)首")
        
        labelProgress.text = "\(index + 1)/\(player.album.count)"
    }
}
