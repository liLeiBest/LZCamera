//
//  LZModalPresentationTranslucentTransitioning.h
//  LZAddressPicker
//
//  Created by Dear.Q on 2021/3/1.
//

#import <Foundation/Foundation.h>
@class LZModalPresentationTranslucentTransitioning;

NS_ASSUME_NONNULL_BEGIN

/// 展示类型
typedef NS_ENUM(NSUInteger, LZModalPresentationType) {
    /// 显示
    LZModalPresentationTypeShow,
    /// 关闭
    LZModalPresentationTypeDismiss,
};

@protocol LZModalPresentationTranslucentTransitioningDelegate <NSObject>

/// 过渡动画中的内容视图
/// @param addressPickerTransition  LZModalPresentationTranslucentTransitioning
- (UIView *)contentViewInModalPresentationTranslucentTransitioning:(LZModalPresentationTranslucentTransitioning *)addressPickerTransition;

@end
@interface LZModalPresentationTranslucentTransitioning : NSObject<UIViewControllerAnimatedTransitioning>

/// 代理
@property (nonatomic, weak) id<LZModalPresentationTranslucentTransitioningDelegate> delegate;


/// 实例
/// @param type LZModalPresentationType
- (instancetype)initWithType:(LZModalPresentationType)type;

@end

NS_ASSUME_NONNULL_END
