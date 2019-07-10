//
//  LZCameraMediaModelView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import <UIKit/UIKit.h>
#import "LZCameraMediaDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaModelView : UIView

/** 捕捉模式 */
@property (assign, nonatomic) LZCameraCaptureModel captureModel;
/** 短时间最长持续时间 */
@property (assign, nonatomic) CGFloat maxDuration;
/** 触摸拍摄图片按钮回调 */
@property (copy, nonatomic) void(^TapToCaptureImageHandler)(void(^ComplteHandler)(void));
/** 触摸拍摄视频按钮回调 */
@property (copy, nonatomic) void(^TapToCaptureVideoHandler)(BOOL began, BOOL end, void(^ComplteHandler)(void));
/** 触摸拍摄视频取消按钮回调 */
@property (copy, nonatomic) void(^TapToCaptureVideoCancelHandler)(void);


/**
 更新时间进度
 
 @param durationTime CMTime
 */
- (void)updateDurationTime:(CMTime)durationTime;

@end

NS_ASSUME_NONNULL_END
