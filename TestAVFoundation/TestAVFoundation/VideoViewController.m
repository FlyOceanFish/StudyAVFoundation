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
    NSMutableArray *_imagesArray;
}
@property (nonatomic,strong)FOFMoviePlayer *moviePlayer;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.title = @"视频编辑学习";
    _videoPath = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    _imagesArray = [NSMutableArray arrayWithCapacity:31];
    for (int i  = 1; i<32; i++) {
        [_imagesArray addObject:[UIImage imageNamed:[NSString stringWithFormat:@"%d.jpg",i]]];
    }
}
- (IBAction)actionClick:(UIButton *)sender {
    switch (sender.tag) {
        case 200:
            [self videoCut:_videoPath];
            break;
        case 201://图片合成视频
            [self picturesToVideo];
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

/**
 图片合成视频，如果图片质量较高的话，需要压缩后才合成，这里有没有进行压缩
 */
- (void)picturesToVideo{
    NSError *outError;
    NSURL *outputURL = [NSURL fileURLWithPath:[self pathForVideo:@"videoFromPics"]];
    AVAssetWriter *assetWriter = [AVAssetWriter assetWriterWithURL:outputURL
                                                          fileType:AVFileTypeQuickTimeMovie
                                                             error:&outError];
    BOOL success = (assetWriter != nil);
    if (success) {
        //写入视频大小
        NSInteger numPixels = 320 * 480;
        //每像素比特
        CGFloat bitsPerPixel = 6;
        NSInteger bitsPerSecond = numPixels * bitsPerPixel;
        
        // 码率和帧率设置,这个能够很好的压缩视频，否则导出来的视频比较大
        NSDictionary *compressionProperties = @{ AVVideoAverageBitRateKey : @(bitsPerSecond),//视频码率就是数据传输时单位时间传送的数据位数，一般我们用的单位是kbps即千位每秒。通俗一点的理解就是取样率，单位时间内取样率越大，精度就越高，处理出来的文件就越接近原始文件。
                                                 AVVideoExpectedSourceFrameRateKey : @(30),
                                                 AVVideoMaxKeyFrameIntervalKey : @(30),
                                                 AVVideoProfileLevelKey : AVVideoProfileLevelH264BaselineAutoLevel
                                                 };
        
        CGSize size =CGSizeMake(320,480);
        NSDictionary *videoSetting = @{AVVideoWidthKey:@(size.width),
                                       AVVideoHeightKey:@(size.height),
                                       AVVideoCodecKey:AVVideoCodecH264,
                                       AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                       AVVideoCompressionPropertiesKey:compressionProperties
                                       };
        
        AVAssetWriterInput *assetWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSetting];
        
        NSDictionary*sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
        //    AVAssetWriterInputPixelBufferAdaptor提供CVPixelBufferPool实例,
        //    可以使用分配像素缓冲区写入输出文件。使用提供的像素为缓冲池分配通常
        //    是更有效的比添加像素缓冲区分配使用一个单独的池
        AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:assetWriterInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
        
        if ([assetWriter canAddInput:assetWriterInput])
            [assetWriter addInput:assetWriterInput];
        
        [assetWriter startWriting];
        
        [assetWriter startSessionAtSourceTime:kCMTimeZero];
        
        dispatch_queue_t myInputSerialQueue =dispatch_queue_create("mediaInputQueue",NULL);
        
        __block int frame = 0;
        [assetWriterInput requestMediaDataWhenReadyOnQueue:myInputSerialQueue usingBlock:^{
            while ([assetWriterInput isReadyForMoreMediaData])
            {
                ++frame;
                if(frame >=[_imagesArray count])
                {
                    [assetWriterInput markAsFinished];
                    [assetWriter finishWritingWithCompletionHandler:^{
                        NSLog(@"合成完成!!");
                    }];
                    break;
                }
                
                CVPixelBufferRef nextBuffer = [self pixelBufferFromCGImage:[_imagesArray[frame] CGImage] size:size];
                
                if (nextBuffer)
                {
                    [adaptor appendPixelBuffer:nextBuffer withPresentationTime:CMTimeMake(frame,1)];
                    CFRelease(nextBuffer);
                    nextBuffer = nil;
                }
            }
        }];
    }

}
- (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    //    当你调用这个函数的时候，Quartz创建一个位图绘制环境，也就是位图上下文。当你向上下文中绘制信息时，Quartz把你要绘制的信息作为位图数据绘制到指定的内存块。一个新的位图上下文的像素格式由三个参数决定：每个组件的位数，颜色空间，alpha选项
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,4*size.width,rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    
    //使用CGContextDrawImage绘制图片  这里设置不正确的话 会导致视频颠倒
    //    当通过CGContextDrawImage绘制图片到一个context中时，如果传入的是UIImage的CGImageRef，因为UIKit和CG坐标系y轴相反，所以图片绘制将会上下颠倒
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    // 释放色彩空间
    CGColorSpaceRelease(rgbColorSpace);
    // 释放context
    CGContextRelease(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
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
