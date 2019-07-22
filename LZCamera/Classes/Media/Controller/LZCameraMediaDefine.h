//
//  LZCameraMediaDefine.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/26.
//

#ifndef LZCameraMediaDefine_h
#define LZCameraMediaDefine_h

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
 控件的可视状态

 - LZControlVisualStateOn: 开
 - LZControlVisualStateOff: 关
 */
typedef NS_ENUM(NSUInteger, LZControlVisualState) {
    LZControlVisualStateOn,
    LZControlVisualStateOff,
};

/**
 闪光灯模式

 - LZCameraFlashModeOff: 开
 - LZCameraFlashModeOn: 关
 - LZCameraFlashModeAutu: 自动
 */
typedef NS_ENUM(NSUInteger, LZCameraFlashMode) {
	LZCameraFlashModeOff  = 0,
	LZCameraFlashModeOn   = 1,
	LZCameraFlashModeAuto = 2,
};

/**
 闪光灯控件的状态

 - LZCameraFlashControlWillExpand: 即将展开
 - LZCameraFlashControlDidExpand: 已经展开
 - LZCameraFlashControlWillCollapse: 即将折叠
 - LZCameraFlashControlDidCollaapse: 已经折叠
 */
typedef NS_ENUM(NSUInteger, LZCameraFlashControlState) {
	LZCameraFlashControlWillExpand,
	LZCameraFlashControlDidExpand,
	LZCameraFlashControlWillCollapse,
	LZCameraFlashControlDidCollaapse,
};

#endif /* LZCameraMediaDefine_h */
