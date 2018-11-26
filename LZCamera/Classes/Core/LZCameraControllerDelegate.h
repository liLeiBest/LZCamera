//
//  LZCameraControllerDelegate.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol LZCameraControllerDelegate <NSObject>

/**
 摄像头配置失败回调

 @param error NSError
 */
- (void)cameraConfigurationFailWithError:(NSError *)error;

/**
 摄像头捕捉失败回调

 @param error NSError
 */
- (void)cameraCaptureFailedWithError:(NSError *)error;

/**
 相册写入失败回调

 @param error NSError
 */
- (void)photosAlbumWriteFailedWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END
