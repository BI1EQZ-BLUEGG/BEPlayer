//
//  ViewController.swift
//  BEPlayerExamples
//
//  Created by bluegg on 2024/12/5.
//

import UIKit
import BELoader

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    @IBAction func push(_ sender: Any) {
        navigationController?.pushViewController(BEPlayerViewController(), animated: true) 
    }
    
    @IBAction func preloadAction(_ sender: UIButton) {
        BEResourceManager.share().preload(mediaURLs.first!)
    }
}

