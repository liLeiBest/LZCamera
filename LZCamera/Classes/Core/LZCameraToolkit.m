//
//  LZCameraToolkit.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/19.
//

#import "LZCameraToolkit.h"

/** 用于生成目录的模版 */
static NSString * const LZDirectoryTemplateString = @"lzcamera.XXXXXX";

@implementation LZCameraToolkit

// MARK: - Public
+ (void)saveImageToAblum:(UIImage *)image
	   completionHandler:(void (^ _Nullable)(PHAsset * _Nullable, NSError * _Nullable))handler {
	
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	switch (status) {
		case PHAuthorizationStatusDenied: {
			if (handler) {
				
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"PHAuthorizationStatusDenied"};
				NSError *error = [NSError errorWithDomain:LZCameraErrorDomain
													 code:LZCameraErrorAuthorization
												 userInfo:userInfo];
				handler(nil, error);
			}
		}
			break;
		case PHAuthorizationStatusRestricted: {
			if (handler) {
				
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"PHAuthorizationStatusRestricted"};
				NSError *error = [NSError errorWithDomain:LZCameraErrorDomain
													 code:LZCameraErrorAuthorization
												 userInfo:userInfo];
				handler(nil, error);
			}
		}
			break;
		default: {
			
			__block PHObjectPlaceholder *placeholderAsset = nil;
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				 
				PHAssetChangeRequest *assetChangeRequest =
				[PHAssetChangeRequest creationRequestForAssetFromImage:image];
				placeholderAsset = assetChangeRequest.placeholderForCreatedAsset;
			} completionHandler:^(BOOL success, NSError * _Nullable error) {
				
				if (NO == success) {
					if (handler) {
						handler(nil, error);
						return ;
					}
				}
				
				NSError *err = nil;
				PHAssetCollection *assetCollection = [self fetchDestinationCollection:&err];
				if (nil == assetCollection) {
					if (handler) {
						handler(nil, err);
						return ;
					}
				}
				PHAsset *asset = [self fetchAssetWithlocalIdentifier:placeholderAsset.localIdentifier];
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					
					PHAssetCollectionChangeRequest *collectionChangeRequest =
					[PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
					[collectionChangeRequest addAssets:@[asset]];
				} completionHandler:^(BOOL success, NSError * _Nullable error) {
					if (handler) {
						handler(asset, error);
					}
				}];
			}];
		}
			break;
	}
}

+ (void)saveVideoToAblum:(NSURL *)url
	   completionHandler:(LZCameraSaveAlbumCompletionHandler)handler {
	
	PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
	switch (status) {
		case PHAuthorizationStatusDenied: {
			if (handler) {
				
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"PHAuthorizationStatusDenied"};
				NSError *error = [NSError errorWithDomain:LZCameraErrorDomain
													 code:LZCameraErrorAuthorization
												 userInfo:userInfo];
				handler(nil, error);
			}
		}
			break;
		case PHAuthorizationStatusRestricted: {
			if (handler) {
				
				NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"PHAuthorizationStatusRestricted"};
				NSError *error = [NSError errorWithDomain:LZCameraErrorDomain
													 code:LZCameraErrorAuthorization
												 userInfo:userInfo];
				handler(nil, error);
			}
		}
			break;
		default: {
			
			__block PHObjectPlaceholder *placeholder = nil;
			[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
				
				PHAssetChangeRequest *assetRequest =
				[PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
				placeholder = assetRequest.placeholderForCreatedAsset;
			} completionHandler:^(BOOL success, NSError * _Nullable error) {
				
				if (NO == success) {
					if (handler) {
						handler(nil, error);
						return ;
					}
				}
				
				NSError *err = nil;
				PHAssetCollection *assetCollection = [self fetchDestinationCollection:&err];
				if (nil == assetCollection) {
					if (handler) {
						handler(nil, err);
					}
				}
				PHAsset *asset = [self fetchAssetWithlocalIdentifier:placeholder.localIdentifier];
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					
					PHAssetCollectionChangeRequest *collectionChangeRequest =
					[PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
					[collectionChangeRequest addAssets:@[asset]];
				} completionHandler:^(BOOL success, NSError * _Nullable error) {
					if (handler) {
						handler(asset ,error);
					}
				}];
			}];
		}
			break;
	}
}

