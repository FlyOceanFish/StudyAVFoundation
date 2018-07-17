//
//  VideoViewController.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/13.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "FOFMoviePlayer.h"
@interface VideoViewController ()
{
    NSString *_videoPath;
    NSString *_newVideoPath;
}
@property (nonatomic,strong)FOFMoviePlayer *moviePlayer;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.title = @"视频编辑学习";
    _videoPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
}
- (IBAction)actionClick:(UIButton *)sender {
    switch (sender.tag) {
        case 200:
            [self videoCut:_videoPath];
            break;
            
        default:
            break;
    }
}


- (void)videoCut:(NSString *)path{
//    1.
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path]];
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack  *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    NSError *error = nil;
    
    NSArray *tracks = asset.tracks;
    NSLog(@"所有轨道:%@\n",tracks);//打印出所有的资源轨道
    [compositionTrack setPreferredTransform:[[asset tracksWithMediaType:AVMediaTypeVideo].firstObject preferredTransform]];
    [compositionTrack insertTimeRange:CMTimeRangeMake(CMTimeMake(1, 1), CMTimeMake(5, 1)) ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject atTime:kCMTimeZero error:&error];//设置视频的截取范围
    
//    2.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:compositionTrack];
//    CGAffineTransform translateToCenter = CGAffineTransformMakeTranslation(compositionTrack.naturalSize.height,0.0);
//    [videolayerInstruction setTransform:CGAffineTransformRotate(translateToCenter, M_PI_2) atTime:CMTimeMake(2, 1)];//将视频旋转90度
    [videolayerInstruction setOpacity:0.0 atTime:compositionTrack.asset.duration];
    
//    3.
    AVMutableVideoCompositionInstruction *videoCompositionInstrution = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    videoCompositionInstrution.timeRange = CMTimeRangeMake(kCMTimeZero, compositionTrack.asset.duration);
    videoCompositionInstrution.layerInstructions = @[videolayerInstruction];
    
//    4.
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    videoComposition.renderSize =  CGSizeMake(compositionTrack.naturalSize.width, compositionTrack.naturalSize.height);//视频宽高，必须设置，否则会奔溃
    /*
     电影：24
     PAL（帕尔制，电视广播制式）和SEACM（）：25
     NTSC（美国电视标准委员会）：29.97
     Web/CD-ROM：15
     其他视频类型，非丢帧视频，E-D动画 30
     */
    videoComposition.frameDuration = CMTimeMake(1, 43);//必须设置，否则会奔溃，一般30就够了
//    videoComposition.renderScale
    videoComposition.instructions = [NSArray arrayWithObject:videoCompositionInstrution];
    
    /*添加水印*/
    [self addWaterMark:compositionTrack.naturalSize withBlock:^(CALayer *parent, CALayer *videoLayer) {
        videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parent];
    }];


//    5.
    AVAssetExportSession *exportSesstion = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    _newVideoPath = [self pathForVideo:@"video"];
    exportSesstion.outputURL = [NSURL fileURLWithPath:_newVideoPath];
    exportSesstion.outputFileType = AVFileTypeMPEG4;
    exportSesstion.shouldOptimizeForNetworkUse = YES;
    
    exportSesstion.videoComposition = videoComposition;//设置导出视频的处理方案
    
    [exportSesstion exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = exportSesstion.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"导出成功");
            dispatch_async(dispatch_get_main_queue(), ^{
                if (self.moviePlayer.playerLayer) {
                    [self.moviePlayer.playerLayer removeFromSuperlayer];
                }
                self.moviePlayer = [[FOFMoviePlayer alloc] initWithFrame:CGRectMake(10, 140,272, 480) url:[NSURL fileURLWithPath:_newVideoPath] superLayer:self.view.layer];
                [self.moviePlayer.playerLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
                [self.moviePlayer fof_play];
            });
        }else{
            
            NSLog(@"导出失败%@",exportSesstion.error);
        }
    }];
}
- (void)addWaterMark:(CGSize)sizeOfVideo withBlock:(void (^)(CALayer *parent,CALayer *videoLayer)) returnBlock{
    
    CATextLayer *textOfvideo=[[CATextLayer alloc] init];
    textOfvideo.string=[NSString stringWithFormat:@"%@",@"测试水印文字"];
    textOfvideo.font = (__bridge CFTypeRef _Nullable)([UIFont boldSystemFontOfSize:24]);
    // 渲染分辨率，否则显示模糊
    textOfvideo.contentsScale = [UIScreen mainScreen].scale;
    [textOfvideo setFrame:CGRectMake(0, 10, sizeOfVideo.width, 40)];
    [textOfvideo setAlignmentMode:kCAAlignmentCenter];
    [textOfvideo setForegroundColor:[UIColor whiteColor].CGColor];
    
    UIImage *myImage=[UIImage imageNamed:@"icon.png"];
    CALayer *layerCa = [CALayer layer];
    layerCa.contents = (id)myImage.CGImage;
    layerCa.frame = CGRectMake(sizeOfVideo.width-120, sizeOfVideo.height-120, 120, 120);
    layerCa.opacity = 1.0;
    
    CALayer *parentLayer=[CALayer layer];
    CALayer *videoLayer=[CALayer layer];
    parentLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    videoLayer.frame=CGRectMake(0, 0, sizeOfVideo.width, sizeOfVideo.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:layerCa];
    [parentLayer addSublayer:textOfvideo];
    returnBlock(parentLayer,videoLayer);
}
#pragma mark - Private
- (NSString *)pathForVideo:(NSString *)videoName{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = paths.firstObject;
    
    NSString *path = [documentsDirectory stringByAppendingPathComponent:
                             [NSString stringWithFormat:@"%@-%d.mp4",videoName,arc4random() % 1000]];
    NSLog(@"视频路径：%@\n",path);
    return path;
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
