//
//  UIImageView+LZTouchRect.h
//  LZCamera
//
//  Created by Dear.Q on 2019/8/2.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (LZTouchRect)

/** 点击区域扩展 */
@property (nonatomic, assign) UIEdgeInsets touchExtendInset;

@end

NS_ASSUME_NONNULL_END
