//
//  LZCameraMediaController.h
//  LZCamera
//
//  Created by Dear.Q on 2021/6/16.
//

#import "LZCameraController.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraMediaController : LZCameraController

/** 是否是拍照，默认 NO */
@property (assign, nonatomic) BOOL takePhoto;

@end

NS_ASSUME_NONNULL_END
