//
//  FOFMoviePlayer.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "FOFMoviePlayer.h"
@interface FOFMoviePlayer()
{
    AVPlayerLooper *_playerLooper;
    AVPlayerItem *_playItem;
    BOOL _loop;
}
@property(nonatomic,strong)NSURL *url;

@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)AVPlayerLayer *playerLayer;
@property(nonatomic,strong)AVPlayerItem *playItem;

@property (nonatomic,assign) CMTime duration;
@end
@implementation FOFMoviePlayer

-(instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url superLayer:(CALayer *)superLayer{
    self = [super init];
    if (self) {
        [self initplayers:superLayer];
        _playerLayer.frame = frame;
        self.url = url;
    }
    return self;
}
-(instancetype)initWithFrame:(CGRect)frame url:(NSURL *)url superLayer:(CALayer *)superLayer loop:(BOOL)loop{
    self = [self initWithFrame:frame url:url superLayer:superLayer];
    if (self) {
        _loop = loop;
    }
    return self;
}
- (void)initplayers:(CALayer *)superLayer{
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [superLayer addSublayer:self.playerLayer];
}
- (void)initLoopPlayers:(CALayer *)superLayer{
    self.player = [[AVQueuePlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [superLayer addSublayer:self.playerLayer];
}
-(void)fof_play{
    [self.player play];
}
-(void)fof_pause{
    [self.player pause];
}

#pragma mark - Observe
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        AVPlayerItemStatus status = [[change objectForKey:@"new"] intValue]; // 获取更改后的状态
        if (status == AVPlayerItemStatusReadyToPlay) {
            _duration = item.duration;//只有在此状态下才能获取，不能在AVPlayerItem初始化后马上获取
            NSLog(@"准备播放");
            if (self.blockStatusReadyPlay) {
                self.blockStatusReadyPlay(item);
            }
        } else if (status == AVPlayerItemStatusFailed) {
            if (self.blockStatusFailed) {
                self.blockStatusFailed();
            }
            AVPlayerItem *item = (AVPlayerItem *)object;
            NSLog(@"%@",item.error);
            NSLog(@"AVPlayerStatusFailed");
        } else {
            self.blockStatusUnknown();
            NSLog(@"%@",item.error);
            NSLog(@"AVPlayerStatusUnknown");
        }
    }else if ([keyPath isEqualToString:@"tracking"]){
        NSInteger status = [change[@"new"] integerValue];
        if (self.blockTracking) {
            self.blockTracking(status);
        }
        if (status) {//正在拖动
            [self.player pause];
        }else{//停止拖动
            
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = _playItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
        CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        double progress = totalBuffer/CMTimeGetSeconds(_duration);
        if (self.blockLoadedTimeRanges) {
            self.blockLoadedTimeRanges(progress);
        }
        NSLog(@"当前缓冲时间：%f",totalBuffer);
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        NSLog(@"缓存不够，不能播放！");
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        if (self.blockPlaybackLikelyToKeepUp) {
            self.blockPlaybackLikelyToKeepUp([change[@"new"] boolValue]);
        }
    }
    
}

-(void)setUrl:(NSURL *)url{
    _url = url;
    [self.player replaceCurrentItemWithPlayerItem:self.playItem];
}

-(AVPlayerItem *)playItem{
    _playItem = [[AVPlayerItem alloc] initWithURL:_url];
    //监听播放器的状态，准备好播放、失败、未知错误
    [_playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //    监听缓存的时间
    [_playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //    监听获取当缓存不够，视频加载不出来的情况：
    [_playItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    //    用于监听缓存足够播放的状态
    [_playItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(private_playerMovieFinish) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    return _playItem;
}
- (void)private_playerMovieFinish{
    NSLog(@"播放结束");
    if (self.blockPlayToEndTime) {
        self.blockPlayToEndTime();
    }
    if (_loop) {
        [self.player pause];
        CMTime time = CMTimeMake(1, 1);
        __weak typeof(self)this = self;
        [self.player seekToTime:time completionHandler:^(BOOL finished) {
            [this.player play];
        }];
    }
}
-(void)dealloc{
    NSLog(@"-----销毁-----");
}
@end
