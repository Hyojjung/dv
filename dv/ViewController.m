//
//  DVViewController.m
//  DVAssetLoaderDelegate
//
//  Created by vdugnist on 01/02/2018.
//  Copyright (c) 2018 vdugnist. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "DVAssetLoader.h"
#import "ViewController.h"

@interface DVViewController () <DVAssetLoaderDelegatesDelegate>

@property (nonatomic, weak) AVPlayerLayer *playerLayer;

@end

@implementation DVViewController

- (void)loadView {
    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
    
    NSURL *url = [NSURL URLWithString:@"https://obs.line-scdn.net/r/myhome/h/6BD7CF6D61426F07AEDCAD8C9D84E1DC22ce2686t092800d1"];
    DVURLAsset *asset = [[DVURLAsset alloc] initWithURL:url options:nil];
    asset.loaderDelegate = self;
    
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
    AVPlayer *player = [[AVPlayer alloc] initWithPlayerItem:playerItem];
    player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
    
    AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
    [self.view.layer addSublayer:playerLayer];
    self.playerLayer = playerLayer;
    [player play];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:playerItem
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [player seekToTime:kCMTimeZero];
                                                  }];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    self.playerLayer.frame = self.view.bounds;
}

- (void)dvAssetLoaderDelegate:(DVAssetLoaderDelegate *)loaderDelegate
                  didLoadData:(NSData *)data
                       forURL:(NSURL *)url {
    NSLog(@"data loaded completely 🎉");
}

- (void)dvAssetLoaderDelegate:(DVAssetLoaderDelegate *)loaderDelegate
                  didLoadData:(NSData *)data
                     forRange:(NSRange)range
                          url:(NSURL *)url {
    NSLog(@"data loaded for range: %@", [NSValue valueWithRange:range]);
}

- (void)dvAssetLoaderDelegate:(DVAssetLoaderDelegate *)loaderDelegate
       didRecieveLoadingError:(NSError *)error
                 withDataTask:(NSURLSessionDataTask *)dataTask
                   forRequest:(AVAssetResourceLoadingRequest *)request {
    NSLog(@"loader delegate did receive error: %@", error.localizedDescription);
}


@end
