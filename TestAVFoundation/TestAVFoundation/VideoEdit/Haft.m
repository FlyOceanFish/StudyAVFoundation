//
//  Haft.m
//  TestAVFoundation
//
//  Created by FlyOceanFish on 2018/7/11.
//  Copyright © 2018年 FlyOceanFish. All rights reserved.
//

#import "Haft.h"
#import <CoreGraphics/CoreGraphics.h>

@implementation Haft
-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = true;
    }
    return self;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event{
    CGRect rect = CGRectMake(self.bounds.origin.x-self.lefEdgeInset, self.bounds.origin.y-self.topEdgeInset, CGRectGetWidth(self.bounds)+self.lefEdgeInset+self.rightEdgeInset, CGRectGetHeight(self.bounds)+self.bottomEdgeInset+self.topEdgeInset);
    if (CGRectContainsPoint(rect, point)) {
        return YES;
    }
    return NO;
}
-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"开始");
}
-(void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    NSLog(@"Move");
    UITouch *touch = touches.anyObject;
    CGPoint point = [touch locationInView:self.superview];
    float maxX = CGRectGetWidth(self.superview.bounds)-CGRectGetWidth(self.bounds);
    if (point.x>maxX) {
        point.x = maxX;
    }
    if (point.x>=0&&point.x<=(CGRectGetWidth(self.superview.bounds)-CGRectGetWidth(self.bounds))&&self.blockMove) {
        self.blockMove(point);
    }
}
-(void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    if (self.blockEnd) {
        self.blockEnd();
    }
}
- (void)drawRect:(CGRect)rect {
    
    float width = CGRectGetWidth(self.bounds);
    float height = CGRectGetHeight(self.bounds);
    float lineWidth = 1.5;
    float lineHeight = 12;
    float gap = (width-lineWidth*2)/3.0;
    float lineY = (height-lineHeight)/2.0;
    
    CGContextRef context  = UIGraphicsGetCurrentContext();
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] colorWithAlphaComponent:0.8].CGColor);
    CGContextMoveToPoint(context, gap+lineWidth/2, lineY);
    CGContextAddLineToPoint(context, gap+lineWidth/2, lineY+lineHeight);
    CGContextStrokePath(context);
    
    CGContextSetLineWidth(context, lineWidth);
    CGContextSetStrokeColorWithColor(context, [[UIColor grayColor] colorWithAlphaComponent:0.8].CGColor);
    CGContextMoveToPoint(context, gap*2+lineWidth+lineWidth/2, lineY);
    CGContextAddLineToPoint(context, gap*2+lineWidth+lineWidth/2, lineY+lineHeight);
    CGContextStrokePath(context);
    
}


@end
