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
	
    PHAuthorizationStatus status = PHAuthorizationStatusRestricted;
    if (@available(iOS 14, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    } else {
        status = [PHPhotoLibrary authorizationStatus];
    }
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
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (NO == success) {
                        if (handler) {
                            handler(nil, error);
                        }
                        return ;
                    } else {
                        
                        PHAsset *asset = [self fetchAssetWithlocalIdentifier:placeholderAsset.localIdentifier];
                        if (handler) {
                            handler(asset, nil);
                        }
                    }
                });
                return;
				NSError *err = nil;
				PHAssetCollection *assetCollection = [self fetchDestinationCollection:&err];
				if (nil == assetCollection) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler) {
                            handler(nil, err);
                        }
                    });
                    return;
				}
				PHAsset *asset = [self fetchAssetWithlocalIdentifier:placeholderAsset.localIdentifier];
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					
					PHAssetCollectionChangeRequest *collectionChangeRequest =
					[PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
					[collectionChangeRequest addAssets:@[asset]];
				} completionHandler:^(BOOL success, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler) {
                            handler(asset, error);
                        }
                    });
				}];
			}];
		}
			break;
	}
}

+ (void)saveVideoToAblum:(NSURL *)url
	   completionHandler:(LZCameraSaveAlbumCompletionHandler)handler {
	
    PHAuthorizationStatus status = PHAuthorizationStatusRestricted;
    if (@available(iOS 14, *)) {
        status = [PHPhotoLibrary authorizationStatusForAccessLevel:PHAccessLevelReadWrite];
    } else {
        status = [PHPhotoLibrary authorizationStatus];
    }
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
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler) {
                            handler(nil, error);
                        }
                    });
                    return ;
				}
				NSError *err = nil;
				PHAssetCollection *assetCollection = [self fetchDestinationCollection:&err];
				if (nil == assetCollection) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler) {
                            handler(nil, err);
                        }
                        return;
                    });
				}
				PHAsset *asset = [self fetchAssetWithlocalIdentifier:placeholder.localIdentifier];
				[[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
					
					PHAssetCollectionChangeRequest *collectionChangeRequest =
					[PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
					[collectionChangeRequest addAssets:@[asset]];
				} completionHandler:^(BOOL success, NSError * _Nullable error) {
					dispatch_async(dispatch_get_main_queue(), ^{
                        if (handler) {
                            handler(asset ,error);
                        }
                    });
				}];
			}];
		}
			break;
	}
}

+ (UIImage *)thumbnailAtFirstFrameForVideoAtURL:(NSURL *)videoURL {
	
	AVAsset *asset = [AVAsset assetWithURL:videoURL];
	AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
	imageGenerator.maximumSize = [UIScreen mainScreen].bounds.size;
	imageGenerator.appliesPreferredTrackTransform = YES;
	imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    NSError *error = nil;
	CGImageRef imageRef = [imageGenerator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:&error];
    if (nil == imageRef) {
        LZCameraLog(@"获取视频缩略图失败:%@", error.localizedDescription);
        return nil;
    }
	UIImage *image = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	return image;
}

+ (AVAssetImageGenerator *)thumbnailBySecondForVideoAsset:(NSURL *)assetURL
												 interval:(CMTimeValue)interval
												  maxSize:(CGSize)maxSize
										  progressHandler:(void (^ _Nullable)(NSArray<UIImage *> * _Nullable, CGFloat))progressHandler
								   		completionHandler:(void (^ _Nullable)(NSArray<UIImage *> * _Nullable))completionHandler {
	
	AVAsset *asset = asset = [AVAsset assetWithURL:assetURL];
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
	AVAssetImageGeneratorCompletionHandler generatorHandler = ^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
		
		switch (result) {
			case AVAssetImageGeneratorSucceeded: {
				
				UIImage *thumbnail = [UIImage imageWithCGImage:image];
				[thumbnails addObject:thumbnail];
			}
				break;
			case AVAssetImageGeneratorFailed: {
				LZCameraLog(@"第 %lu 张缩略图获取失败:%@", (unsigned long)thumbnailCount, error.localizedDescription);
			}
				break;
			case AVAssetImageGeneratorCancelled: {
				LZCameraLog(@"取消缩略图生成");
			}
				break;
			default:
				break;
		}
		
		if (progressHandler) {
			
			CGFloat progress = thumbnails.count * 1.0f / times.count;
			LZCameraLog(@"视频缩略图生成进度:%f", progress);
			dispatch_async(dispatch_get_main_queue(), ^{
				progressHandler(thumbnails, progress);
			});
		}
		thumbnailCount ++;
		if (thumbnailCount == times.count) {
			if (completionHandler) {
				dispatch_async(dispatch_get_main_queue(), ^{
					completionHandler(thumbnails);
				});
			}
		}
	};
	[assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:generatorHandler];
	return assetImageGenerator;
}