/**
 生成视频缩略图
 
 @param videoURL NSURL
 */
+ (UIImage *)thumbnailAtFirstFrameForVideoAtURL:(NSURL *)videoURL {
	
	AVAsset *asset = [AVAsset assetWithURL:videoURL];
	AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
	imageGenerator.maximumSize = [UIScreen mainScreen].bounds.size;
	imageGenerator.appliesPreferredTrackTransform = YES;
	imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
	
	CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:NULL];
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return image;
}

+ (AVAssetImageGenerator *)thumbnailBySecondForAsset:(AVAsset *)asset
											interval:(CMTimeValue)interval
											 maxSize:(CGSize)maxSize
								   completionHandler:(void (^ _Nullable)(NSArray<UIImage *> * _Nullable))handler {
	
	AVAssetImageGenerator *assetImageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
	assetImageGenerator.maximumSize = maxSize;
	assetImageGenerator.appliesPreferredTrackTransform = YES;
	assetImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
	assetImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
	
	CMTime duratoin = asset.duration;
	CMTimeValue inrement = interval * duratoin.timescale;
	CMTimeValue timeCount = duratoin.value / inrement;
	NSMutableArray *times = [NSMutableArray array];
	for (CMTimeValue i = 0; i < timeCount; i ++) {
		
		CMTime time = CMTimeMake(i * inrement, duratoin.timescale);
		NSValue *timeValue = [NSValue valueWithCMTime:time];
		[times addObject:timeValue];
	}
	
	NSMutableArray *thumbnails = [NSMutableArray array];
	
	__block NSUInteger thumbnailCount = 0;
	AVAssetImageGeneratorCompletionHandler completionHandler = ^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
		
		switch (result) {
			case AVAssetImageGeneratorSucceeded: {
				
				UIImage *thumbnail = [UIImage imageWithCGImage:image];
				[thumbnails addObject:thumbnail];
			}
				break;
			case AVAssetImageGeneratorFailed:
			case AVAssetImageGeneratorCancelled: {
				LZCameraLog(@"%lu 张缩略图获取失败:%@", (unsigned long)thumbnailCount, error.localizedDescription);
			}
				break;
			default:
				break;
		}
		
		thumbnailCount ++;
		if (thumbnailCount == times.count && handler) {
			dispatch_async(dispatch_get_main_queue(), ^{
				handler(thumbnails);
			});
		}
	};
	[assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:completionHandler];
	
	return assetImageGenerator;
}

