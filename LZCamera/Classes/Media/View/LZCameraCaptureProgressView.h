//
//  LZCameraCaptureProgressView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraCaptureProgressView : UIView

/** 进度 */
@property (assign, nonatomic) CGFloat progressValue;

/**
 清除进度
 */
- (void)clearProgress;

@end

NS_ASSUME_NONNULL_END
