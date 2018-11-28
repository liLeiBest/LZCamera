//
//  LZCameraCaptureProgressView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/26.
//

#import "LZCameraCaptureProgressView.h"

@implementation LZCameraCaptureProgressView

// MARK: - Initialization
- (void)setProgressValue:(CGFloat)progressValue {
    _progressValue = progressValue;
    
    LZCameraLog(@"进度:%f", progressValue);
    [self setNeedsDisplay];
    self.hidden = progressValue == 1.0f;
}

- (void)drawRect:(CGRect)rect {
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();// 获取上下文
    CGPoint center = CGPointMake(self.frame.size.width / 2.0, self.frame.size.width / 2.0);  // 设置圆心位置
    CGFloat radius = self.frame.size.width / 2.0 - 5.0;  // 设置半径
    CGFloat startAngle = -M_PI_2;  // 圆起点位置
    CGFloat endAngle = startAngle + M_PI * 2 * _progressValue;  // 圆终点位置
    UIBezierPath *path =
    [UIBezierPath bezierPathWithArcCenter:center
                                   radius:radius
                               startAngle:startAngle
                                 endAngle:endAngle
                                clockwise:YES]; // 根据起始点、原点、半径绘制弧线
    CGContextSetLineWidth(ctx, 10); // 设置线条宽度
    [[UIColor whiteColor] setStroke]; // 设置描边颜色
    CGContextAddPath(ctx, path.CGPath); // 把路径添加到上下文
    CGContextStrokePath(ctx);  // 渲染
}

// MARK: - Public
- (void)clearProgress {
    self.hidden = YES;
}

@end
