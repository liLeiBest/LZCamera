//
//  LZCameraCaptureLongVideoButton.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/27.
//

#import "LZCameraCaptureLongVideoButton.h"

@interface LZCameraCaptureLongVideoButton()
@property (strong, nonatomic) CALayer *circleLayer;
@end

@implementation LZCameraCaptureLongVideoButton

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupView];
}

// MARK: - Setter
- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    
    CABasicAnimation *fadeAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    fadeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    fadeAnimation.duration = 0.2f;
    if (highlighted) {
        fadeAnimation.toValue = @0.0f;
    } else {
        fadeAnimation.toValue = @1.0f;
    }
    self.circleLayer.opacity = [fadeAnimation.toValue floatValue];
    [self.circleLayer addAnimation:fadeAnimation forKey:@"fadeAnimation"];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    
    [CATransaction disableActions];
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    CABasicAnimation *radiusAnimation = [CABasicAnimation animationWithKeyPath:@"cornerRadius"];
    if (selected) {
        scaleAnimation.toValue = @0.6f;
        radiusAnimation.toValue = @(self.circleLayer.bounds.size.width / 4.0f);
    } else {
        scaleAnimation.toValue = @1.0f;
        radiusAnimation.toValue = @(self.circleLayer.bounds.size.width / 2.0f);
    }
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[scaleAnimation, radiusAnimation];
    animationGroup.beginTime = CACurrentMediaTime() + 0.2f;
    animationGroup.duration = 0.35f;
    
    [self.circleLayer setValue:radiusAnimation.toValue forKeyPath:@"cornerRadius"];
    [self.circleLayer setValue:scaleAnimation.toValue forKeyPath:@"transform.scale"];
    [self.circleLayer addAnimation:animationGroup forKey:@"scaleAndRadiusAnimation"];
}


- (void)drawRect:(CGRect)rect {
    
    static CGFloat lineW = 6.0f;
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextSetLineWidth(context, lineW);
    CGRect insetRect = CGRectInset(rect, lineW / 2.0f, lineW / 2.0f);
    CGContextStrokeEllipseInRect(context, insetRect);
}

// MARK: - Private
- (void)setupView {
    
    self.backgroundColor = [UIColor clearColor];
    self.tintColor = [UIColor clearColor];
    _circleLayer = [CALayer layer];
    _circleLayer.backgroundColor = [UIColor redColor].CGColor;
    _circleLayer.bounds = CGRectInset(self.bounds, 8.0, 8.0);
    _circleLayer.position = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    _circleLayer.cornerRadius = _circleLayer.bounds.size.width / 2.0f;
    [self.layer addSublayer:_circleLayer];
}


@end
