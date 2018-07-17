//
//  FOFMoviePlayer.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/5/10.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "FOFMoviePlayerView.h"

@interface FOFMoviePlayerView()
{
    UIView *_indicatorView;
    AVPlayerLooper *_playerLooper;
}

@property (nonatomic,assign) CMTime duration;
@property (nonatomic,assign) BOOL canKeepUp;

@property (strong, nonatomic)  UIButton *btn;
@property (strong, nonatomic)  UILabel *mLabeStart;
@property (strong, nonatomic)  UILabel *mLabelTimeLeft;
@property (strong, nonatomic)  UISlider *mlider;
@property (strong, nonatomic)  UIProgressView *mprogressView;

@property (strong, nonatomic)  UIView *mViewProgress;
@property (strong, nonatomic)  UIActivityIndicatorView *indicator;
@property (strong, nonatomic)  UISegmentedControl *mSegmentedControl;
@end
@implementation FOFMoviePlayerView

- (instancetype)initWithURL:(NSURL *)url{
    self = [super init];
    if (self) {
        [self initViews];
        self.url = url;
    }
    return self;
}
-(void)layoutSubviews{
    [super layoutSubviews];
    self.playerLayer.frame = CGRectMake(0, 0,CGRectGetWidth(self.bounds), CGRectGetHeight(self.bounds)-14);
    [_btn addTarget:self action:@selector(actionPlayPause:) forControlEvents:UIControlEventTouchUpInside];
    _btn.frame = CGRectMake(CGRectGetWidth(self.playerLayer.bounds)/2-24,CGRectGetHeight(self.playerLayer.bounds)/2-24, 48, 48);
    [self layoutIndicatorSubviews];
}
-(void)awakeFromNib{
    [super awakeFromNib];
    [self initViews];
}
-(void)setUrl:(NSURL *)url{
    _url = url;
    [self.player replaceCurrentItemWithPlayerItem:self.playItem];
}

-(void)initViews{
    [self initIndicatorView];
    self.userInteractionEnabled = YES;
    [self.mlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    [self.mlider addObserver:self forKeyPath:@"tracking" options:NSKeyValueObservingOptionNew context:nil];
    
    self.player = [[AVPlayer alloc] init];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.backgroundColor = [UIColor grayColor].CGColor;
    self.playerLayer.videoGravity = AVLayerVideoGravityResize;
    [self.layer addSublayer:self.playerLayer];

    __weak typeof(self) this = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 12) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float currentTime = CMTimeGetSeconds(time);
        this.mlider.value = currentTime;
        this.mLabeStart.text = [this getMMSSFromSS:(int)currentTime];
        this.mLabelTimeLeft.text = [this getMMSSFromSS:(int)(CMTimeGetSeconds(this.duration)-currentTime)];
        if (fabs(CMTimeGetSeconds(this.duration)-currentTime)<=0.01) {
            [this replay];
        }
    }];
    
    
    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_btn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [self addSubview:_btn];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:_btn.frame];
    self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator.color = [UIColor colorWithRed:23/255.0 green:130/255.0 blue:210/255.9 alpha:1];
    self.indicator.hidden = YES;
    [self addSubview:self.indicator];
    
    [self.mSegmentedControl addTarget:self action:@selector(segmentedIndexChanged:) forControlEvents:UIControlEventValueChanged];
}
- (void)initIndicatorView{
    _indicatorView = [[UIView alloc] initWithFrame:CGRectZero];
    _mLabeStart = [[UILabel alloc] initWithFrame:CGRectZero];
    _mLabeStart.font = [UIFont systemFontOfSize:11];
    _mLabeStart.text = @"00:00:00";
    
    _mLabelTimeLeft = [[UILabel alloc] initWithFrame:CGRectZero];
    _mLabelTimeLeft.font = [UIFont systemFontOfSize:11];
    
    _mlider = [[UISlider alloc] initWithFrame:CGRectZero];
    _mlider.minimumTrackTintColor = [UIColor blueColor];
    _mlider.backgroundColor = [UIColor clearColor];
    _mlider.maximumTrackTintColor = [UIColor clearColor];
    
    _mprogressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    _mprogressView.progressTintColor = [UIColor colorWithWhite:0.5 alpha:1];
    
    [_indicatorView addSubview:_mLabeStart];
    [_indicatorView addSubview:_mLabelTimeLeft];
    [_indicatorView addSubview:_mprogressView];
    [_indicatorView addSubview:_mlider];
    [self addSubview:_indicatorView];

}
- (void)layoutIndicatorSubviews{
    _indicatorView.frame = CGRectMake(0, CGRectGetHeight(self.playerLayer.bounds), CGRectGetWidth(self.bounds), 15);
    _mLabeStart.frame = CGRectMake(0, 0, 49, 15);
    _mLabelTimeLeft.frame = CGRectMake(CGRectGetWidth(self.bounds)-49, 0, 49, 15);
    float _mliderX = _mLabeStart.frame.origin.x+CGRectGetWidth(_mLabeStart.bounds)+8;
    _mlider.frame = CGRectMake(_mliderX, 0, CGRectGetWidth(self.bounds)-_mliderX-CGRectGetWidth(_mLabelTimeLeft.bounds)-8, 15);
    _mprogressView.frame = CGRectMake(_mlider.frame.origin.x+2, (15-2)/2.0, CGRectGetWidth(_mlider.bounds)-8, 2);
}
#pragma mark - Action
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self];
    CALayer *layer = [self.playerLayer hitTest:point];
    if (layer) {
        if (_btn.alpha) {
            [self animalHide];
        }else{
            [self animalShow];
        }
    }
}

