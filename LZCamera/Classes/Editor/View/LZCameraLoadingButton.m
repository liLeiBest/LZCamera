//
//  LZCameraLoadingButton.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/30.
//

#import "LZCameraLoadingButton.h"

@interface LZCameraLoadingButton() {
	
	/** 遮盖层 */
	CAShapeLayer *maskLayer;
	/** 白色层 */
	CAShapeLayer *shapeLayer;
	/** 加载层 */
	CAShapeLayer *loadingLayer;
	/** 白圈层 */
	CAShapeLayer *circleLayer;
	/** 按钮 */
	UIButton *button;
	
	/** 按钮事件 Target */
	__weak id btnActionTarget;
	/** 按钮点击事件 */
	SEL btnClickSelector;
}

@end
@implementation LZCameraLoadingButton

// MARK: - Initialization
- (void)awakeFromNib {
	[super awakeFromNib];
	
	[self setupSubViews];
	[self setupDefaultValue];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	button.frame = self.bounds;
	
	shapeLayer.frame = self.bounds;
	shapeLayer.strokeColor = self.shapeColor.CGColor;
	shapeLayer.path = [self drawBezierPath:self.frame.size.height * 0.5f].CGPath;
	shapeLayer.fillColor = [UIColor clearColor].CGColor;
	shapeLayer.strokeColor = self.shapeColor.CGColor;
	shapeLayer.lineWidth = 1.0f;
}

- (void)dealloc {
	LZCameraLog();
}

// MARK: - Public
- (void)setAttributedTitle:(NSAttributedString *)attributedTitle {
	_attributedTitle = attributedTitle;
	
	[button setAttributedTitle:attributedTitle forState:UIControlStateNormal];
}

- (instancetype)initWithTitle:(NSAttributedString *)title
					shapColor:(UIColor *)shapColor
						frame:(CGRect)frame {
	
	if (self = [super init]) {
		
		self.frame = frame;
		self.attributedTitle = title;
		self.shapeColor = shapColor;
		self.circleColor = shapColor;
		self.maskColor = shapColor;
		self.loadColor = shapColor;
		[self setupSubViews];
	}
	return self;
}

- (void)addTarget:(id)target
		   action:(SEL)action {
	
	btnClickSelector = action;
	btnActionTarget = target;
	[button addTarget:self action:@selector(clickAnimation) forControlEvents:UIControlEventTouchDown];
}

- (void)animationFinish {
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		
		[self removeSubViews];
		[self setupSubViews];
		if ([self->btnActionTarget respondsToSelector:self->btnClickSelector]) {
			[self addTarget:self->btnActionTarget action:self->btnClickSelector];
		}
	});
}

// MARK: - UI Event
- (void)clickBtn {
	[self clickAnimation];
}

// MARK: - Private
- (void)setupDefaultValue {
	
	self.shapeColor = [UIColor blackColor];
	self.circleColor = [UIColor blackColor];
	self.maskColor = [UIColor blackColor];
	self.loadColor = [UIColor blackColor];
	self.minAnimationTime = 0.0f;
}

- (void)setupSubViews {
	
	shapeLayer = [CAShapeLayer layer];
	shapeLayer.frame = self.bounds;
	[self.layer addSublayer:shapeLayer];
	
	button = [UIButton buttonWithType:UIButtonTypeCustom];
	button.frame = self.bounds;
	[button setAttributedTitle:self.attributedTitle forState:UIControlStateNormal];
	[self addSubview:button];
}

- (void)clickAnimation {
	
	circleLayer = [CAShapeLayer layer];
	circleLayer.position = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
	circleLayer.fillColor = self.circleColor.CGColor;
	circleLayer.path = [self drawCircleBezierPath:0].CGPath;
	[self.layer addSublayer:circleLayer];
	
	CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
	basicAnimation.duration = 0.15f;
	basicAnimation.toValue = (__bridge id _Nullable)([self drawCircleBezierPath:(self.bounds.size.height - 10 * 2) * 0.5f].CGPath);
	basicAnimation.removedOnCompletion = NO;
	basicAnimation.fillMode = kCAFillModeForwards;
	[circleLayer addAnimation:basicAnimation forKey:@"clickCicrleAnimation"];
	
	[self performSelector:@selector(clickNextAnimation) withObject:self afterDelay:basicAnimation.duration];
}

- (void)clickNextAnimation {
	
	circleLayer.fillColor = [UIColor clearColor].CGColor;
	circleLayer.strokeColor = self.circleColor.CGColor;
	circleLayer.lineWidth = 10.0f;
	
	CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
	
	CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
	basicAnimation.duration = 0.15f;
	basicAnimation.toValue = (__bridge id _Nullable)[self drawCircleBezierPath:self.bounds.size.height - 10 * 2].CGPath;
	basicAnimation.removedOnCompletion = NO;
	basicAnimation.fillMode = kCAFillModeForwards;
	
	CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacityAnimation.beginTime = 0.10f;
	opacityAnimation.duration = 0.15f;
	opacityAnimation.toValue = @0.0f;
	opacityAnimation.removedOnCompletion = NO;
	opacityAnimation.fillMode = kCAFillModeForwards;
	
	animationGroup.duration = opacityAnimation.beginTime + opacityAnimation.duration;
	animationGroup.removedOnCompletion = NO;
	animationGroup.fillMode = kCAFillModeForwards;
	animationGroup.animations = @[basicAnimation, opacityAnimation];
	
	[circleLayer addAnimation:animationGroup forKey:@"clickCicrleAnimation"];
	
	[self performSelector:@selector(startMaskAnimation) withObject:self afterDelay:animationGroup.duration];
}