+ (AVAssetExportSession *)cutAsset:(NSURL *)assetURL
							  type:(LZCameraAssetType)type
						  timeRane:(CMTimeRange)timeRange
				 completionHandler:(void (^ _Nullable)(NSURL * _Nullable, BOOL))completionHandler {
	
	AVAsset *asset = [AVAsset assetWithURL:assetURL];
	if (CMTimeRangeEqual(timeRange, kCMTimeRangeZero)) {
		timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	}
	return [self exportAsset:asset
						type:type
			videoComposition:nil
					audioMix:nil
				   timeRange:timeRange
				  presetName:nil
		   completionHandler:^(NSURL * _Nonnull outputFileURL, BOOL success, NSError * _Nullable error) {
			   if (completionHandler) {
				   completionHandler(outputFileURL, success);
			   }
		   }];
}

+ (AVAssetExportSession *)exportVideoAsset:(NSURL *)assetURL
								presetName:(NSString *)presetName
						 completionHandler:(void (^ _Nullable)(NSURL * _Nullable, BOOL))completionHandler {
	
	AVAsset *asset = asset = [AVAsset assetWithURL:assetURL];
	return [self exportAsset:asset
						type:LZCameraAssetTypeMp4
			videoComposition:nil
					audioMix:nil
				   timeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
				  presetName:presetName
		   completionHandler:^(NSURL * _Nonnull outputFileURL, BOOL success, NSError * _Nullable error) {
			   if (completionHandler) {
				   completionHandler(outputFileURL, success);
			   }
		   }];
}

+ (AVAssetExportSession *)mixAudioForAsset:(NSURL *)assetURL
								 timeRange:(CMTimeRange)timeRange
							  audioPathURL:(NSURL *)audioPathURL
							 originalAudio:(BOOL)originalAudio
							originalVolume:(CGFloat)originalVolume
							   audioVolume:(CGFloat)audioVolume
								presetName:(NSString *)presetName
						 completionHandler:(void (^ _Nullable)(NSURL * _Nullable, BOOL))completionHandler {
	
	AVAsset *asset = [AVAsset assetWithURL:assetURL];
	AVMutableComposition *composition =
	[self composingAudioToAsset:asset
					  timeRange:timeRange
					   audioURL:audioPathURL
					   mixAudio:originalAudio
				 originalVolume:originalVolume
					audioVolume:audioVolume];
	
	AVMutableVideoComposition *videoComposition =
	[self videoCompositionWithComposition:composition asset:asset];
	
	AVAudioMix *audioMix = nil;
	if (originalAudio) {
		
		NSArray *audioCompositionTracks = [composition tracksWithMediaType:AVMediaTypeAudio];
		if (1 < audioCompositionTracks.count) {
			audioMix = [self audioMixWithAudioCompositionTracks:audioCompositionTracks
												 originalVolume:originalVolume
													audioVolume:audioVolume
														 atTime:kCMTimeZero];
		}
	}
	
	return [self exportAsset:composition
						type:LZCameraAssetTypeMov
			videoComposition:videoComposition
					audioMix:audioMix
				   timeRange:timeRange
				  presetName:presetName
		   completionHandler:^(NSURL * _Nonnull outputFileURL, BOOL success, NSError * _Nullable error) {
			   if (completionHandler) {
				   completionHandler(outputFileURL, success);
			   }
		   }];
}

