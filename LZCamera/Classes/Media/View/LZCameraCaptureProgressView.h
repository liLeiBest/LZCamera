//
//  LZCameraCaptureProgressView.h
//  LZCamera
//
//  Created by Dear.Q on 2018/11/26.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraCaptureProgressView : UIView

@property (assign, nonatomic) NSInteger timeMax;

- (void)clearProgress;

@end

NS_ASSUME_NONNULL_END
