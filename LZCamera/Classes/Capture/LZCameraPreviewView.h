//
//  LZCameraPreviewView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/19.
//

#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraPreviewView : UIView

@property (strong, nonatomic) AVCaptureSession *captureSesstion;

/** 单指单击聚集是否可用 */
@property (assign, nonatomic) BOOL singleTapToFocusEnable;
/** 单指双击曝光是否可用 */
@property (assign, nonatomic) BOOL doubleTapToExposeEnable;
/** 单指单击聚集回调 */
@property (copy, nonatomic) void(^TappedToFocusAtPointHandler)(CGPoint point);
/** 单指双击曝光回调 */
@property (copy, nonatomic) void(^TappedToExposeAtPointHandler)(CGPoint point);
/** 双指双击重设聚集和曝光回调 */
@property (copy, nonatomic) void(^TappedToResetFocusAndExposure)(void);


/**
 人脸识别

 @param faces @[AVMetadataFaceObject]
 */
- (void)detectFaces:(NSArray<AVMetadataObject *> *)faces;

@end

NS_ASSUME_NONNULL_END
