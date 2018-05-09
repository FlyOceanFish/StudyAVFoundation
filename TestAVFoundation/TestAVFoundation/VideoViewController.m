//
//  VideoViewController.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/5/7.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//


/*
   AVQueuePlayer可以很好连续播放两个视频，播放A的时候会提前预加载B，甚至C，但是AVQueuePlayer不是播放列表。可以实现循环播放功能
 AVPlayerLooper 实现循环播放功能代码更加简洁
 */
#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoViewController ()
{
    
    UIButton *_btn;
    AVPlayerItem *_playItem;
}
@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)AVPlayerLayer *playerLayer;
@property (nonatomic,assign) CMTime duration;
@property (nonatomic,assign) BOOL canKeepUp;

@property (weak, nonatomic) IBOutlet UILabel *mLabeStart;
@property (weak, nonatomic) IBOutlet UILabel *mLabelTimeLeft;
@property (weak, nonatomic) IBOutlet UISlider *mlider;
@property (weak, nonatomic) IBOutlet UIProgressView *mprogressView;

@property (weak, nonatomic) IBOutlet UIView *mViewProgress;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (weak, nonatomic) IBOutlet UISegmentedControl *mSegmentedControl;
@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频";    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self.mlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    [self.mlider addObserver:self forKeyPath:@"tracking" options:NSKeyValueObservingOptionNew context:nil];
    
    
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"video2" ofType:@"mp4"];
//    NSURL *url = [NSURL fileURLWithPath:path];

//    NSURL *url = [NSURL URLWithString:@"http://static.tripbe.com/videofiles/20121214/9533522808.f4v.mp4"];
//    NSURL *url = [NSURL URLWithString:@"http://192.168.9.196:8080/videos/video.mp4"];
    NSURL *url = [NSURL URLWithString:@"http://192.168.9.197:8080/videos/videos.mp4"];
    _playItem = [[AVPlayerItem alloc] initWithURL:url];
//    _playItem.preferredForwardBufferDuration = 5;此属性设置缓存了多少秒就开始播放，不过要与AVPlayer的automaticallyWaitsToMinimizeStalling = false结合使用才行

//    AVAsset *asset = [AVAsset assetWithURL:url];//实际是创建了AVURLAsset
//    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
//    self.player = [AVPlayer playerWithPlayerItem:item];//此实例方法要配合以上两句实例才行，即通过AVAsset
    
//    self.player = [[AVPlayer alloc] initWithPlayerItem:_playItem];//这是第二种方式
    
    self.player = [[AVPlayer alloc] init];//第三种方式苹果推荐的方式，先实例化一个空的AVPlayerLayer创建之后，通过replaceCurrentItemWithPlayerItem设置。最好的实践是在AVPlayer调用play之后调用replaceCurrentItemWithPlayerItem
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    [self.player replaceCurrentItemWithPlayerItem:_playItem];
    
    self.playerLayer.frame = CGRectMake(0, 0,CGRectGetWidth(self.view.bounds), 260);
    self.playerLayer.backgroundColor = [UIColor redColor].CGColor;
    self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:self.playerLayer];
//监听播放器的状态，准备好播放、失败、未知错误
    [_playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
//    监听缓存的时间
    [_playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
//    监听获取当缓存不够，视频加载不出来的情况：
    [_playItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
//    用于监听缓存足够播放的状态
    [_playItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    __weak typeof(self) this = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        float currentTime = CMTimeGetSeconds(time);
        this.mlider.value = currentTime;
        this.mLabeStart.text = [this getMMSSFromSS:(int)currentTime];
        this.mLabelTimeLeft.text = [this getMMSSFromSS:(int)(CMTimeGetSeconds(this.duration)-currentTime)];
    }];


    _btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [_btn setImage:[UIImage imageNamed:@"play"] forState:UIControlStateNormal];
    [_btn setImage:[UIImage imageNamed:@"pause"] forState:UIControlStateSelected];
    [_btn addTarget:self action:@selector(actionPlayPause:) forControlEvents:UIControlEventTouchUpInside];
    _btn.frame = CGRectMake(CGRectGetWidth(self.playerLayer.bounds)/2-16,CGRectGetHeight(self.playerLayer.bounds)/2-16, 32, 32);
    [self.view addSubview:_btn];
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithFrame:_btn.frame];
    self.indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhiteLarge;
    self.indicator.color = [UIColor colorWithRed:23/255.0 green:130/255.0 blue:210/255.9 alpha:1];
    self.indicator.hidden = YES;
    [self.view addSubview:self.indicator];
    
    if ([_playItem canPlayFastForward]) {//只有是true的时候，才能支持2倍速度以上
        [self.mSegmentedControl insertSegmentWithTitle:@"X3" atIndex:2 animated:NO];
        [self.mSegmentedControl insertSegmentWithTitle:@"X4" atIndex:3 animated:NO];
    }
    [self.mSegmentedControl addTarget:self action:@selector(segmentedIndexChanged:) forControlEvents:UIControlEventValueChanged];
//    AVPlayerTimeControlStatusPaused, 暂停
//    AVPlayerTimeControlStatusWaitingToPlayAtSpecifiedRate,等待播放
//    AVPlayerTimeControlStatusPlaying 播放
//    _player.timeControlStatus
}
#pragma mark - Action
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
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self.view];
    CALayer *layer = [self.playerLayer hitTest:point];
    if (layer) {
        if (_btn.alpha) {
            [self animalHide];
        }else{
            [self animalShow];
        }
    }
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"begin");
}
#pragma mark - Private
- (void)animalHide{
    [UIView animateWithDuration:1 animations:^{
        _btn.alpha = 0;
        self.mViewProgress.alpha = 0;
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
        self.mViewProgress.alpha = 1;
    }];
}

-(NSString *)getMMSSFromSS:(NSInteger)seconds{
    NSString *str_hour = [NSString stringWithFormat:@"%02ld",seconds/3600];
    NSString *str_minute = [NSString stringWithFormat:@"%02ld",(seconds%3600)/60];
    NSString *str_second = [NSString stringWithFormat:@"%02ld",seconds%60];
    NSString *format_time = [NSString stringWithFormat:@"%@:%@:%@",str_hour,str_minute,str_second];
    return format_time;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/
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
