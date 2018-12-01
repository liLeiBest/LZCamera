//
//  LZCameraCaptureFlashControl.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/27.
//

#import <UIKit/UIKit.h>
#import "LZCameraMediaDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraCaptureFlashControl : UIControl

/** 点击闪光模式回调 */
@property (copy, nonatomic) void(^TapToFlashModeHandler)(LZCameraFlashMode flashMode);
/** 状态回调 */
@property (copy, nonatomic) void(^FlashControlStatusHandler)(LZCameraFlashControlState state);
@property (assign, nonatomic) LZCameraFlashMode selectedMode;

@end

NS_ASSUME_NONNULL_END
