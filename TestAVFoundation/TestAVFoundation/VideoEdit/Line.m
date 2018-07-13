//
//  Line.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "Line.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation Line

-(void)setBeginPoint:(CGPoint)beginPoint{
    _beginPoint = beginPoint;
    [self setNeedsDisplay];
}
-(void)setEndPoint:(CGPoint)endPoint{
    _endPoint = endPoint;
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, 3);
    CGContextSetStrokeColorWithColor(context, [UIColor colorWithWhite:0.9 alpha:1].CGColor);
    CGContextMoveToPoint(context, self.beginPoint.x, self.beginPoint.y);
    CGContextAddLineToPoint(context, self.endPoint.x, self.endPoint.y);
    CGContextStrokePath(context);
}


@end
