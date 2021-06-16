//
//  LZCameraController.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/15.
//

#import <AVFoundation/AVFoundation.h>
#import "LZCameraDefine.h"
#import "LZCameraConfig.h"
#import "LZCameraControllerDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraController : NSObject

/** 代理 */
@property (weak, nonatomic) id<LZCameraControllerDelegate> delegate;
/** 图像捕捉会话 */
@property (strong, nonatomic, readonly) AVCaptureSession *captureSession;

/** 摄像头数目 */
@property (assign, nonatomic, readonly) NSUInteger cameraCount;
/** 是否有手电筒 */
@property (assign, nonatomic, readonly) BOOL cameraHasTorch;
/** 是否有闪光灯 */
@property (assign, nonatomic, readonly) BOOL cameraHasFlash;
/** 手电模式 */
@property (assign, nonatomic) AVCaptureTorchMode torchMode;
/** 闪光灯模式 */
@property (assign, nonatomic) AVCaptureFlashMode flashMode;

/** 是否支持特定区域对焦 */
@property (assign, nonatomic, readonly) BOOL cameraSupportTapToFocus;
/** 是否支持特定区域曝光 */
@property (assign, nonatomic, readonly) BOOL cameraSupportTapToExpose;

/** 是否支持缩放 */
@property (assign, nonatomic, readonly) BOOL cameraSupportZoom;
/** 缩放完成回调 */
@property (copy, nonatomic) LZCameraZoomCompletionHandler zoomCompletionHandler;

/** 捕捉元数据完成回调 */
@property (copy, nonatomic) LZCameraCaptureMetaDataCompletionHandler captureMetaDataCompletionHandler;


// MARK: - 实例
/**
 实例方法

 @return LZCameraController
 */
+ (instancetype)cameraController;

/**
 实例方法

 @param config LZCameraConfig
 @return LZCameraController
 */
+ (instancetype)cameraControllerWithConfig:(LZCameraConfig *)config;

// MARK: 配置会话
/**
 设置捕捉会话

 @param error NSError
 @return BOOL
 */
- (BOOL)setupSession:(NSError **)error;

/**
 启动会话
 */
- (void)startSession;

/**
 停止会话
 */
- (void)stopSession;

/**
 会话预设

 @return AVCaptureSessionPreset
 @remark 可以重写
 */
- (AVCaptureSessionPreset)sessionPreset;

/**
 设置会话输入

 @param error NSError
 @return BOOL
 @remark 可以重写
 */
- (BOOL)setupSessionInputs:(NSError **)error;

/**
 更新会话输入

 @param videoInput AVCaptureDeviceInput
 @return BOOL
 */
- (BOOL)updateSessionVideoInput:(AVCaptureDeviceInput *)videoInput;

/**
 设置会话输出
 
 @param error NSError
 @return BOOL
 @remark 可以重写
 */
- (BOOL)setupSessionOutputs:(NSError **)error;

// MARK: 切换摄像头、聚集、曝光、缩放
/**
 是否支持切换摄像头

 @return BOOL
 */
- (BOOL)canSwitchCameras;

/**
 切换摄像头

 @return BOOL
 */
- (BOOL)switchCameras;

/**
 手动聚集

 @param point CGPoint
 */
- (void)focusAtPoint:(CGPoint)point;

/**
 手动曝光

 @param point CGPoint
 */
- (void)exposeAtPoint:(CGPoint)point;

/**
 重新设置聚集和曝光
 */
- (void)resetFocusAndExposureMode;

/**
 设置缩放倍数
 */
- (void)setZoomValue:(CGFloat)zoomValue;

/**
 持续平滑缩放

 @param zoomValue CGFloat
 */
- (void)rampZoomValue:(CGFloat)zoomValue;

/**
 取消持续平滑缩放
 */
- (void)cancelRampingZoom;

// MARK: 拍照
/**
 捕捉静态图片
 
 @param completionHandler LZCameraCaptureStillImageCompletionHandler
 */
- (void)captureStillImage:(LZCameraCaptureStillImageCompletionHandler)completionHandler;

// MARK: 录像
/**
 开始录制视频

 @param completionHandler LZCameraCaptureVideoCompletionHandler
 */
- (void)startVideoRecording:(LZCameraCaptureVideoCompletionHandler)completionHandler;

/**
 停止录制视频
 */
- (void)stopVideoRecording;

/**
 是否正在录制视频

 @return BOOL
 */
- (BOOL)isVideoRecording;

/**
 当前视频录制的的持续时间

 @return CMTime
 @remark 此属性返回到目前为止记录的总时间。
 */
- (CMTime)videoRecordedDuration;

/**
 视频录制的时间进度

 @param progressHandler LZCameraRecordedDurationProgressHandler
 */
- (void)videoRecordedDurationWithProgress:(LZCameraRecordedDurationProgressHandler)progressHandler;

/**
 当前录制的视频文件大小

 @return int64_t
 @remark 单位:bytes，此属性返回当前记录的数据的字节大小。
 */
- (int64_t)videoRecordedFileSize;

// MARK: 捕捉元数据
/**
 捕捉元数据
 
 @param metaObjectTypes @[AVMetadataObjectType]
 @param completionHandler LZCameraCaptureMetaDataCompletionHandler
 */
- (void)captureMetaDataObjectWithTypes:(NSArray<AVMetadataObjectType> *)metaObjectTypes
                     completionHandler:(LZCameraCaptureMetaDataCompletionHandler)completionHandler;

// MARK: - 权限
/**
 是否有摄像头权限

 @return BOOL
 */
- (BOOL)grantCameraAuthority;

@end

NS_ASSUME_NONNULL_END
