//
//  LZCameraEditorVideoMusicContainerView.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/23.
//

#import <UIKit/UIKit.h>
#import "LZCameraEditorMusicModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraEditorVideoMusicContainerView : UIView

/** 确定回调 */
@property (copy, nonatomic) void (^TapSureCallback)(void);
/** 点击原音回调 */
@property (copy, nonatomic) void (^TapOriginalMusicCallback)(void);
/** 选择音乐回调 */
@property (copy, nonatomic) void (^TapMusicCallback)(LZCameraEditorMusicModel *musicModel);

@end

NS_ASSUME_NONNULL_END
