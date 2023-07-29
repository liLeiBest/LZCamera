//
//  LZCameraEditorVideoMusicContainerView.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/23.
//

#import "LZCameraEditorVideoMusicContainerView.h"
#import "LZCameraEditorMusicThumbnailCell.h"

@interface LZCameraEditorVideoMusicContainerView()<UICollectionViewDataSource, UICollectionViewDelegate> {
	
	IBOutlet UIProgressView *progressView;
	IBOutlet UIButton *originAudioBtn;
	IBOutlet UICollectionView *collectionView;
}

@property (strong, nonatomic) NSMutableArray *datasource;
@property (assign, nonatomic) BOOL editEnable;

@end
@implementation LZCameraEditorVideoMusicContainerView

// MARK: - Lazy Loading
- (NSMutableArray *)datasource {
	if (nil == _datasource) {
		_datasource = [NSMutableArray array];
	}
	return _datasource;
}

// MARK: - Initialization
- (void)awakeFromNib {
	[super awakeFromNib];
	
	[self setupUI];
	[self fetchMusic];
}

// MARK: - Public
- (void)updateEditProgress:(CGFloat)progress {
	
	LZCameraLog(@"视频合成进度:%f", progress);
	UIViewAnimationOptions options =
	UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveLinear;
	[UIView animateWithDuration:0.5f
						  delay:.0
						options:options
					 animations:^{
						 
						 BOOL animated = progress > 0;
						 [self->progressView setProgress:progress animated:animated];
					 } completion:^(BOOL finished) {
					 }];
	if (1 <= progress) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self->progressView setProgress:0.0 animated:NO];
		});
	}
}

- (void)updateEditEnable:(BOOL)enable {
	self.editEnable = enable;
}

// MARK: - UI Action
- (IBAction)originalAudioDidClick:(id)sender {    
    if (YES == self.editEnable) {
        if (NO == originAudioBtn.selected) {
            // 只作选择音乐和原音切换，不做去掉原音
            originAudioBtn.selected = !originAudioBtn.selected;
        }
		[self handleSelectedMusic:nil];
		if (self.TapOriginalMusicCallback) {
			self.TapOriginalMusicCallback();
		}
	}
}
// MARK: - Private
- (void)setupUI {
	
	UIImage *normalImage = [UIImage imageNamed:@"editor_origin_music_normal"
                                      inBundle:LZCameraNSBundle(@"LZCameraEditor")
                 compatibleWithTraitCollection:nil];
    UIImage *selectedImage = [UIImage imageNamed:@"editor_origin_music_selected"
                                        inBundle:LZCameraNSBundle(@"LZCameraEditor")
                   compatibleWithTraitCollection:nil];
	[originAudioBtn setImage:normalImage forState:UIControlStateNormal];
    [originAudioBtn setImage:normalImage forState:UIControlStateHighlighted];
    [originAudioBtn setImage:selectedImage forState:UIControlStateSelected];
    originAudioBtn.selected = YES;
    collectionView.backgroundColor = [UIColor clearColor];
}

- (void)fetchMusic {
	
	[self.datasource removeAllObjects];
	for (NSUInteger i = 1; i < 13; i++) {
		
		LZCameraEditorMusicModel *model = [[LZCameraEditorMusicModel alloc] init];
		NSString *imgName = [NSString stringWithFormat:@"backgroundSound%d", (int)i];
		model.thumbnail = imgName;
		NSString *title = nil;
		switch (i) {
			case 1:
				title = @"Tooting";
				break;
			case 2:
				title = @"Exercise";
				break;
			case 3:
				title = @"吹吹风";
				break;
			case 4:
				title = @"Night-Sky";
				break;
			case 5:
				title = @"Jumping-Rope";
				break;
			case 6:
				title = @"小精灵";
				break;
			case 7:
				title = @"Big-Boat-1";
				break;
			case 8:
				title = @"Big-Boat-2";
				break;
			case 9:
				title = @"好宝宝";
				break;
			case 10:
				title = @"长高不是梦";
				break;
			case 11:
				title = @"Playing-music-1";
				break;
			case 12:
				title = @"Playing-music-2";
				break;
		}
		model.title = title;
		[self.datasource addObject:model];
	}
	[collectionView reloadData];
}

- (void)handleSelectedMusic:(LZCameraEditorMusicModel *)musicModel {
	for (LZCameraEditorMusicModel *model in self.datasource) {
		if ([model isEqual:musicModel]) {
			model.selected = YES;
		} else {
			model.selected = NO;
		}
	}
	[collectionView reloadData];
}

// MARK: - Delegate
// MARK: <UICollectionViewDataSource>
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
	 numberOfItemsInSection:(NSInteger)section {
	return self.datasource.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
				  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	LZCameraEditorMusicThumbnailCell *cell =
	[collectionView dequeueReusableCellWithReuseIdentifier:LZEditMusicThumbnailCellID forIndexPath:indexPath];
	cell.musicModel = [self.datasource objectAtIndex:indexPath.row];
	return cell;
}

// MARK: <UICollectionViewDelegate>
- (void)collectionView:(UICollectionView *)collectionView
didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
	if (YES == self.editEnable) {
		
        originAudioBtn.selected = NO;
		LZCameraEditorMusicModel *musicModel = [self.datasource objectAtIndex:indexPath.row];
		[self handleSelectedMusic:musicModel];
		if (self.TapMusicCallback) {
			self.TapMusicCallback(musicModel);
		}
	}
}

// MARK: <UICollectionViewDelegateFlowLayout>
- (CGSize)collectionView:(UICollectionView *)collectionView
				  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
	
	CGFloat height = collectionView.frame.size.height;
	return CGSizeMake(height, height);
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
	return 0.0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView
				   layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 10.0f;
}

@end
