//
//  LZCameraLoadingButton.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/30.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraLoadingButton : UIView

/** 标题样式 */
@property (nonatomic, copy) NSAttributedString *attributedTitle;
/** 边框颜色，默认 [UIColor blackColor] */
@property (nonatomic, strong) UIColor *shapeColor;
/** 点击圆圈颜色，默认 [UIColor blackColor] */
@property (nonatomic, strong) UIColor *circleColor;
/** 遮盖颜色，默认 [UIColor blackColor] */
@property (nonatomic, strong) UIColor *maskColor;
/** 加载颜色，默认 [UIColor blackColor] */
@property (nonatomic, strong) UIColor *loadColor;
/** 最短动画时间，默认 0 不限制 */
@property (nonatomic, assign) NSTimeInterval minAnimationTime;


/**
 实例方法
 
 @param title 		NSAttributedString
 @param shapColor 	边框颜色
 @param frame       Frame
 
 @return LZButton
 */
- (instancetype)initWithTitle:(NSAttributedString *)title
					shapColor:(UIColor *)shapColor
						frame:(CGRect)frame;

/**
 添加点击事件
 
 @param target        Target
 @param action        SEL
 */
- (void)addTarget:(id)target
		   action:(SEL)action;

/**
 结束动画
 */
- (void)animationFinish;

@end

NS_ASSUME_NONNULL_END
