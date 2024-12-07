//
//  BEPlayerViewController.swift
//  BEPlayerExamples
//
//  Created by bluegg on 2024/12/5.
//

import UIKit
import BEPlayer
import BELoader

class BEPlayerViewController: UIViewController {
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @IBOutlet weak var labelTime: UILabel!
    
    @IBOutlet weak var labelDuration: UILabel!
    
    
    @IBOutlet weak var indicatorLoading: UIActivityIndicatorView!
    
    @IBOutlet weak var sliderProgress: UISlider!
    
    @IBOutlet weak var viewBoarder: UIView!
    
    @IBOutlet weak var buttonPrevious: UIButton!
    
    @IBOutlet weak var buttonPlayPause: UIButton!
    
    @IBOutlet weak var buttonNext: UIButton!
    
    
    @IBOutlet weak var buttonRetry: UIButton!
    
    
    let player: BEPlayer
    
    var album: [BEPlayerItem] = []
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        player = BEPlayer()
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
    
    
    func setupView() {
        buttonPlayPause.setImage(.init(systemName: "play"), for: .normal)
        buttonPlayPause.setImage(.init(systemName: "pause"), for: .selected)
    }

    func setup() {
        
        let album = mediaURLs.compactMap({BEPlayerItem(url: URL(string: $0)!, title: $0.components(separatedBy: "/").last ?? "-")})
        
        player.updateAlbume(album, playAt: 0)
        
        viewBoarder.addSubview(player.playerView)
        let _ = NSLayoutConstraint(item: player.playerView, attribute: .leading, relatedBy: .equal, toItem: viewBoarder, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        let _ = NSLayoutConstraint(item: player.playerView, attribute: .top, relatedBy: .equal, toItem: viewBoarder, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        let _ = NSLayoutConstraint(item: player.playerView, attribute: .trailing, relatedBy: .equal, toItem: viewBoarder, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        let _ = NSLayoutConstraint(item: player.playerView, attribute: .bottom, relatedBy: .equal, toItem: viewBoarder, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        
        player.resourceLoader = BEResourceLoader()
        player.delegate = self
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
            sliderProgress.maximumValue = Float(CMTimeGetSeconds(player.duration))
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
            break
            
        case .error:
            
            indicatorLoading.stopAnimating()
            buttonRetry.isHidden = false
        default:
            break
        }
    }
    
    func player(_ player: BEPlayer, progress seconds: Float64) {
        if sliderProgress.tag == 0 {
            sliderProgress.value = Float(seconds)
            labelTime.text = "\(seconds.toHMSTime)"
        }
    }
    
    func player(_ player: BEPlayer, didPlayAt index: Int) {
        sliderProgress.value = 0
        print(#function, index)
    }
    
}
