//
//  VideoPieces.h
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Haft.h"

typedef void(^BlockSeekOff)(CGFloat offX);

@interface VideoPieces : UIView
@property (nonatomic,copy)BlockSeekOff blockSeekOffLeft;
@property (nonatomic,copy)BlockSeekOff blockSeekOffRight;
@property (nonatomic,copy)BlockMoveEnd blockMoveEnd;
@property (nonatomic,assign)CGFloat minGap;
@end
