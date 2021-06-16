//
//  LZCameraMediaController.m
//  LZCamera
//
//  Created by Dear.Q on 2021/6/16.
//

#import "LZCameraMediaController.h"

@implementation LZCameraMediaController

- (instancetype)init {
    if (self = [super init]) {
        self.takePhoto = NO;
    }
    return self;
}

- (BOOL)setupSessionInputs:(NSError **)error {
    
    AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput *videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:error];
    
    if (NO == [self updateSessionVideoInput:videoDeviceInput]) {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add audio input."};
        *error = [NSError errorWithDomain:LZCameraErrorDomain
                                     code:LZCameraErrorFailedToAddInput
                                 userInfo:userInfo];
        return NO;
    }
    if (NO == self.takePhoto) {
        
        AVCaptureDevice *audioDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
        AVCaptureDeviceInput *audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:audioDevice error:error];
        if (audioDeviceInput) {
            if ([self.captureSession canAddInput:audioDeviceInput]) {
                [self.captureSession addInput:audioDeviceInput];
            } else {
                
                NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add audio input."};
                *error = [NSError errorWithDomain:LZCameraErrorDomain
                                             code:LZCameraErrorFailedToAddInput
                                         userInfo:userInfo];
            }
        } else {
            
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey: @"Failed to add audio input."};
            *error = [NSError errorWithDomain:LZCameraErrorDomain
                                         code:LZCameraErrorFailedToAddInput
                                     userInfo:userInfo];
            return NO;
        }
    }
    return YES;
}

@end
