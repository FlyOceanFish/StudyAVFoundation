//
//  VideoEditViewController.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "VideoEditViewController.h"
#import "FOFMoviePlayer.h"
#import "VideoPieces.h"

@interface VideoEditViewController (){
    UIImageView *iv;
}
@property (nonatomic,strong)FOFMoviePlayer *moviePlayer;
@property (nonatomic,strong)VideoPieces *videoPieces;
@property (nonatomic,assign)CGFloat totalSeconds;
@property (nonatomic,assign)CGFloat lastStartSeconds;
@property (nonatomic,assign)CGFloat lastEndSeconds;
@property (nonatomic,assign)BOOL seeking;
@property (nonatomic,strong)id timeObserverToken;
@end

@implementation VideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor blackColor];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    self.lastEndSeconds = NAN;
    self.moviePlayer = [[FOFMoviePlayer alloc] initWithFrame:CGRectMake(10, 20,400, 300) url:[NSURL fileURLWithPath:path] superLayer:self.view.layer];
    __weak typeof(self) this = self;
    [self.moviePlayer setBlockStatusReadyPlay:^(AVPlayerItem *playItem){
        [this.moviePlayer fof_play];
        this.totalSeconds = CMTimeGetSeconds(playItem.duration);
    }];
    [self.moviePlayer setBlockPlayToEndTime:^{
        [this private_replayAtBeginTime:this.lastStartSeconds];
    }];

    self.timeObserverToken = [self.moviePlayer.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(0.5, NSEC_PER_SEC) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        if (!this.seeking) {
            if (fabs(CMTimeGetSeconds(time)-this.lastEndSeconds)<=0.02) {
                    [this.moviePlayer fof_pause];
                    [this private_replayAtBeginTime:this.lastStartSeconds];
                }
        }
    }];
    CGFloat width = CGRectGetWidth(self.view.bounds);
    _videoPieces = [[VideoPieces alloc] initWithFrame:CGRectMake(30, 350, width-60, 80)];
    [_videoPieces setBlockSeekOffLeft:^(CGFloat offX) {
        this.seeking = true;
        [this.moviePlayer fof_pause];
        this.lastStartSeconds = this.totalSeconds*offX/CGRectGetWidth(this.videoPieces.bounds);
        [this.moviePlayer.player seekToTime:CMTimeMakeWithSeconds(this.lastStartSeconds, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    [_videoPieces setBlockSeekOffRight:^(CGFloat offX) {
        this.seeking = true;
        [this.moviePlayer fof_pause];
        this.lastEndSeconds = this.totalSeconds*offX/CGRectGetWidth(this.videoPieces.bounds);
        [this.moviePlayer.player seekToTime:CMTimeMakeWithSeconds(this.lastEndSeconds, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    }];
    
    [_videoPieces setBlockMoveEnd:^{
        NSLog(@"滑动结束");
        if (this.seeking) {
            this.seeking = false;
            [this private_replayAtBeginTime:this.lastStartSeconds];
        }
    }];
    _videoPieces.backgroundColor = [UIColor clearColor];
    [self.view addSubview:_videoPieces];
    CGFloat widthIV = (CGRectGetWidth(_videoPieces.frame))/10.0;
    CGFloat heightIV = CGRectGetHeight(_videoPieces.frame);
    [self getVideoThumbnail:path count:10 splitCompleteBlock:^(BOOL success, NSMutableArray *splitimgs) {
        for (int i = 0; i<splitimgs.count; i++) {
            UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(i*widthIV, 3, widthIV, heightIV-6)];
            iv.contentMode = UIViewContentModeScaleToFill;
            iv.image = splitimgs[i];
            [this.videoPieces insertSubview:iv atIndex:1];
        }
    }];
}
- (void)private_replayAtBeginTime:(Float64)beginTime{
    [self.moviePlayer.player seekToTime:CMTimeMakeWithSeconds(self.lastStartSeconds, 1) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [self.moviePlayer fof_play];
}
- (NSArray *)getVideoThumbnail:(NSString *)path count:(NSInteger)count splitCompleteBlock:(void(^)(BOOL success, NSMutableArray *splitimgs))splitCompleteBlock {
    AVAsset *asset = [AVAsset assetWithURL:[NSURL fileURLWithPath:path]];
    NSMutableArray *arrayImages = [NSMutableArray array];
    [asset loadValuesAsynchronouslyForKeys:@[@"duration"] completionHandler:^{
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
//        generator.maximumSize = CGSizeMake(480,136);//如果是CGSizeMake(480,136)，则获取到的图片是{240, 136}。与实际大小成比例
        generator.appliesPreferredTrackTransform = YES;//这个属性保证我们获取的图片的方向是正确的。比如有的视频需要旋转手机方向才是视频的正确方向。
        /**因为有误差，所以需要设置以下两个属性。如果不设置误差有点大，设置了之后相差非常非常的小**/
        generator.requestedTimeToleranceAfter = kCMTimeZero;
        generator.requestedTimeToleranceBefore = kCMTimeZero;
        Float64 seconds = CMTimeGetSeconds(asset.duration);
        NSMutableArray *array = [NSMutableArray array];
        for (int i = 0; i<count; i++) {
            CMTime time = CMTimeMakeWithSeconds(i*(seconds/10.0),1);//想要获取图片的时间位置
            [array addObject:[NSValue valueWithCMTime:time]];
        }
        __block int i = 0;
        [generator generateCGImagesAsynchronouslyForTimes:array completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable imageRef, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {

            i++;
            if (result==AVAssetImageGeneratorSucceeded) {
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                [arrayImages addObject:image];
            }else{
                NSLog(@"获取图片失败！！！");
            }
            if (i==count) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    splitCompleteBlock(YES,arrayImages);
                });
            }
        }];
    }];
    return arrayImages;

}
-(void)dealloc{
    [self.moviePlayer.player removeTimeObserver:self.timeObserverToken];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
