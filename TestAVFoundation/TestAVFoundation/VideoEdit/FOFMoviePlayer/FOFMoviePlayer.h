//
//  FOFMoviePlayer.h
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef void(^BlockStatusReadyPlay)(AVPlayerItem *palyItem);
typedef void(^BlockStatusFailed)(void);
typedef void(^BlockStatusUnknown)(void);
typedef void(^BlockTracking)(NSInteger status);
typedef void(^BlockLoadedTimeRanges)(double progress);
typedef void(^BlockPlaybackLikelyToKeepUp)(BOOL keepUp);
typedef void(^BlockPlayToEndTime)(void);

@interface FOFMoviePlayer : NSObject
@property(nonatomic,copy)BlockStatusReadyPlay blockStatusReadyPlay;
@property(nonatomic,copy)BlockStatusFailed blockStatusFailed;
@property(nonatomic,copy)BlockStatusUnknown blockStatusUnknown;
@property(nonatomic,copy)BlockTracking blockTracking;
@property(nonatomic,copy)BlockLoadedTimeRanges blockLoadedTimeRanges;
@property(nonatomic,copy)BlockPlaybackLikelyToKeepUp blockPlaybackLikelyToKeepUp;
@property(nonatomic,copy)BlockPlayToEndTime blockPlayToEndTime;

@property (nonatomic,assign)CGFloat lastStartSeconds;

@property(nonatomic,strong,readonly)NSURL *url;

@property(nonatomic,strong,readonly)AVPlayer *player;
@property(nonatomic,strong,readonly)AVPlayerLayer *playerLayer;
@property(nonatomic,strong,readonly)AVPlayerItem *playItem;

-(instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url superLayer:(CALayer *)superLayer;
-(instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url superLayer:(CALayer *)superLayer loop:(BOOL)loop;

- (void)fof_play;
- (void)fof_pause;
@end
