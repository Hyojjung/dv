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
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "fake"
        delegate = AssetResourceLoaderDelegate(url: url)
        guard let fakeUrl = components?.url
            else {
                print("can not make fake url")
                super.init(url: url, options: nil)
                return
        }
        super.init(url: fakeUrl, options: nil)
        resourceLoader.setDelegate(delegate, queue: DispatchQueue.main)
    }
}
