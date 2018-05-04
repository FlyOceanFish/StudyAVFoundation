//
//  ViewController.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/5/2.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

@interface ViewController ()<AVAudioPlayerDelegate>
{
    NSURL *_url;
}
@property (nonatomic,strong)AVAudioPlayer *player;
@property (nonatomic,strong)AVAudioRecorder *recorder;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];//支持后台播放和录音
    [[AVAudioSession sharedInstance] setActive:YES error:nil];//这两行代码在录音和播放的时候要写，否则会失败
    if (error) {
        NSLog(@"注册录音失败%@",error);
    }else{
        NSLog(@"注册录音成功!");
    }
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;//必须先调用一遍，要不锁屏界面的时候显示不出来。这里设置为空，表示还没有歌曲播放
    
}

- (void)viewDidAppear:(BOOL)animated {
    //    接受远程控制 这句如果不调用的话，锁屏不会显示出来
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
}

- (void)viewDidDisappear:(BOOL)animated {
    //    取消远程控制
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
}
- (void)setPlayingInfo {
    //    设置后台播放时显示的东西，例如歌曲名字，图片等
    MPMediaItemArtwork *artWork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"empty.png"]];
    
    NSDictionary *dic = @{MPMediaItemPropertyTitle:@"时间煮雨",
                          MPMediaItemPropertyArtist:@"吴亦凡",
                          MPMediaItemPropertyArtwork:artWork,
                          MPMediaItemPropertyPlaybackDuration:@(3)
                          };
    [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dic];
    
}
- (NSURL *)pathForMedia{
    return [self pathForName:@"test.aac"];
}
- (NSURL *)pathForName:(NSString *)name{
    NSString *docum = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).lastObject;
    docum = [docum stringByAppendingPathComponent:name];
    NSURL *url = [NSURL URLWithString:docum];
    return url;
}
- (NSURL *)pathForPlaybackground{
    NSString *path = [[NSBundle mainBundle] pathForResource:@"宿命者" ofType:@"mp3"];
    NSURL *url = [NSURL fileURLWithPath:path];
    return url;
}
//支持后台播放，并且锁屏可以看

- (IBAction)actionPlaybackground:(id)sender {
    NSURL *url = [self pathForPlaybackground];
    NSError *error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];//播放声音
    if (error) {
        NSLog(@"播放失败%@",error);
    }else{
        [self.player play];
        [self setPlayingInfo];
    }
}
//录音、合成之后等播放
- (IBAction)actionPlay:(id)sender {
    NSURL *url = _url;
    NSError *error = nil;
    self.player = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:&error];//播放声音
    self.player.delegate = self;
    if (error) {
        NSLog(@"播放失败%@",error);
    }else{
        [self.player play];
    }
    
}
//暂停录音
- (IBAction)actionPause:(id)sender {
    if ([self.recorder isRecording]) {
//        [self.recorder pause];//pause之后，不会把所有的录音写入文件中，并且可以通过recorde继续录制
        [self.recorder stop];//stop之后会把所有的录音都写到文件中。文件录制结束后一定要stop一下，否则有可能播放失败的
    }
}
//开始录音
- (IBAction)actionRecord:(id)sender {
    _url = [self pathForMedia];
    NSMutableDictionary *dicM=[NSMutableDictionary dictionary];
    
    //设置录音格式
    
    [dicM setObject:@(kAudioFormatMPEG4AAC)forKey:AVFormatIDKey];
    
    //设置录音采样率，8000是电话采样率，对于一般录音已经够了，不过为了保证声音不失真，采样频率应该在40kHz左右
//    8000 Hz - 电话所用采样率， 对于人的说话已经足够
//    11025 Hz - 电话所用采样率
//    22050 Hz - 无线电广播所用采样率
//    32000 Hz - miniDV 数码视频 camcorder、DAT (LP mode)所用采样率
//    44100 Hz - 音频 CD, 也常用于 MPEG-1 音频（VCD，SVCD，MP3）所用采样率

    [dicM setObject:@(8000)forKey:AVSampleRateKey];
    
    //设置录制通道 单频道和双频道
    
    [dicM setObject:@(2)forKey:AVNumberOfChannelsKey];
    
    //每个采样点位数,分为8、16、24、32
    
    [dicM setObject:@(16)forKey:AVLinearPCMBitDepthKey];
    
    //是否使用浮点数采样
    
    [dicM setObject:@(YES)forKey:AVLinearPCMIsFloatKey];
    [dicM setObject:@(AVAudioQualityMedium) forKey:AVEncoderAudioQualityKey];//设置音频质量
    NSError *error = nil;
    
    self.recorder = [[AVAudioRecorder alloc] initWithURL:_url settings:dicM error:&error];
    if (error) {
        NSLog(@"%@",error.description);
    }
    if ([self.recorder prepareToRecord]) {//创建文件并且准备开始录音
        NSLog(@"准备好录音");
         [self.recorder record];//开始录音或继续录音，(暂停之后可以继续录音)
    }else{
        NSLog(@"失败");
    }
   
}
- (NSURL *)pathForCompostion{
    NSString *document = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    document = [document stringByAppendingPathComponent:[NSString stringWithFormat:@"%.0f.m4a",[NSDate date].timeIntervalSince1970]];
    return [NSURL fileURLWithPath:document];
}
//开始合成
- (IBAction)audioComposition:(UIButton *)button{
    _url = [self pathForCompostion];
    NSString *path1 = [[NSBundle mainBundle] pathForResource:@"男声" ofType:@"mp3"];
    NSString *path2 = [[NSBundle mainBundle] pathForResource:@"女声" ofType:@"mp3"];
    
    AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path1]];
    AVURLAsset *asset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:path2]];
    AVAssetTrack *track1 = [asset1 tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetTrack *track2 = [asset2 tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    AVMutableComposition *composition = [AVMutableComposition composition];
    AVMutableCompositionTrack  *compositionTrack = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    
//    AVMutableCompositionTrack  *compositionTrack2 = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:1];//这里可以再生成一个mutableCoposition，这样可以实现给一段声音添加一个背景音乐
    
    NSError *error1 = nil;
    NSError *error2 = nil;
    NSError *error3 = nil;
    float timescale1 = asset1.duration.timescale;
    float timescale2 = asset2.duration.timescale;
    
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,asset1.duration) ofTrack:track1 atTime:kCMTimeZero error:&error1];
    [compositionTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero,asset2.duration) ofTrack:track2 atTime:asset1.duration error:&error2];

