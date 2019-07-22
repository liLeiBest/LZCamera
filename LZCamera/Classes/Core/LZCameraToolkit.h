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


/**
 按秒为视频生成缩略图

 @param asset 视频 AVAsset
 @param interval 时间间隔，单位为秒
 @param maxSize 缩略图的最大尺寸，强烈建议进行设置，可显著提高性别
 @param handler 完成回调
 @return AVAssetImageGenerator，注意强引用，会导致无法调用回调
 */
+ (AVAssetImageGenerator *)thumbnailBySecondForAsset:(AVAsset *)asset
											interval:(CMTimeValue)interval
											 maxSize:(CGSize)maxSize
								   completionHandler:(void (^ _Nullable)(AVAsset * _Nullable asset, NSArray<UIImage *> * _Nullable thumbnails))handler;

@end

NS_ASSUME_NONNULL_END
