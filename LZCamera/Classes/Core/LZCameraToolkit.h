//
//  LZCameraToolkit.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/19.
//

#import <Foundation/Foundation.h>
#import <Photos/Photos.h>
#import "LZCameraDefine.h"

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
 视频第一帧的缩略图（同步）
 
 @param videoURL NSURL
 */
+ (UIImage *)thumbnailAtFirstFrameForVideoAtURL:(NSURL *)videoURL;

/**
 按秒为视频生成缩略图（异步）

 @param asset 视频 AVAsset
 @param interval 时间间隔，单位为秒
 @param maxSize 缩略图的最大尺寸，强烈建议进行设置，可显著提高性别
 @param handler 完成回调
 @return AVAssetImageGenerator，注意强引用，会导致无法调用回调
 */
+ (AVAssetImageGenerator *)thumbnailBySecondForAsset:(AVAsset *)asset
											interval:(CMTimeValue)interval
											 maxSize:(CGSize)maxSize
								   completionHandler:(void (^ _Nullable)(NSArray<UIImage *> * _Nullable thumbnails))handler;

/**
 混合音频

 @param assetURL 视频原文件
 @param timeRange 时间范围
 @param audioPathURL 音频文件
 @param originalAudio 是否保留原始音频
 @param originalVolume 设置原始音频音量
 @param audioVolume 设置混合音频音量
 @param presetName 预设名称
 @param handler 完成回调
 */
+ (void)mixAudioForAsset:(NSURL *)assetURL
			   timeRange:(CMTimeRange)timeRange
			audioPathURL:(NSURL *)audioPathURL
		   originalAudio:(BOOL)originalAudio
		 originalVolume:(CGFloat)originalVolume
			 audioVolume:(CGFloat)audioVolume
			  presetName:(NSString *)presetName
	  completionHandler:(void (^)(NSURL * _Nullable outputFileURL, BOOL success))handler;

/**
 导出视频

 @param asset 视频 AVAsset
 @param timeRange 时间范围
 @param presetName 预设名称
 @param handler 完成回调
 @return AVAssetExportSession
 */
+ (AVAssetExportSession *)exportForAsset:(AVAsset *)asset
							   timeRange:(CMTimeRange)timeRange
							  presetName:(NSString *)presetName
					   completionHandler:(void (^)(NSURL *outputFileURL, BOOL success, NSError * _Nullable error))handler;

/**
 生成唯一的视频文件路径
 
 @return NSURL
 */
+ (NSURL *)generateUniqueMovieFileURL:(LZExportVideoType)videoType;

@end

NS_ASSUME_NONNULL_END
