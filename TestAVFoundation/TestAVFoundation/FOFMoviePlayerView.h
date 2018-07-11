//
//  FOFMoviePlayer.h
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/5/10.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface FOFMoviePlayerView : UIView

@property(nonatomic,strong)NSURL *url;

@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)AVPlayerLayer *playerLayer;
@property(nonatomic,strong)AVPlayerItem *playItem;

- (instancetype)initWithURL:(NSURL *)url;
@end
