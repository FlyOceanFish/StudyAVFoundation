//
//  VideoViewController.m
//  TestAVFoundation
//
//  Created by YTO on 2018/5/7.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "VideoViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface VideoViewController ()

@property(nonatomic,strong)AVPlayer *player;
@property(nonatomic,strong)AVPlayerLayer *playerLayer;

@end

@implementation VideoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"视频";
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    NSURL *url = [NSURL fileURLWithPath:path];
    AVPlayerItem *item = [AVPlayerItem playerItemWithURL:url];
    self.player = [AVPlayer playerWithPlayerItem:item];
    
    self.playerLayer = [AVPlayerLayer layer];
    self.playerLayer.frame = CGRectMake(0, 100,CGRectGetWidth(self.view.bounds), 300);
    self.playerLayer.backgroundColor = [UIColor redColor].CGColor;
    [self.view.layer addSublayer:self.playerLayer];
    
    [self.player addObserver:self forKeyPath:@"status" options:(NSKeyValueObservingOptionNew) context:nil];
}
- (IBAction)actionPlay:(UIButton *)sender {
    [self.player play];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{

    AVPlayerItemStatus status = [[change objectForKey:@"new"] intValue]; // 获取更改后的状态
        if (status == AVPlayerItemStatusReadyToPlay) {
                NSLog(@"准备播放");
            } else if (status == AVPlayerItemStatusFailed) {
                AVPlayerItem *item = (AVPlayerItem *)object;
                NSLog(@"%@",item.error);
                NSLog(@"AVPlayerStatusFailed");
            } else {
                AVPlayerItem *item = (AVPlayerItem *)object;
                NSLog(@"%@",item.error);
                NSLog(@"AVPlayerStatusUnknown");
        }
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