//    [compositionTrack2 insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:track2 atTime:kCMTimeZero error:&error3];
    
//    [compositionTrack scaleTimeRange:CMTimeRangeMake(kCMTimeZero,asset1.duration) toDuration:CMTimeMake(asset1.duration.value, timescale1*3)];//通过此方法可以实现语音或视频的加速和减速
    AVAssetExportSession *exportSessio = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    exportSessio.outputFileType = AVFileTypeAppleM4A;
    exportSessio.outputURL = _url;//路径如果已经存在此文件，则导出会失败
//    exportSessio.timeRange //对音视频截取的时间
    [exportSessio exportAsynchronouslyWithCompletionHandler:^{
        AVAssetExportSessionStatus status = exportSessio.status;
        if (status == AVAssetExportSessionStatusCompleted) {
            NSLog(@"导出成功");
        }else{
          NSLog(@"导出失败");
        }
    }];
}

//锁屏之后屏幕上显示的暂停、上一曲、下一曲操作
-(void)remoteControlReceivedWithEvent:(UIEvent *)event{
    // 根据事件的子类型(subtype) 来判断具体的事件类型, 并做出处理
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlPause: {
            // 执行播放或暂停的相关操作 (锁屏界面和上拉快捷功能菜单处的播放按钮)
            break;
        }
        case UIEventSubtypeRemoteControlPreviousTrack: {
            // 执行上一曲的相关操作 (锁屏界面和上拉快捷功能菜单处的上一曲按钮)
            break;
        }
        case UIEventSubtypeRemoteControlNextTrack: {
            // 执行下一曲的相关操作 (锁屏界面和上拉快捷功能菜单处的下一曲按钮)
            //    设置后台播放时显示的东西，例如歌曲名字，图片等
            MPMediaItemArtwork *artWork = [[MPMediaItemArtwork alloc] initWithImage:[UIImage imageNamed:@"empty.png"]];
            
            NSDictionary *dic = @{MPMediaItemPropertyTitle:@"下一曲",
                                  MPMediaItemPropertyArtist:@"无名 ",
                                  MPMediaItemPropertyArtwork:artWork
                                  };
            [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:dic];
            break;
        }
        case UIEventSubtypeRemoteControlTogglePlayPause: {
            // 进行播放/暂停的相关操作 (耳机的播放/暂停按钮)
            break;
        }
        default:
            break;
    }
}

@end
