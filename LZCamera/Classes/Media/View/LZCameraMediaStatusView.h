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
/** 触摸关闭按钮回调 */
@property (copy, nonatomic) void(^TapToCloseCaptureHandler)(void);
/** 触摸闪光灯模式按钮回调 */
@property (copy, nonatomic) void(^TapToFlashModelHandler)(LZCameraFlashMode model);
/** 触摸摄像头切换按钮回调 */
@property (copy, nonatomic) void(^TapToSwitchCameraHandler)(void);


/**
 更新闪光灯可视状态

 @param state LZControlVisualState
 */
- (void)updateFlashVisualState:(LZControlVisualState)state;

/**
 更新摄像头切换可视状态
 
 @param state LZControlVisualState
 */
- (void)updateSwitchCameraVisualState:(LZControlVisualState)state;

/**
 更新时间进度

 @param durationTime CMTime
 */
- (void)updateDurationTime:(CMTime)durationTime;

@end

NS_ASSUME_NONNULL_END
