//
//  LZCameraMediaDefine.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/26.
//

#ifndef LZCameraMediaDefine_h
#define LZCameraMediaDefine_h

#import <AVFoundation/AVFoundation.h>

/**
 摄像头捕捉类型

 - LZCameraCaptureModeStillImage: 图片
 - LZCameraCaptureModelShortVideo: 短视频
 - LZCameraCaptureModelStillImageAndShortVideo: 图片或短视频
 - LZCameraCaptureModelLongVideo: 长视频
 */
typedef NS_ENUM(NSUInteger, LZCameraCaptureModel) {
    LZCameraCaptureModeStillImage,
    LZCameraCaptureModelShortVideo,
    LZCameraCaptureModelStillImageAndShortVideo,
    LZCameraCaptureModelLongVideo,
};

/**
 闪光灯的可视状态

 - LZFlashVisualStateOn: 开
 - LZFlashVisualStateOff: 关
 */
typedef NS_ENUM(NSUInteger, LZFlashVisualState) {
    LZFlashVisualStateOn,
    LZFlashVisualStateOff,
};

#endif /* LZCameraMediaDefine_h */
