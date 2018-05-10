//
//  TestMoviePlayerViewController.m
//  TestAVFoundation
//
//  Created by YTO on 2018/5/10.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "TestMoviePlayerViewController.h"
#import "FOFMoviePlayer.h"

@interface TestMoviePlayerViewController ()

@property (weak, nonatomic) IBOutlet FOFMoviePlayer *mMoviePlayer;
@end

@implementation TestMoviePlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.mMoviePlayer.url = [NSURL URLWithString:@"http://192.168.9.197:8080/videos/videos.mp4"];
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