+ (AVAssetExportSession *)watermarkForVideoAsset:(NSURL *)assetURL
								   watermarkText:(NSAttributedString * _Nullable)watermarkText
									textLocation:(LZCameraWatermarkLocation)textLocation
								  watermarkImage:(UIImage * _Nullable)watermarkImage
								   imageLocation:(LZCameraWatermarkLocation)imageLocation
							   completionHandler:(void (^)(NSURL * _Nullable, BOOL))completionHandler {
	
	AVAsset *asset = [AVAsset assetWithURL:assetURL];
	AVMutableComposition *composition = [self compositionForAsset:asset];
	
	AVMutableVideoComposition *videoComposition =
	[self videoCompositionWithComposition:composition asset:asset];
	
	videoComposition = [self watermarkWithVideoComposition:videoComposition
											 watermarkText:watermarkText
											  textLocation:textLocation
											watermarkImage:watermarkImage
											 imageLocation:imageLocation];
	
	return [self exportAsset:composition
						type:LZCameraAssetTypeMov
			videoComposition:videoComposition
					audioMix:nil
				   timeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
				  presetName:AVAssetExportPresetMediumQuality
		   completionHandler:^(NSURL * _Nonnull outputFileURL, BOOL success, NSError * _Nullable error) {
			   if (completionHandler) {
				   completionHandler(outputFileURL, success);
			   }
		   }];
}

+ (NSURL *)generateUniqueAssetFileURL:(LZCameraAssetType)assetType {
	
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
		
		NSString *filePath = [directoryPath stringByAppendingPathComponent:@"lzcamera_movie"];
		NSString *format = nil;
		switch (assetType) {
			case LZCameraAssetTypeMov:
				format = @".mov";
				break;
			case LZCameraAssetTypeMp4:
				format = @".mp4";
				break;
			case LZCameraAssetTypeM4A:
				format = @".m4a";
				break;
			default:
				format = @".mov";
				break;
		}
		filePath = [filePath stringByAppendingString:format];
		NSURL *fileURL = [NSURL fileURLWithPath:filePath];
		return fileURL;
	}
	return nil;
}

+ (BOOL)deleteFile:(NSURL *)fileURL {
	
	NSFileManager *fileM = [NSFileManager defaultManager];
	BOOL success = YES;
	if ([fileM fileExistsAtPath:fileURL.relativePath]) {
		
		NSError *error;
		success = [fileM removeItemAtURL:fileURL error:&error];
		LZCameraLog(@"删除文件%@:%@", success ? @"成功" : @"失败", success ? @"" : error.localizedDescription);
	}
	return success;
}

+ (NSString * _Nullable)sizeForFile:(NSString *)filePath {
	
	NSString *sizeText = nil;
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:filePath]) {
		
		NSDictionary *fileDic = [fileManager attributesOfItemAtPath:filePath error:nil];
		unsigned long long size = fileDic.fileSize;
		if (size >= pow(10, 9)) { // size >= 1GB
			sizeText = [NSString stringWithFormat:@"%.2fGB", size / pow(10, 9)];
		} else if (size >= pow(10, 6)) { // 1GB > size >= 1MB
			sizeText = [NSString stringWithFormat:@"%.2fMB", size / pow(10, 6)];
		} else if (size >= pow(10, 3)) { // 1MB > size >= 1KB
			sizeText = [NSString stringWithFormat:@"%.2fKB", size / pow(10, 3)];
		} else { // 1KB > size
			sizeText = [NSString stringWithFormat:@"%.2lluB", size];
		}
	} else {
		NSLog(@"找不到文件");
		
	}
	return sizeText;
}

