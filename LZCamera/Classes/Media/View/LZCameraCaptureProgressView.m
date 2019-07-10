//
//  LZCameraCaptureProgressView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/26.
//

#import "LZCameraCaptureProgressView.h"

@interface LZCameraCaptureProgressView()<CAAnimationDelegate>

@property (nonatomic, strong) CAShapeLayer *progressLayer;

@end
@implementation LZCameraCaptureProgressView

// MARK: - Initialization
- (instancetype)initWithFrame:(CGRect)frame {
	if (self = [super initWithFrame:frame]) {
		
		self.progressLayer = [CAShapeLayer layer];
		self.progressLayer.fillColor = [UIColor clearColor].CGColor;
		self.progressLayer.strokeColor = [UIColor whiteColor].CGColor;
		self.progressLayer.lineCap = kCALineCapSquare;
		self.progressLayer.lineWidth = 8;

		[self.layer addSublayer:self.progressLayer];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		
		self.progressLayer = [CAShapeLayer layer];
		self.progressLayer.fillColor = [UIColor clearColor].CGColor;
		self.progressLayer.strokeColor = [UIColor whiteColor].CGColor;
		self.progressLayer.lineCap = kCALineCapSquare;
		self.progressLayer.lineWidth = 8;
		
		[self.layer addSublayer:self.progressLayer];
	}
	return self;
}

- (void)setProgressValue:(CGFloat)progressValue {
    _progressValue = progressValue;
    
    LZCameraLog(@"进度:%f", progressValue);
    self.hidden = progressValue == 1.0f;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	
	CGPoint center = CGPointMake(rect.size.width / 2, rect.size.height / 2);
	CGFloat radius = rect.size.width / 2;
	CGFloat end = - M_PI_2 + (M_PI * 2 * self.progressValue);
	self.progressLayer.frame = self.bounds;
	UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center radius:radius startAngle:-M_PI_2 endAngle:end clockwise:YES];
	path.lineWidth = 8.0f;
	path.lineCapStyle = kCGLineCapSquare;
	self.progressLayer.path = [path CGPath];
}

//- (void)drawRect:(CGRect)rect {
//
//    CGContextRef ctx = UIGraphicsGetCurrentContext();// 获取上下文
//    CGPoint center = CGPointMake(self.frame.size.width / 2.0, self.frame.size.width / 2.0);  // 设置圆心位置
//    CGFloat radius = self.frame.size.width / 2.0 - 5.0;  // 设置半径
//    CGFloat startAngle = -M_PI_2;  // 圆起点位置
//    CGFloat endAngle = startAngle + M_PI * 2 * _progressValue;  // 圆终点位置
//    UIBezierPath *path =
//    [UIBezierPath bezierPathWithArcCenter:center
//                                   radius:radius
//                               startAngle:startAngle
//                                 endAngle:endAngle
//                                clockwise:YES]; // 根据起始点、原点、半径绘制弧线
//    CGContextSetLineWidth(ctx, 10); // 设置线条宽度
//    [[UIColor whiteColor] setStroke]; // 设置描边颜色
//    CGContextAddPath(ctx, path.CGPath); // 把路径添加到上下文
//    CGContextStrokePath(ctx);  // 渲染
//}

// MARK: - Public
- (void)clearProgress {
    self.hidden = YES;
}

@end
