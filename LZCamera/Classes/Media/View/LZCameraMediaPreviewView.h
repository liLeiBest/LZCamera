//
//  LZCameraMediaPreviewView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/19.
//

#import "LZCameraPreviewView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaPreviewView : LZCameraPreviewView

/** 单指单击聚集是否可用 */
@property (assign, nonatomic) BOOL singleTapToFocusEnable;
/** 单指双击曝光是否可用 */
@property (assign, nonatomic) BOOL doubleTapToExposeEnable;
/** 单指单击聚集回调 */
@property (copy, nonatomic) void(^TapToFocusAtPointHandler)(CGPoint point);
/** 单指双击曝光回调 */
@property (copy, nonatomic) void(^TapToExposeAtPointHandler)(CGPoint point);
/** 双指双击重设聚集和曝光回调 */
@property (copy, nonatomic) void(^TapToResetFocusAndExposure)(void);
/** 捏合缩放 */
@property (copy, nonatomic) void(^PinchToZoomHandler)(BOOL complete, BOOL magnify, CGFloat rampZoomValue);


/**
 人脸识别

 @param faces @[AVMetadataFaceObject]
 */
- (void)detectFaces:(NSArray<AVMetadataObject *> *)faces;

@end

NS_ASSUME_NONNULL_END