+ (NSString *)sizeForImage:(UIImage *)image {
	
	NSData *data = UIImagePNGRepresentation(image);
	if (!data) {
		data = UIImageJPEGRepresentation(image, 0.5);
	}
	double dataLength = [data length] * 1.0;
	NSArray *typeArray = @[@"B",@"KB",@"MB",@"GB"];
	NSInteger index = 0;
	while (dataLength > 1000) {
		dataLength /= 1000.0;
		index ++;
	}
	return [NSString stringWithFormat:@"%.2f%@", dataLength, typeArray[index]];
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
    if (nil == collectionId) {
		LZCameraLog(@"创建相册失败：%@", appName);
		return nil;
	}
	PHAssetCollection *assetCollection =
	[[PHAssetCollection fetchAssetCollectionsWithLocalIdentifiers:@[collectionId] options:nil]
	 lastObject];
	return assetCollection;
}

+ (AVAssetExportSession *)exportAsset:(AVAsset *)asset
								 type:(LZCameraAssetType)type
					 videoComposition:(AVVideoComposition *)videoComposition
							 audioMix:(AVAudioMix *)audioMix
							timeRange:(CMTimeRange)timeRange
						   presetName:(NSString *)presetName
					completionHandler:(void (^)(NSURL * _Nonnull outputFileURL, BOOL success, NSError * _Nullable error))completionHandler {
	
	presetName = [self exportPresetName:presetName asset:asset type:type];
	AVAssetExportSession *exportSession =
	[[AVAssetExportSession alloc] initWithAsset:asset presetName:presetName];
	NSURL *fileURL = [self generateUniqueAssetFileURL:type];
	exportSession.outputURL = fileURL;
	exportSession.shouldOptimizeForNetworkUse = true;
	exportSession.outputFileType = [self exportFileType:type];
	exportSession.timeRange = timeRange;
	if (videoComposition) {
		exportSession.videoComposition = videoComposition;
	}
	if (audioMix) {
		exportSession.audioMix = audioMix;
	}
	
	[exportSession exportAsynchronouslyWithCompletionHandler:^{
		
		BOOL success = exportSession.status == AVAssetExportSessionStatusCompleted;
		if (completionHandler) {
			dispatch_async(dispatch_get_main_queue(), ^{
				if (NO == success) {
					LZCameraLog(@"Export Asset Failed:%@", exportSession.error);
					[self deleteFile:fileURL];
				}
				completionHandler(fileURL, success, exportSession.error);
			});
		}
	}];
	return exportSession;
}

+ (NSString *)exportPresetName:(NSString *)presetName
						 asset:(AVAsset *)asset
						  type:(LZCameraAssetType)type {
	
	NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:asset];
	if (NO == [compatiblePresets containsObject:presetName]) {
		switch (type) {
			case LZCameraAssetTypeM4A:
				presetName = AVAssetExportPresetAppleM4A;
				break;
			default:
				presetName = AVAssetExportPresetMediumQuality;
				break;
		}
	}
	return presetName;
}

+ (AVFileType)exportFileType:(LZCameraAssetType)assetType {
	
	switch (assetType) {
		case LZCameraAssetTypeMov:
			return AVFileTypeQuickTimeMovie;
			break;
		case LZCameraAssetTypeMp4:
			return AVFileTypeMPEG4;
			break;
		case LZCameraAssetTypeM4A:
			return AVFileTypeAppleM4A;
			break;
		default:
			return AVFileTypeQuickTimeMovie;
			break;
	}
}

+ (AVAudioMix *)audioMixWithAudioCompositionTracks:(NSArray<AVMutableCompositionTrack *> *)audioTracks
									originalVolume:(CGFloat)originalVolume
									   audioVolume:(CGFloat)audioVolume
											atTime:(CMTime)time {
	
	NSMutableArray *inputParameters = [NSMutableArray arrayWithCapacity:audioTracks.count];
	for (NSUInteger i = 0; i < audioTracks.count; i++) {
		
		AVMutableCompositionTrack *audioCompositionTrank = [audioTracks objectAtIndex:i];
		if (0 == i) {
			
			AVMutableAudioMixInputParameters *originalMixInput =
			[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrank];
			[originalMixInput setVolume:originalVolume atTime:time];
			[inputParameters addObject:originalMixInput];
		} else {
			
			AVMutableAudioMixInputParameters *audioMixInput =
			[AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioCompositionTrank];
			[audioMixInput setVolume:audioVolume atTime:time];
			[inputParameters addObject:audioMixInput];
		}
	}
	
	AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
	audioMix.inputParameters = [inputParameters copy];
	return audioMix;
}

