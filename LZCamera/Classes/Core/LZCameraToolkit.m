//
//  LZCameraToolkit.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/19.
//

#import "LZCameraToolkit.h"
#import "LZCameraDefine.h"

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
				[self saveAlbumCallbackOnMainThread:^(PHAsset * _Nullable asset, NSError * _Nullable error) {
					
				}];
				
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

+ (AVAssetImageGenerator *)thumbnailBySecondForAsset:(AVAsset *)asset
											interval:(CMTimeValue)interval
											 maxSize:(CGSize)maxSize
								   completionHandler:(void (^)(AVAsset * _Nullable, NSArray<UIImage *> * _Nullable))handler {
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
				handler(asset, thumbnails);
			});
		}
	};
	[assetImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:completionHandler];
	
	return assetImageGenerator;
}

// MARK: - Private
/**
 根据本地标识获取 PHAsset
 
 @param localIdentifier 本地标识
 @return PHAsset
 */
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

/**
 获取目标相册
 
 @param error NSError
 @return PHAssetCollection
 */
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

+ (void)saveAlbumCallbackOnMainThread:(LZCameraSaveAlbumCompletionHandler)handler {
	
	if (NO == [NSThread isMainThread]) {
		
	} else {
		
	}
}

@end
