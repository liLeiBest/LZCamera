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
/** 短时间持续时间 */
@property (assign, nonatomic) NSInteger maxDuration;
/** 触摸取消按钮回调 */
@property (copy, nonatomic) void(^TapToCancelCaptureHandler)(void);
/** 触摸拍摄图片按钮回调 */
@property (copy, nonatomic) void(^TapToCaptureImageHandler)(void(^ComplteHandler)(void));
/** 触摸拍摄视频按钮回调 */
@property (copy, nonatomic) void(^TapToCaptureVideoHandler)(BOOL began, BOOL end, void(^ComplteHandler)(void));

@end

NS_ASSUME_NONNULL_END
