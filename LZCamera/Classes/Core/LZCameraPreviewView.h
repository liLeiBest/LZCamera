//
//  LZCameraPreviewView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/23.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraPreviewView : UIView

/** 接收捕捉会话 */
@property (strong, nonatomic) AVCaptureSession *captureSesstion;
/** 获取预览图层 */
@property (strong, nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

@end

NS_ASSUME_NONNULL_END
