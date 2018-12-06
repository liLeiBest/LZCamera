//
//  LZCameraConfig.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/21.
//

#import "LZCameraConfig.h"

@implementation LZCameraConfig

- (instancetype)init {
    
    self = [super init];
    if (self) {
        
        self.stillImageAutoWriteToAlbum = YES;
        self.videoAutoWriteToAlbum = YES;
        self.cameraZoomRate = 1.2f;
        self.maxCameraZoomFactor = 3.0f;
        self.minVideoRecordedDuration = kCMTimeZero;
        self.maxVideoRecordedDuration = kCMTimeInvalid;
        self.maxVideoRecordedFileSize = 0.0f;
        self.minVideoFreeDiskSpaceLimit = 0.0f;
    }
    return self;
}

@end
