//
//  LZCameraEditorMusicModel.h
//  LZCamera
//
//  Created by Dear.Q on 2019/7/23.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface LZCameraEditorMusicModel : NSObject

@property (copy, nonatomic) NSString *thumbnail;
@property (copy, nonatomic) NSString *title;
@property (assign, nonatomic) BOOL selected;

@end

NS_ASSUME_NONNULL_END
