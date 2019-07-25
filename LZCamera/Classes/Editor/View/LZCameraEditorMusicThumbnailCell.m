//
//  LZCameraEditorMusicThumbnailCell.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/23.
//

#import "LZCameraEditorMusicThumbnailCell.h"
#import "LZCameraEditorMusicModel.h"

NSString * const LZEditMusicThumbnailCellID = @"LZCameraEditorMusicThumbnailCell";
@interface LZCameraEditorMusicThumbnailCell()
@property (weak, nonatomic) IBOutlet UIImageView *imgView;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImgView;
@end
@implementation LZCameraEditorMusicThumbnailCell

// MARK: - Initialization
- (void)awakeFromNib {
	[super awakeFromNib];
	
	[self setupUI];
}

- (void)setMusicModel:(LZCameraEditorMusicModel *)musicModel {
	_musicModel = musicModel;
	
	self.imgView.image = [self imageInBundle:musicModel.thumbnail];
	self.titleLabel.text = musicModel.title;
	self.coverImgView.hidden = musicModel.selected ? NO : YES;
}

// MARK: - Private
- (void)setupUI {
	
	self.contentView.layer.cornerRadius = 6.0f;
	self.contentView.layer.masksToBounds = YES;
}

- (UIImage *)imageInBundle:(NSString *)imageName {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
	return image;
}

@end
