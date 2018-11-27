//
//  LZCameraDefine.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/21.
//

#ifndef LZCameraDefine_h
#define LZCameraDefine_h

/**
 错误码
 
 - LZCameraErrorFailedToAddInput: 添加输入失败
 - LZCameraErrorFailedToAddOutput: 添加输出失败
 - LZCameraErrorInvalideFileOutputURL: 文件输出路径无效
 - LZCameraErrorDiskFull: 储存空间满
 - LZCameraErrorSessionInterrupted: 被中断，比如：后台、电话、提醒
 */
typedef NS_ENUM(NSInteger, LZCameraErrorCode) {
    LZCameraErrorFailedToAddInput = 100001,
    LZCameraErrorFailedToAddOutput,
    LZCameraErrorInvalideFileOutputURL,
    LZCameraErrorDiskFull,
    LZCameraErrorSessionInterrupted
};

/** 错误域标识 */
FOUNDATION_EXPORT NSString * const LZCameraErrorDomain;
/** 捕捉静态图片完成回调 */
typedef void(^LZCameraCaptureStillImageCompletionHandler)(UIImage * _Nonnull stillImage, NSError * _Nullable error);
/** 捕捉视频完成回调 */
typedef void(^LZCameraCaptureVideoCompletionHandler)(NSURL * _Nonnull videoURL, UIImage * _Nullable thumbnail, NSError * _Nullable error);
/** 摄像缩放完成回调 */
typedef void(^ _Nullable LZCameraZoomCompletionHandler)(CGFloat zoomValue);
/** 摄像记录时间进度回调 */
typedef void(^LZCameraRecordedDurationProgressHandler)(CMTime duration);
/** 捕捉元数据完成回调 */
typedef void(^LZCameraCaptureMetaDataCompletionHandler)(NSArray<AVMetadataObject *> * _Nullable metadataObjects, NSError * _Nullable error);

#endif /* LZCameraDefine_h */
