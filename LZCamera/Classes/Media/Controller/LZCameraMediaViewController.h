//
//  LZCameraMediaViewController.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/22.
//

#import <UIKit/UIKit.h>
#import "LZCameraMediaDefine.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaViewController : UIViewController

/** 是否显示状态栏，默认 YES */
@property (assign, nonatomic) BOOL showStatusBar;
/** 是否显示状态栏里的闪光灯模式，默认 YES */
@property (assign, nonatomic) BOOL showFlashModeInStatusBar;
/** 是否显示状态栏里的摄像头切换，默认 YES */
@property (assign, nonatomic) BOOL showSwitchCameraInStatusBar;

/** 捕捉模式，默认是 LZCameraCaptureModelStillImageAndShortVideo */
@property (assign, nonatomic) LZCameraCaptureModel captureModel;
/** 短视频最长持续时间，单位：秒，默认 10 秒 */
@property (assign, nonatomic) CGFloat maxShortVideoDuration;
/** 短视频/长视频最短持续时间，单位：秒，默认 3 秒 */
@property (assign, nonatomic) CGFloat minVideoDuration;
/** 是否检测人脸，默认 NO */
@property (assign, nonatomic) BOOL detectFaces;

/** 是否自动保存到相册，默认：YES，自动存入相册 */
@property (assign, nonatomic) BOOL autoSaveToAlbum;

/** 拍摄图片完成回调 */
@property (copy, nonatomic) void(^CameraImageCompletionHandler)(UIImage *stillImage, PHAsset * _Nullable asset);
/** 拍摄视频完成回调 */
@property (copy, nonatomic) void(^CameraVideoCompletionHandler)(UIImage *thumbnailImage, NSURL *videoURL);


/**
 实例

 @return LZCameraMediaViewController
 */
+ (instancetype)instance;

@end

NS_ASSUME_NONNULL_END