- (void)startMaskAnimation {
	
	maskLayer = [CAShapeLayer layer];
	maskLayer.opacity = 0.15f;
	maskLayer.fillColor = self.maskColor.CGColor;
	maskLayer.path = [self drawBezierPath:self.frame.size.height * 0.5f].CGPath;
	[self.layer addSublayer:maskLayer];
	
	CABasicAnimation *basicAnimaton = [CABasicAnimation animationWithKeyPath:@"path"];
	basicAnimaton.duration = 0.25f;
	basicAnimaton.toValue = (__bridge id _Nullable)[self drawBezierPath:self.frame.size.height * 0.5f].CGPath;
	basicAnimaton.removedOnCompletion = NO;
	basicAnimaton.fillMode = kCAFillModeForwards;
	[maskLayer addAnimation:basicAnimaton forKey:@"maskAnimation"];
	
	[self performSelector:@selector(dismissAnimation) withObject:self afterDelay:basicAnimaton.duration + 0.2f];
}

- (void)dismissAnimation {
	
	[self removeSubViews];
	
	CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
	
	CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
	basicAnimation.duration = 0.15f;
	basicAnimation.toValue = (__bridge id _Nullable)([self drawBezierPath:self.frame.size.width * 0.5f].CGPath);
	basicAnimation.removedOnCompletion = NO;
	basicAnimation.fillMode = kCAFillModeForwards;
	
	CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
	opacityAnimation.beginTime = 0.10f;
	opacityAnimation.duration = 0.15;
	opacityAnimation.toValue = @0.0f;
	basicAnimation.removedOnCompletion = NO;
	basicAnimation.fillMode = kCAFillModeForwards;
	
	animationGroup.animations = @[basicAnimation, opacityAnimation];
	animationGroup.duration = opacityAnimation.beginTime + opacityAnimation.duration;
	animationGroup.removedOnCompletion = NO;
	animationGroup.fillMode = kCAFillModeForwards;
	[shapeLayer addAnimation:animationGroup forKey:@"dismisAnimation"];
	
	[self performSelector:@selector(loadingAnimation) withObject:self afterDelay:animationGroup.duration];
}

- (void)loadingAnimation {
	
	loadingLayer = [CAShapeLayer layer];
	loadingLayer.position = CGPointMake(self.bounds.size.width * 0.5f, self.bounds.size.height * 0.5f);
	loadingLayer.fillColor = [UIColor clearColor].CGColor;
	loadingLayer.strokeColor = self.loadColor.CGColor;
	loadingLayer.lineWidth = 2.0f;
	loadingLayer.path = [self drawLoadingBezierPath].CGPath;
	[self.layer addSublayer:loadingLayer];
	
	CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	basicAnimation.fromValue = @(0);
	basicAnimation.toValue = @(M_PI * 2.0f);
	basicAnimation.duration = 0.5f;
	basicAnimation.repeatCount = LONG_MAX;
	[loadingLayer addAnimation:basicAnimation forKey:@"loadingAnimation"];
	
	if (0.0f < self.minAnimationTime) {
		[self performSelector:@selector(removeAllAnimation) withObject:self afterDelay:self.minAnimationTime];
	} else {
		if ([btnActionTarget respondsToSelector:btnClickSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[btnActionTarget performSelector:btnClickSelector];
#pragma clang disagnostic pop
		}
	}
}

- (void)removeAllAnimation {
	
	[self removeSubViews];
	if ([btnActionTarget respondsToSelector:btnClickSelector]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
		[btnActionTarget performSelector:btnClickSelector];
#pragma clang disagnostic pop
	}
}

- (UIBezierPath *)drawLoadingBezierPath {
	
	CGFloat radius = self.bounds.size.height * 0.5f - 3.0f;
	UIBezierPath *bezierPath = [UIBezierPath bezierPath];
	[bezierPath addArcWithCenter:CGPointMake(0, 0)
						  radius:radius
					  startAngle:M_PI_2
						endAngle:M_PI
					   clockwise:YES];
	return bezierPath;
}

- (void)removeSubViews {
	
	[button removeFromSuperview];
	[shapeLayer removeFromSuperlayer];
	[maskLayer removeFromSuperlayer];
	[loadingLayer removeFromSuperlayer];
	[circleLayer removeFromSuperlayer];
}

- (UIBezierPath *)drawCircleBezierPath:(CGFloat)radius {
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPath];
	[bezierPath addArcWithCenter:CGPointMake(0, 0)
						  radius:radius
					  startAngle:0
						endAngle:M_PI * 2.0f
					   clockwise:YES];
	
	return bezierPath;
}

- (UIBezierPath *)drawBezierPath:(CGFloat)x {
	
	CGFloat radius = self.bounds.size.height * 0.5f - 3.0f;
	CGFloat right = self.bounds.size.width - x;
	CGFloat left = x;
	
	UIBezierPath *bezierPath = [UIBezierPath bezierPath];
	bezierPath.lineJoinStyle = kCGLineJoinRound;
	bezierPath.lineCapStyle = kCGLineCapRound;
	[bezierPath addArcWithCenter:CGPointMake(right, self.bounds.size.height * 0.5f)
						  radius:radius
					  startAngle:-M_PI_2
						endAngle:M_PI_2
					   clockwise:YES];
	[bezierPath addArcWithCenter:CGPointMake(left, self.bounds.size.height * 0.5f)
						  radius:radius
					  startAngle:M_PI_2
						endAngle:-M_PI_2
					   clockwise:YES];
	[bezierPath closePath];
	return bezierPath;
}

@end
