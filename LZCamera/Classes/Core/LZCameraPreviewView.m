//
//  LZCameraPreviewView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import "LZCameraPreviewView.h"

@implementation LZCameraPreviewView

// MARK: - Initiazalition
+ (Class)layerClass {
    return [AVCaptureVideoPreviewLayer class];
}

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setupView];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    
    if (self = [super initWithCoder:aDecoder]) {
        [self setupView];
    }
    return self;
}

- (AVCaptureVideoPreviewLayer *)previewLayer {
    return (AVCaptureVideoPreviewLayer *)self.layer;
}

- (AVCaptureSession *)captureSesstion {
    return [self.previewLayer session];
}

- (void)setCaptureSesstion:(AVCaptureSession *)captureSesstion {
    [self.previewLayer setSession:captureSesstion];
}

// MARK: - Private
/**
 设置视图
 */
- (void)setupView {
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
}

@end
