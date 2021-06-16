//
//  LZModalPresentationTranslucentTransitioning.m
//  LZAddressPicker
//
//  Created by Dear.Q on 2021/3/1.
//

#import "LZModalPresentationTranslucentTransitioning.h"

@interface LZModalPresentationTranslucentTransitioning()

@property (nonatomic, assign) enum LZModalPresentationType type;

@end
@implementation LZModalPresentationTranslucentTransitioning

// MARK: - Public
- (instancetype)initWithType:(LZModalPresentationType)type {
    if (self = [super init]) {
        self.type = type;
    }
    return self;
}

// MARK: - Delegate
// MARK: <UIViewControllerAnimatedTransitioning>
- (NSTimeInterval)transitionDuration:(nullable id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3f;
}

- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    if (LZModalPresentationTypeShow == self.type) {
        
        UIViewController *toVC = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
        UIView *toView = toVC.view;
        UIView *containerView = transitionContext.containerView;
        [containerView addSubview:toView];
        if ([self.delegate respondsToSelector:@selector(contentViewInModalPresentationTranslucentTransitioning:)]) {
            
            UIView *animationView = [self.delegate contentViewInModalPresentationTranslucentTransitioning:self];
            CGFloat animationViewHeight = animationView.frame.size.height;
            animationView.transform = CGAffineTransformMakeTranslation(0, animationViewHeight);
            [UIView animateWithDuration:0.25f animations:^{
                animationView.transform = CGAffineTransformMakeTranslation(0, -10);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.25f animations:^{
                    animationView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL finished) {
                    [transitionContext completeTransition:YES];
                }];
            }];
        }
    } else {
        if ([self.delegate respondsToSelector:@selector(contentViewInModalPresentationTranslucentTransitioning:)]) {
            
            UIView *animationView = [self.delegate contentViewInModalPresentationTranslucentTransitioning:self];
            [UIView animateWithDuration:0.25f animations:^{
                animationView.transform = CGAffineTransformMakeTranslation(0, animationView.frame.size.height);
            } completion:^(BOOL finished) {
                [transitionContext completeTransition:YES];
            }];
        }
    }
}

@end
