//
//  LZCameraCodeController.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/29.
//

#import "LZCameraCodeController.h"

@interface LZCameraCodeController()

/** 当前的可用的摄像头 */
@property (weak, nonatomic) AVCaptureDeviceInput *activeMediaInput;

@end

@implementation LZCameraCodeController

- (BOOL)setupSessionInputs:(NSError * _Nullable __autoreleasing *)error {
    
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (device.autoFocusRangeRestrictionSupported) {
        
        if ([device lockForConfiguration:error]) {
            
            device.autoFocusRangeRestriction = AVCaptureAutoFocusRangeRestrictionNone;
            [device unlockForConfiguration];
        }
    }
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device error:error];
    if ([self.captureSession canAddInput:deviceInput]) {
        
        [self.captureSession addInput:deviceInput];
        self.activeMediaInput = deviceInput;
    } else {
        
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add video input."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddInput
                                 userInfo:userInfo];
        return NO;
    }
    return YES;
}

- (BOOL)setupSessionOutputs:(NSError * _Nullable __autoreleasing *)error {
    return YES;
}

- (BOOL)grantCameraAuthority {
    
    BOOL grantVideo = YES;
    AVAuthorizationStatus authorizationStatusForVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authorizationStatusForVideo == AVAuthorizationStatusRestricted || authorizationStatusForVideo == AVAuthorizationStatusDenied) {
        grantVideo = NO;
    }
    
    return grantVideo;
}

@end
