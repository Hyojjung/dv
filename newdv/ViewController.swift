//
//  ViewController.swift
//  newdv
//
//  Created by 김효정 on 28/07/2019.
//  Copyright © 2019 김효정. All rights reserved.
//

import UIKit
import AVKit

class ViewController: AVPlayerViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://obs.line-scdn.net/r/myhome/h/6BD7CF6D61426F07AEDCAD8C9D84E1DC22ce2686t092800d1")!
        let delegate = AssetResourceLoaderDelegate(url: url)
        let asset = Asset(url: url, delegate: delegate)
        let playerItem = AVPlayerItem(asset: asset)
        player = AVPlayer(playerItem: playerItem)
        player?.play()
    }
}