+ (AVMutableComposition *)composingAudioToAsset:(AVAsset *)asset
									  timeRange:(CMTimeRange)timeRange
									   audioURL:(NSURL *)audioURL
									   mixAudio:(BOOL)mixAudio
								 originalVolume:(CGFloat)originalVolume
									audioVolume:(CGFloat)audioVolume {
	
	AVMutableComposition *assetComposition = [self compositionForAsset:asset];
	if (NO == mixAudio) {
		
		NSArray *audioCompositionTracks = [assetComposition tracksWithMediaType:AVMediaTypeAudio];
		for (AVMutableCompositionTrack *audioCompositionTrack in audioCompositionTracks) {
			[assetComposition removeTrack:audioCompositionTrack];
		}
	}
	
	AVAsset *audioAsset = [AVAsset assetWithURL:audioURL];
	NSArray *audioAssetTracks = [audioAsset tracksWithMediaType:AVMediaTypeAudio];
	if (0 < audioAssetTracks.count) {
		
		CMTime assetTime = timeRange.duration;
		CMTime audioTime = audioAsset.duration;
#if DEBUG
		CMTimeShow(assetTime);
		CMTimeShow(audioTime);
#endif
		CMTime tmpTime = kCMTimeZero;
		static int32_t multi = 0;
		do {
			multi++;
			tmpTime = CMTimeMultiply(audioTime, multi);
			LZCameraLog(@"放大%d倍", (int)multi);
#if DEBUG
			CMTimeShow(tmpTime);
#endif
		} while (0 < CMTimeCompare(assetTime, tmpTime));
		AVMutableCompositionTrack *audioCompositionTrack =
		[assetComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
		audioCompositionTrack.preferredVolume = audioVolume;
		NSError *error = nil;
		
		AVAssetTrack *audioAssetTrack = [audioAssetTracks firstObject];
		for (int i = 0; i < multi; i++) {
			
			CMTime start = 0 == i ? timeRange.start : kCMTimeInvalid;
			CMTimeRange audioTimeRange = CMTimeRangeMake(kCMTimeZero, audioTime);
#if DEBUG
			CMTimeShow(start);
			CMTimeRangeShow(audioTimeRange);
#endif
			[audioCompositionTrack insertTimeRange:audioTimeRange ofTrack:audioAssetTrack atTime:start error:&error];
			if (error) {
				LZCameraLog(@"资源合成-添加背景音音轨失败:%@", error);
			}
		}
		multi = 0;
	}
	return assetComposition;
}

+ (AVMutableComposition *)compositionForAsset:(AVAsset *)asset {
	
	AVMutableComposition *assetComposition = [AVMutableComposition composition];
	CMTimeRange assetTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	NSError *error = nil;
	
	NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
	if (0 < videoAssetTracks.count) {
		for (AVAssetTrack *videoAssetTrack in videoAssetTracks) {
			
			AVMutableCompositionTrack *videoCompositionTrack =
			[assetComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
			[videoCompositionTrack insertTimeRange:assetTimeRange ofTrack:videoAssetTrack atTime:kCMTimeZero error:&error];
			if (error) {
				LZCameraLog(@"资源合成-添加原视频轨道失败:%@", error);
			}
		}
	}
	
	NSArray *audioAssetTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
	if (0 < audioAssetTracks.count) {
		for (AVAssetTrack *originalAudioAssetTrack in audioAssetTracks) {
			
			AVMutableCompositionTrack *originalAudioCompositionTrack =
			[assetComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
			[originalAudioCompositionTrack insertTimeRange:assetTimeRange ofTrack:originalAudioAssetTrack atTime:kCMTimeZero error:&error];
			if (error) {
				LZCameraLog(@"资源合成-添加原音音轨失败:%@", error);
			}
		}
	}
	return assetComposition;
}

+ (AVMutableVideoComposition *)videoCompositionWithComposition:(AVMutableComposition *)composition
														 asset:(AVAsset *)asset {
	
	AVMutableVideoComposition *videoComposition = nil;

	NSArray *compositionTranks = [composition tracksWithMediaType:AVMediaTypeVideo];
	if (0 < compositionTranks.count) {

		CGFloat degree = 0.0f;
		NSArray *videoAssetTracks = [asset tracksWithMediaType:AVMediaTypeVideo];
		if (0 < videoAssetTracks.count) {
			
			AVAssetTrack *videoAssetTrack = [videoAssetTracks firstObject];
			degree = [self getVideoDegree:videoAssetTrack];
		}
		CGSize renderSize = CGSizeMake(MAXFLOAT, MAXFLOAT);
		for (AVMutableCompositionTrack *videoCompositionTrack in compositionTranks) {
			
			CGSize naturalSize = videoCompositionTrack.naturalSize;
			CGFloat videoWidth = (degree == 0 || degree == M_PI) ? naturalSize.width : naturalSize.height;
			CGFloat videoHeight = (degree == 0 || degree == M_PI) ? naturalSize.height : naturalSize.width;
			CGSize cropSize = CGSizeMake(MIN(videoWidth, renderSize.width), MIN(videoHeight, renderSize.height));
			CGAffineTransform mixedTransform = [self assetTransformByDegree:degree naturalSize:naturalSize renderSize:cropSize];
			
			AVMutableVideoCompositionLayerInstruction *layerInstruction =
			[AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoCompositionTrack];
			[layerInstruction setOpacity:0.0 atTime:composition.duration];
			[layerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
			
			AVMutableVideoCompositionInstruction *instruction =
			[AVMutableVideoCompositionInstruction videoCompositionInstruction];
			instruction.timeRange = CMTimeRangeMake(kCMTimeZero, composition.duration);
			instruction.layerInstructions = @[layerInstruction];
			
			videoComposition = [AVMutableVideoComposition videoComposition];
			videoComposition.frameDuration = CMTimeMake(1, 30);
			videoComposition.renderScale = 1.0;
			videoComposition.renderSize = cropSize;
			videoComposition.instructions = @[instruction];
		}
	}
	return videoComposition;
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

+ (CGAffineTransform)assetTransformByDegree:(CGFloat)degree
								naturalSize:(CGSize)naturalSize
								 renderSize:(CGSize)renderSize {
	
	CGFloat videoWidth = (degree == 0 || degree == M_PI) ? naturalSize.width : naturalSize.height;
	CGFloat videoHeight = (degree == 0 || degree == M_PI) ? naturalSize.height : naturalSize.width;
	CGFloat x, y;
	CGAffineTransform mixedTransform =  CGAffineTransformIdentity;
	if (degree == M_PI_2) {
		// 顺时针 90°
		CGAffineTransform t = CGAffineTransformMakeTranslation(naturalSize.height,.0);
		CGAffineTransform t1 = CGAffineTransformRotate(t, M_PI_2);
		// x为正向下 y为正向左
		x = -(videoHeight - renderSize.height) / 2.0;
		y = (videoWidth - renderSize.width) / 2.0;
		mixedTransform = CGAffineTransformTranslate(t1, x, y);
	} else if (degree == M_PI) {
		// 顺时针 180°
		CGAffineTransform t = CGAffineTransformMakeTranslation(naturalSize.width, naturalSize.height);
		CGAffineTransform t1 = CGAffineTransformRotate(t, M_PI);
		// x为正向左 y为正向上
		x = (videoWidth - renderSize.width) / 2.0;
		y = (videoHeight - renderSize.height) / 2.0;
		mixedTransform = CGAffineTransformTranslate(t1, x, y);
	} else if (degree == (M_PI_2 * 3.0)) {
		// 顺时针 270°
		CGAffineTransform t = CGAffineTransformMakeTranslation(.0, naturalSize.width);
		CGAffineTransform t1 = CGAffineTransformRotate(t, M_PI_2 * 3.0);
		// x为正向上 y为正向右
		x = (videoHeight - renderSize.height) / 2.0;
		y = -(videoWidth - renderSize.width) / 2.0;
		mixedTransform = CGAffineTransformTranslate(t1, x, y);
	} else if (degree == 1) {
		// 前摄像头的情况
		CGAffineTransform transform = CGAffineTransformMakeScale(-1.0, 1.0);
		transform = CGAffineTransformRotate(transform, M_PI / 2.0);
		x = -(videoHeight - renderSize.height) / 2.0;
		y = (videoWidth - renderSize.width) / 2.0;
		mixedTransform = CGAffineTransformTranslate(transform, x, y);
	} else {
		// x为正向右 y为正向下
		x = -(videoWidth - renderSize.width) / 2.0;
		y = -(videoHeight - renderSize.height) / 2.0;
		mixedTransform = CGAffineTransformMakeTranslation(x, y);
	}
	return mixedTransform;
}

+ (AVMutableVideoComposition *)watermarkWithVideoComposition:(AVMutableVideoComposition *)videoComposition
											   watermarkText:(NSAttributedString *)watermarkText
												textLocation:(LZCameraWatermarkLocation)textLocation
											  watermarkImage:(UIImage *)watermarkImage
											   imageLocation:(LZCameraWatermarkLocation)imageLocation {
	
	CGSize videoSize = videoComposition.renderSize;
	
	CATextLayer *textLayer = nil;
	if (watermarkText && watermarkText.length) {
		
		textLayer = [CATextLayer layer];
		textLayer.truncationMode = kCATruncationEnd;
		textLayer.wrapped = NO;
		textLayer.backgroundColor = [UIColor clearColor].CGColor;
		textLayer.string = watermarkText;
	}
	
	CALayer *imageLayer = nil;
	if (watermarkImage) {
		
		imageLayer = [CALayer layer];
		imageLayer.contents = (id)watermarkImage.CGImage;
	}
	
	CALayer *overlayLayer = [CALayer layer];
	overlayLayer.frame = (CGRect){CGPointZero, videoSize};
	if (textLayer) {
		[overlayLayer addSublayer:textLayer];
	}
	if (imageLayer) {
		[overlayLayer addSublayer:imageLayer];
	}
	
	CGFloat margin = 10.0f;
	CGFloat spacing = 10.0;
	CGFloat x,y,w,h; // 坐标起点为左下角，向右为x正，向上为y正
	if (imageLayer) {
		
		w = watermarkImage.size.width;
		h = watermarkImage.size.height;
		switch (imageLocation) {
			case LZCameraWatermarkLocationLeftTop:
				
				x = margin;
				y = videoSize.height - h - margin;
				imageLayer.frame = CGRectMake(x, y, w, h);
				break;
			case LZCameraWatermarkLocationLeftBottom:
				
				x = margin;
				y = margin;
				imageLayer.frame = CGRectMake(x, y, w, h);
				break;
			case LZCameraWatermarkLocationRightBottom:
				
				x = videoSize.width - w - margin;
				y = margin;
				imageLayer.frame = CGRectMake(x, y, w, h);
				break;
			case LZCameraWatermarkLocationRightTop:
				
				x = videoSize.width - w - margin;
				y = videoSize.height - h - margin;
				imageLayer.frame = CGRectMake(x, y, w, h);
				break;
			default:
				
				x = (videoSize.width - w) * 0.5f;
				y = (videoSize.height - h) * 0.5f;
				imageLayer.frame = CGRectMake(x, y, w, h);
				break;
		}
	}
	if (textLayer) {
		switch (textLocation) {
			case LZCameraWatermarkLocationLeftTop:
			case LZCameraWatermarkLocationRightTop: {
				
				CGFloat textMaxWidth = videoSize.width - 2 * margin;
				x = margin;
				if (imageLayer && (imageLocation == LZCameraWatermarkLocationLeftTop || imageLocation == LZCameraWatermarkLocationRightTop)) {
					
					textMaxWidth = textMaxWidth - spacing - CGRectGetWidth(imageLayer.frame);
					x = imageLocation == LZCameraWatermarkLocationRightTop ? margin : (CGRectGetMaxX(imageLayer.frame) + spacing);
				}
				CGSize textSize = watermarkText.size;
				
				w = textMaxWidth;
				h = ceil(textSize.height);
				y = videoSize.height - h - margin;
				textLayer.frame = CGRectMake(x, y, w, h);
			}
				break;
			case LZCameraWatermarkLocationLeftBottom:
			case LZCameraWatermarkLocationRightBottom: {
				
				CGFloat textMaxWidth = videoSize.width - 2 * margin;
				x = margin;
				if (imageLayer && (imageLocation == LZCameraWatermarkLocationLeftBottom || imageLocation == LZCameraWatermarkLocationRightBottom)) {
					
					textMaxWidth = textMaxWidth - spacing - CGRectGetWidth(imageLayer.frame);
					x = imageLocation == LZCameraWatermarkLocationRightBottom ? margin : (CGRectGetMaxX(imageLayer.frame) + spacing);
				}
				CGSize textSize = watermarkText.size;
				
				w = textMaxWidth;
				h = ceil(textSize.height);
				y = margin;
				textLayer.frame = CGRectMake(x, y, w, h);
			}
				break;
			default: {
				
				CGFloat textMaxWidth = 0.0f;
				if (imageLayer && imageLocation == LZCameraWatermarkLocationCenter) {
					textMaxWidth = videoSize.width - 2 * margin - spacing - CGRectGetWidth(imageLayer.frame);
				} else {
					textMaxWidth = videoSize.width - 2 * margin;
				}
				CGSize textSize = watermarkText.size;
				
				w = textMaxWidth;
				h = ceil(textSize.height);
				x = (videoSize.width - w - 2 * margin) * 0.5f;
				y = (videoSize.height - h) * 0.5f;
				
				if (imageLayer && imageLocation == LZCameraWatermarkLocationCenter) {
				
					CGRect imgFrame = imageLayer.frame;
					CGFloat imgAndImgW = (CGRectGetWidth(imageLayer.frame) + spacing + w);
					CGFloat imgX = (videoSize.width - imgAndImgW - 2 * margin) * 0.5f;
					imgFrame.origin.x = imgX;
					imageLayer.frame = imgFrame;
					x = CGRectGetMaxX(imageLayer.frame) + spacing;
				}
				textLayer.frame = CGRectMake(x, y, w, h);
			}
				break;
		}
		switch (textLocation) {
			case LZCameraWatermarkLocationLeftTop:
				textLayer.alignmentMode = kCAAlignmentLeft;
				break;
			case LZCameraWatermarkLocationLeftBottom:
				textLayer.alignmentMode = kCAAlignmentLeft;
				break;
			case LZCameraWatermarkLocationRightBottom:
				textLayer.alignmentMode = kCAAlignmentRight;
				break;
			case LZCameraWatermarkLocationRightTop:
				textLayer.alignmentMode = kCAAlignmentRight;
				break;
			default:
				textLayer.alignmentMode = kCAAlignmentCenter;
				break;
		}
	}
	
	CALayer *videoLayer = [CALayer layer];
	videoLayer.frame = (CGRect){CGPointZero, videoSize};
	CALayer *parentLayer = [CALayer layer];
	parentLayer.frame = (CGRect){CGPointZero, videoSize};
	[parentLayer addSublayer:videoLayer];
	[parentLayer addSublayer:overlayLayer];
	
	AVVideoCompositionCoreAnimationTool *animalTool =
	[AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
																								 inLayer:parentLayer];
	videoComposition.animationTool = animalTool;
	return videoComposition;
}

@end
