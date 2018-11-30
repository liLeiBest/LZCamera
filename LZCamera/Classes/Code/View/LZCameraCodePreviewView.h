//
//  LZCameraCodePreviewView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/29.
//

#import "LZCameraPreviewView.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraCodePreviewView : LZCameraPreviewView

/**
 机器码识别
 
 @param codes @[AVMetadataFaceObject]
 */
- (void)detectCodes:(NSArray<AVMetadataObject *> *)codes;

@end

NS_ASSUME_NONNULL_END
