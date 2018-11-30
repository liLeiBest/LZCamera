//
//  LZCameraDefine.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/30.
//

#import <AVFoundation/AVFoundation.h>

NSString * const LZCameraErrorDomain = @"com.lzcamera.LZCameraErrorDomain";

void lzPlaySound(NSString *soundName, NSString *inBundle) {
    
    NSString *path = [LZCameraNSBundle(inBundle) pathForResource:soundName ofType:nil];
    NSURL *pathURL = [NSURL URLWithString:path];
    CFURLRef cfURL = CFBridgingRetain(pathURL);
    static SystemSoundID camera_sound = 0;
    AudioServicesCreateSystemSoundID(cfURL, &camera_sound);
    AudioServicesPlaySystemSound(camera_sound);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{    
        AudioServicesDisposeSystemSoundID(camera_sound);
    });
}
