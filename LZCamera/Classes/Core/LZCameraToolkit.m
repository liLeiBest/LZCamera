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
