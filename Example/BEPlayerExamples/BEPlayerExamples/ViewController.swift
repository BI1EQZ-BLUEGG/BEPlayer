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
        let identifiers = mediaURLs.compactMap { url in
            return URLComponents(string: url)?.queryItems?.first(where: {$0.name == "token"})?.value
        }
        
        BEResourceManager.share().preloadGroup("supery", urls: mediaURLs, identifiers: [], expected: 1.0) { group, loaded, failed, total, bytes, totalBytes, loadedTask in
            print("1 ========", group, loaded, failed, total, bytes, totalBytes)
        } speed: { bps in
            print("2 ========", bps)
        } complete: { result, metrics in
            print("3 ========", "all: ", (result["all"] as! Array<Any>).count, "failed: ",(result["failed"] as! Array<Any>).count, "loaded: ", (result["loaded"] as! Array<Any>).count, "-------->", metrics.compactMap({($0.value as? [String: Any])?.compactMap({$0})}))
        }
    }
    
    @IBAction func clean(_ sender: UIButton) {
        print("cache size", BEResourceManager.share().cacheSize())
        BEResourceManager.share().cleanAll {
            print("clean finished")
            print("cache size", BEResourceManager.share().cacheSize())
        }
    }
}

