//
//  LZCameraMediaStatusView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import <UIKit/UIKit.h>
#import <coremedia/CMTime.h>
#import "LZCameraMediaDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaStatusView : UIView

/** 捕捉模式 */
@property (assign, nonatomic) LZCameraCaptureModel captureModel;
/** 触摸闪光灯模式按钮回调 */
@property (copy, nonatomic) void(^TapToFlashModelHandler)(NSUInteger model);
/** 触摸摄像头切换按钮回调 */
@property (copy, nonatomic) void(^TapToSwitchCameraHandler)(void);


/**
 更新闪光灯可视状态

 @param state LZFlashVisualState
 */
- (void)updateFlashVisualState:(LZFlashVisualState)state;

/**
 更新时间进度

 @param durationTime CMTime
 */
- (void)updateDurationTime:(CMTime)durationTime;

@end

NS_ASSUME_NONNULL_END
