//
//  VideoEditViewController.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "VideoEditViewController.h"
#import "FOFMoviePlayer.h"

@interface VideoEditViewController ()
@property (nonatomic,strong)FOFMoviePlayer *moviePlayer;
@end

@implementation VideoEditViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"video" ofType:@"mp4"];
    
    self.moviePlayer = [[FOFMoviePlayer alloc] initWithFrame:CGRectMake(10, 20,400, 300) url:[NSURL fileURLWithPath:path] superLayer:self.view.layer loop:true];
    __weak typeof(self) this = self;
    [self.moviePlayer setBlockStatusReadyPlay:^{
        [this.moviePlayer fof_play];
    }];
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
