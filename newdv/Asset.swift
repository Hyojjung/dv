//
//  Asset.swift
//  newdv
//
//  Created by 김효정 on 28/07/2019.
//  Copyright © 2019 김효정. All rights reserved.
//

import AVFoundation

class Asset: AVURLAsset {
    
    let delegate: AVAssetResourceLoaderDelegate
    
    init(url: URL) {
        delegate = AssetResourceLoaderDelegate(url: url)
        super.init(url: url.replaceScheme(to: "fake"), options: nil)
        resourceLoader.setDelegate(delegate, queue: DispatchQueue.main)
    }
}