+ (void)mixAudioForAsset:(NSURL *)assetURL
			   timeRange:(CMTimeRange)timeRange
			audioPathURL:(NSURL *)audioPathURL
		   originalAudio:(BOOL)originalAudio
		  originalVolume:(CGFloat)originalVolume
			 audioVolume:(CGFloat)audioVolume
			  presetName:(NSString *)presetName
	   completionHandler:(void (^)(NSURL * _Nullable, BOOL))handler {
	
	AVAsset *asset = [AVAsset assetWithURL:assetURL];
	NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
	if (0 == videoAssetTracks.count) {
		if (handler) {
			handler(assetURL, NO);
		}
		return;
	}
	AVAssetTrack *videoAssetTrack = [videoAssetTracks firstObject];
	if (CMTIMERANGE_IS_EMPTY(timeRange)) {
		
		CMTime duration = asset.duration;
		timeRange = CMTimeRangeMake(kCMTimeZero, duration);
	}
	AVMutableComposition *composition = [AVMutableComposition composition];
	AVMutableCompositionTrack *videoCompositionTrack =
	[composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
	NSError *error = nil;
	[videoCompositionTrack insertTimeRange:timeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
	if (error) {
		LZCameraLog(@"音乐合成-添加视频失败:%@", error);
	}
	
	AVAsset *audioAsset = [AVAsset assetWithURL:audioPathURL];
	AVAssetTrack *audioAssetTrack = nil;
	NSArray *audioAssetTracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
	if (0 < audioAssetTracks.count) {
		audioAssetTrack = [audioAssetTracks firstObject];
	}
	AVMutableCompositionTrack *audioCompositionTrack = nil;
	if (audioAssetTrack) {
		
		audioCompositionTrack =
		[composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
		[audioCompositionTrack insertTimeRange:timeRange ofTrack:audioAssetTrack atTime:kCMTimeZero error:&error];
		//	audioCompositionTrack.preferredVolume = audioVolume;
		if (error) {
			LZCameraLog(@"音乐合成-添加背景音失败:%@", error);
		}
	}
	
	AVMutableCompositionTrack *originalAudioCompositionTrack = nil;
	if (originalAudio) {
		
		NSArray *audioAssetTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
		if (0 < audioAssetTracks.count) {
			
			AVAssetTrack *originalAudioAssetTrack = [audioAssetTracks firstObject];
			originalAudioCompositionTrack =
			[composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
			[originalAudioCompositionTrack insertTimeRange:timeRange ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:&error];
			//	originalAudioCompositionTrack.preferredVolume = originalVolume;
			if (error) {
				LZCameraLog(@"音乐合成-添加原音失败:%@", error);
			}
		}
	}
	
	CGFloat degree = [self getVideoDegree:videoAssetTrack];
	CGSize naturalSize = videoAssetTrack.naturalSize;
	CGSize renderSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
	
	CGAffineTransform mixedTransform =  CGAffineTransformIdentity;
	CGFloat videoWidth = (degree == 0 || degree == M_PI) ? naturalSize.width : naturalSize.height;
	CGFloat videoHeight = (degree == 0 || degree == M_PI) ? naturalSize.height : naturalSize.width;
	CGSize cropSize = CGSizeMake(MIN(videoWidth, renderSize.width), MIN(videoHeight, renderSize.height));
	CGFloat x, y;
	if (degree == M_PI_2) {
		// 顺时针 90°
		CGAffineTransform t = CGAffineTransformMakeTranslation(naturalSize.height,.0);
		CGAffineTransform t1 = CGAffineTransformRotate(t, M_PI_2);
		// x为正向下 y为正向左
		x = -(videoHeight-cropSize.height) / 2.0;
		y = (videoWidth-cropSize.width) / 2.0;
		mixedTransform = CGAffineTransformTranslate(t1, x, y);
	} else if (degree == M_PI) {
		// 顺时针 180°
		CGAffineTransform t = CGAffineTransformMakeTranslation(naturalSize.width, naturalSize.height);
		CGAffineTransform t1 = CGAffineTransformRotate(t, M_PI);
		// x为正向左 y为正向上
		x = (videoWidth-cropSize.width) / 2.0;
		y = (videoHeight-cropSize.height) / 2.0;
		mixedTransform = CGAffineTransformTranslate(t1, x, y);
	} else if (degree == (M_PI_2 * 3.0)) {
		// 顺时针 270°
		CGAffineTransform t = CGAffineTransformMakeTranslation(.0, naturalSize.width);
		CGAffineTransform t1 = CGAffineTransformRotate(t, M_PI_2 * 3.0);
		// x为正向上 y为正向右
		x = (videoHeight-cropSize.height) / 2.0;
		y = -(videoWidth-cropSize.width) / 2.0;
		mixedTransform = CGAffineTransformTranslate(t1, x, y);
	} else if (degree == 1) {
		// 前摄像头的情况
		CGAffineTransform transform = CGAffineTransformMakeScale(-1.0, 1.0);
		transform = CGAffineTransformRotate(transform, M_PI / 2.0);
		x = -(videoHeight-cropSize.height) / 2.0;
		y = (videoWidth-cropSize.width) / 2.0;
		mixedTransform = CGAffineTransformTranslate(transform, x, y);
	} else {
		// x为正向右 y为正向下
		x = -(videoWidth-cropSize.width) / 2.0;
		y = -(videoHeight-cropSize.height) / 2.0;
		mixedTransform = CGAffineTransformMakeTranslation(x, y);
	}
	
	AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoAssetTrack];
	[layerInstruction setOpacity:0.0 atTime:videoAssetTrack.timeRange.duration];
	[layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
	
	AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	instruction.layerInstructions = @[layerInstruction];
	
	// 管理所有需要处理的视频
	AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
	videoComposition.frameDuration = CMTimeMake(1, 30);
	videoComposition.renderScale = 1.0;
	videoComposition.renderSize = cropSize;
	videoComposition.instructions = @[instruction];
	
	AVAudioMix *audioMix = nil;
	if (originalAudioCompositionTrack && audioCompositionTrack) {
		audioMix = [self buildAudioMixWithVideoTrack:originalAudioCompositionTrack originalVolume:originalVolume audioTrack:audioCompositionTrack audioVolume:audioVolume atTime:kCMTimeZero];
	}
	
	[self exportForAsset:composition videoComposition:videoComposition audioMix:audioMix timeRange:timeRange presetName:presetName completionHandler:^(NSURL * _Nonnull outputFileURL, BOOL success, NSError * _Nullable error) {
		if (handler) {
			
			if (error) {
				LZCameraLog(@"音乐合成失败:%@", error);
			}
			handler(outputFileURL, success);
		}
	}];
}

+ (AVAssetExportSession *)exportForAsset:(AVAsset *)asset
							   timeRange:(CMTimeRange)timeRange
							  presetName:(NSString *)presetName
					   completionHandler:(void (^)(NSURL * _Nonnull, BOOL success, NSError * _Nullable))handler {
	return [self exportForAsset:asset
			   videoComposition:nil
					   audioMix:nil
					  timeRange:timeRange
					 presetName:presetName
			  completionHandler:handler];
}

+ (NSURL *)generateUniqueMovieFileURL:(LZExportVideoType)videoType {
	
	NSString *mkdTemplate = [NSTemporaryDirectory() stringByAppendingPathComponent:LZDirectoryTemplateString];
	const char *templateCString = [mkdTemplate fileSystemRepresentation];
	char *buffer = malloc(strlen(templateCString) + 1);
	strcpy(buffer, templateCString);
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSString *directoryPath = nil;
	char *result = mkdtemp(buffer);
	if (result) {
		directoryPath = [fileManager stringWithFileSystemRepresentation:buffer length:strlen(result)];
	}
	free(buffer);
	
	if (directoryPath) {
		
		NSString *filePath = [directoryPath stringByAppendingPathComponent:@"lacamera_movie.mov"];
		NSString *format = (videoType == LZExportVideoTypeMov ? @"mov" : @"mp4");
		filePath = [filePath stringByAppendingFormat:@".%@", format];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		return fileURL;
	}
	return nil;
}

// MARK: - Private
+ (PHAsset *)fetchAssetWithlocalIdentifier:(NSString *)localIdentifier {
	
	if(localIdentifier == nil){
		LZCameraLog(@"localIdentifier can be nil");
		return nil;
	}
	PHFetchResult *result = [PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil];
	if(result.count){
		return result[0];
	}
	return nil;
}

+ (PHAssetCollection *)fetchDestinationCollection:(NSError **)error {
	
	NSString *appName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleDisplayName"];
	if (nil == appName || 0 == appName.length) {
		appName = [[NSBundle mainBundle].infoDictionary objectForKey:@"CFBundleName"];
	}
	
	PHFetchResult<PHAssetCollection *> *collectionResult =
	[PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
											 subtype:PHAssetCollectionSubtypeAlbumRegular
											 options:nil];
	for (PHAssetCollection *collection in collectionResult) {
		if ([collection.localizedTitle isEqualToString:appName]) {
			return collection;
		}
	}
	__block NSString *collectionId = nil;
	[[PHPhotoLibrary sharedPhotoLibrary] performChangesAndWait:^{
		
		PHAssetCollectionChangeRequest *collectionChangeRequest =
		[PHAssetCollectionChangeRequest creationRequestForAssetCollectionWithTitle:appName];
		collectionId = collectionChangeRequest.placeholderForCreatedAssetCollection.localIdentifier;
	} error:error];
	if (error) {
		LZCameraLog(@"创建相册失败：%@", appName);
		return nil;
	}
	PHAssetCollection *assetCollection =
	[[PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil]
	 lastObject];
	return assetCollection;
}

+ (AVAssetExportSession *)exportForAsset:(AVAsset *)asset
						videoComposition:(AVVideoComposition *)videoComposition
								audioMix:(AVAudioMix *)audioMix
							   timeRange:(CMTimeRange)timeRange
							  presetName:(NSString *)presetName
					   completionHandler:(void (^)(NSURL * _Nonnull, BOOL success, NSError * _Nullable))handler {
	
	NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
	if (NO == [compatiblePresets containsObject:presetName]) {
		presetName = AVAssetExportPresetMediumQuality;
	}
	
	AVAssetExportSession *exportSession =
	[[AVAssetExportSession alloc] initWithAsset:asset presetName:presetName];
	NSURL *fileURL = [self generateUniqueMovieFileURL:LZExportVideoTypeMov];
	exportSession.outputURL = fileURL;
	exportSession.shouldOptimizeForNetworkUse = true;
	exportSession.outputFileType = AVFileTypeQuickTimeMovie;
	exportSession.timeRange = timeRange;
	if (videoComposition) {
		exportSession.videoComposition = videoComposition;
	}
	if (audioMix) {
		exportSession.audioMix = audioMix;
	}
	
	__block BOOL success = NO;
	__block BOOL finish = NO;
	[exportSession exportAsynchronouslyWithCompletionHandler:^{
		switch (exportSession.status) {
			case AVAssetExportSessionStatusCompleted:
				success = YES;
				finish = YES;
				LZCameraLog(@"Export success");
				break;
			case AVAssetExportSessionStatusFailed:
				finish = YES;
				LZCameraLog(@"Export failed");
				break;
			case AVAssetExportSessionStatusCancelled:
				finish = YES;
				LZCameraLog(@"Export cancelled");
				break;
			case AVAssetExportSessionStatusWaiting:
				LZCameraLog(@"Export waiting");
				break;
			case AVAssetExportSessionStatusExporting:
				LZCameraLog(@"Export exporting");
				break;
			case AVAssetExportSessionStatusUnknown:
				LZCameraLog(@"Export unknown");
				break;
			default:
				break;
		}
		if (handler && YES == finish) {
			dispatch_async(dispatch_get_main_queue(), ^{
				handler(fileURL, success, exportSession.error);
			});
		}
	}];
	return exportSession;
}

+ (AVAudioMix *)buildAudioMixWithVideoTrack:(AVCompositionTrack *)videoTrack
							 originalVolume:(CGFloat)originalVolume
								 audioTrack:(AVCompositionTrack *)audioTrack
								audioVolume:(CGFloat)audioVolume
									 atTime:(CMTime)time {
	
	AVMutableAudioMixInputParameters *originalMixInputParameters =
	[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:videoTrack];
	[originalMixInputParameters setVolume:originalVolume atTime:time];
	AVMutableAudioMixInputParameters *audioMixInputParameters =
	[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
	[audioMixInputParameters setVolume:audioVolume atTime:time];
	
	AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
	audioMix.inputParameters = @[originalMixInputParameters, audioMixInputParameters];
	return audioMix;
}

+ (CGFloat)getVideoDegree:(AVAssetTrack *)videoTrack {
	
	CGAffineTransform tf = videoTrack.preferredTransform;
	CGFloat degree = 0;
	if (tf.b == 1.0 && tf.c == -1.0) {
		degree = M_PI_2;
	} else if (tf.a == -1.0 && tf.d == -1.0) {
		degree = M_PI;
	} else if (tf.b == -1.0 && tf.c == 1.0) {
		degree = M_PI_2 * 3;
	} else if (tf.a == 1.0 && tf.d == 1.0) {
		degree = 0;
	} else {
		degree = 1;
	}
	return degree;
}

@end
