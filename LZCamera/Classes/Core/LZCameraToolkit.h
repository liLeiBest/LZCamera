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

 @param assetURL 视频资源地址
 @param interval 时间间隔，单位为秒
 @param maxSize 缩略图的最大尺寸，强烈建议进行设置，可显著提高性别
 @param progressHandler 解析进度回调，缩略图数量递增，直至所有
 @param completionHandler 解析完成回调，包含所有缩略图
 @return AVAssetImageGenerator，注意强引用，会导致无法调用回调
 */
+ (AVAssetImageGenerator *)thumbnailBySecondForVideoAsset:(NSURL *)assetURL
												 interval:(CMTimeValue)interval
												  maxSize:(CGSize)maxSize
										  progressHandler:(void (^ _Nullable)(NSArray<UIImage *> * _Nullable thumbnails, CGFloat progress))progressHandler
								   		completionHandler:(void (^ _Nullable)(NSArray<UIImage *> * _Nullable thumbnails))completionHandler;

/**
 裁剪资源

 @param assetURL 资源地址
 @param type 资源类型
 @param timeRange 裁剪区间，如是传 kCMTimeRangeZero 
 @param completionHandler 完成回调
 @return AVAssetExportSession
 */
+ (AVAssetExportSession *)cutAsset:(NSURL *)assetURL
							  type:(LZCameraAssetType)type
						  timeRane:(CMTimeRange)timeRange
				 completionHandler:(void (^ _Nullable)(NSURL * _Nullable outputFileURL, BOOL success))completionHandler;

/**
 导出视频资源

 @param assetURL 资源地址
 @param presetName 预设名称
 @param completionHandler 完成回调
 @return AVAssetExportSession
 */
+ (AVAssetExportSession *)exportVideoAsset:(NSURL *)assetURL
								presetName:(NSString *)presetName
						 completionHandler:(void (^ _Nullable)(NSURL * _Nullable outputFileURL, BOOL success))completionHandler;

/**
 混合音频

 @param assetURL 视频原文件
 @param timeRange 时间范围
 @param audioPathURL 音频文件
 @param originalAudio 是否保留原始音频
 @param originalVolume 设置原始音频音量
 @param audioVolume 设置混合音频音量
 @param presetName 预设名称
 @param completionHandler 完成回调
 @return AVAssetExportSession
 */
+ (AVAssetExportSession *)mixAudioForAsset:(NSURL *)assetURL
								 timeRange:(CMTimeRange)timeRange
							  audioPathURL:(NSURL *)audioPathURL
							 originalAudio:(BOOL)originalAudio
							originalVolume:(CGFloat)originalVolume
							   audioVolume:(CGFloat)audioVolume
								presetName:(NSString *)presetName
						 completionHandler:(void (^ _Nullable)(NSURL * _Nullable outputFileURL, BOOL success))completionHandler;

/**
 水印

 @param assetURL 视频原文件
 @param watermarkText 水印文本
 @param textLocation 文本位置
 @param watermarkImage 水印图片
 @param imageLocation 图片位置
 @param completionHandler 完成回调
 @return AVAssetExportSession
 */
+ (AVAssetExportSession *)watermarkForVideoAsset:(NSURL *)assetURL
								   watermarkText:(NSAttributedString * _Nullable)watermarkText
									textLocation:(LZCameraWatermarkLocation)textLocation
								  watermarkImage:(UIImage * _Nullable)watermarkImage
								   imageLocation:(LZCameraWatermarkLocation)imageLocation
							   completionHandler:(void (^ _Nullable)(NSURL * _Nullable outputFileURL, BOOL success))completionHandler;

/**
 生成唯一的视频文件路径
 
 @return NSURL
 */
+ (NSURL *)generateUniqueAssetFileURL:(LZCameraAssetType)assetType;

/**
 删除文件
 
 @param fileURL 文件地址
 @return BOOL
 */
+ (BOOL)deleteFile:(NSURL *)fileURL;

/**
 获取文件大小
 
 @param filePath 文件路径
 @return NSString 文件不存在时，返回 nil
 */
+ (NSString * _Nullable)sizeForFile:(NSString *)filePath;

/**
 获取图片对象的大小
 
 @param image UIImage
 @return NSString
 */
+ (NSString *)sizeForImage:(UIImage *)image;

@end

NS_ASSUME_NONNULL_END
