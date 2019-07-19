//
//  LZCameraToolkit.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/19.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>

NS_ASSUME_NONNULL_BEGIN

/** 保存到相册回调 */
typedef void (^LZCameraSaveAlbumCompletionHandler)(PHAsset * _Nullable asset, NSError * _Nullable error);

@interface LZCameraToolkit : NSObject

/**
 保存图片到相册
 
 @param image 图片
 @param handler 完成回调，不一定在主线程
 */
+ (void)saveImageToAblum:(UIImage *)image
	   completionHandler:(LZCameraSaveAlbumCompletionHandler _Nullable)handler;

/**
 保存视频到相册
 
 @param url 视频地址
 @param handler 完成回调，不一定在主线程
 */
+ (void)saveVideoToAblum:(NSURL *)url
	   completionHandler:(LZCameraSaveAlbumCompletionHandler _Nullable)handler;

@end

NS_ASSUME_NONNULL_END