- (void)actionPlayPause:(UIButton *)sender {
    if (sender.selected) {
        [self.player pause];
    }else{
        [self.player play];
        [self performSelector:@selector(animalHide) withObject:nil afterDelay:1];
    }
    sender.selected = !sender.selected;
}

- (void)segmentedIndexChanged:(UISegmentedControl *)sender{
    self.player.rate = sender.selectedSegmentIndex+1;
}

#pragma mark - Observe
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    if ([keyPath isEqualToString:@"status"]) {
        AVPlayerItem *item = (AVPlayerItem *)object;
        AVPlayerItemStatus status = [[change objectForKey:@"new"] intValue]; // 获取更改后的状态
        if (status == AVPlayerItemStatusReadyToPlay) {
            _duration = item.duration;//只有在此状态下才能获取，不能在AVPlayerItem初始化后马上获取
            self.mLabelTimeLeft.text = [self getMMSSFromSS:(int)CMTimeGetSeconds(_duration)];
            self.mlider.maximumValue = CMTimeGetSeconds(_duration);
            self.mlider.minimumValue = 0;
            NSLog(@"准备播放");
        } else if (status == AVPlayerItemStatusFailed) {
            AVPlayerItem *item = (AVPlayerItem *)object;
            NSLog(@"%@",item.error);
            NSLog(@"AVPlayerStatusFailed");
        } else {
            NSLog(@"%@",item.error);
            NSLog(@"AVPlayerStatusUnknown");
        }
    }else if ([keyPath isEqualToString:@"tracking"]){
        NSInteger status = [change[@"new"] integerValue];
        float slideValue = self.mlider.value;
        [self.player seekToTime:CMTimeMake(slideValue*_duration.timescale, _duration.timescale) completionHandler:^(BOOL finished) {
            
        }];
        self.mLabeStart.text = [self getMMSSFromSS:(int)slideValue];
        self.mLabelTimeLeft.text = [self getMMSSFromSS:(int)(CMTimeGetSeconds(_duration)-slideValue)];

        if (status) {//正在拖动
            [self.player pause];
        }else{//停止拖动
            if (_btn.selected) {
                [self.player play];
            }
            
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        NSArray *array = _playItem.loadedTimeRanges;
        CMTimeRange timeRange = [array.firstObject CMTimeRangeValue];//本次缓冲时间范围
        float startSeconds = CMTimeGetSeconds(timeRange.start);
        float durationSeconds = CMTimeGetSeconds(timeRange.duration);
        NSTimeInterval totalBuffer = startSeconds + durationSeconds;//缓冲总长度
        self.mprogressView.progress = totalBuffer/CMTimeGetSeconds(_duration);
        NSLog(@"当前缓冲时间：%f",totalBuffer);
    }else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        NSLog(@"缓存不够，不能播放！");
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        if ([change[@"new"] boolValue]) {
            if (!self.indicator.hidden) {
                self.indicator.hidden = YES;
                [self.indicator stopAnimating];
            }
            self.canKeepUp = YES;
            NSLog(@"缓存的足够多可以播放了！");
        }else{
            self.canKeepUp = NO;
        }
    }
    
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

    //        if ([_playItem canPlayFastForward]) {//只有是true的时候，才能支持2倍速度以上
    //            [self.mSegmentedControl insertSegmentWithTitle:@"X3" atIndex:2 animated:NO];
    //            [self.mSegmentedControl insertSegmentWithTitle:@"X4" atIndex:3 animated:NO];
    //        }
    return _playItem;
}
-(NSString *)getMMSSFromSS:(NSInteger)seconds{
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",seconds/3600];
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    return format_time;
}
#pragma mark - Private
- (void)replay{
    self.btn.selected = NO;
    [_player seekToTime:kCMTimeZero];
    [self animalShow];
}
- (void)animalHide{
    [UIView animateWithDuration:1 animations:^{
        _btn.alpha = 0;
        _indicatorView.alpha = 0;
        if (!self.canKeepUp) {
            self.indicator.hidden = NO;
            [self.indicator startAnimating];
        }
    }];
}
- (void)animalShow{
    [UIView animateWithDuration:1 animations:^{
        if (self.indicator.hidden) {
            _btn.alpha = 1;
        }
        _indicatorView.alpha = 1;
    }];
}
-(void)dealloc{
    //    需要释放一下资源否则会奔溃
    [_playItem removeObserver:self forKeyPath:@"status"];
    [_playItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [_playItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [_playItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    [_player.currentItem cancelPendingSeeks];
    [_player.currentItem.asset cancelLoading];
    NSLog(@"顺利销毁");
}
@end
