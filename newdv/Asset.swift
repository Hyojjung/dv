//
//  Asset.swift
//  newdv
//
//  Created by 김효정 on 28/07/2019.
//  Copyright © 2019 김효정. All rights reserved.
//

import AVFoundation

class Asset: AVURLAsset {
    
    init(url: URL, delegate: AVAssetResourceLoaderDelegate) {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "fake"
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
