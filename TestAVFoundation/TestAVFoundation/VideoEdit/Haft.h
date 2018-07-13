//
//  Haft.h
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^BlockMove)(CGPoint point);
typedef void(^BlockMoveEnd)(void);
@interface Haft : UIView
@property (nonatomic,copy)BlockMove blockMove;
@property (nonatomic,copy)BlockMoveEnd blockMoveEnd;
/**
 增加左边的相应区域
 */
@property (nonatomic,assign)NSInteger lefEdgeInset;
/**
 增加右边的相应区域
 */
@property (nonatomic,assign)NSInteger rightEdgeInset;
/**
 增加上边的相应区域
 */
@property (nonatomic,assign)NSInteger topEdgeInset;
/**
 增加下边的相应区域
 */
@property (nonatomic,assign)NSInteger bottomEdgeInset;
@end
