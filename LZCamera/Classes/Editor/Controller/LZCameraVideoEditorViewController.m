//
//  LZCameraVideoEditorViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import "LZCameraVideoEditorViewController.h"
#import "LZCameraEditorVideoContainerView.h"
#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraPlayer.h"
#import "LZCameraToolkit.h"

@interface LZCameraVideoEditorViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoContainerView *videoClipView;;

/** 视频播放器 */
@property (strong, nonatomic) LZCameraPlayer *videoPlayer;
/** 循环播放的区间 */
@property (assign, nonatomic) CMTimeRange timeRange;
/** 已编辑的视频地址 */
@property (copy, nonatomic) NSURL *editVideoURL;

@end

@implementation LZCameraVideoEditorViewController

// MARK: - Initialization
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
	if (self = [super initWithCoder:aDecoder]) {
		self.videoMaximumDuration = 10.0f;
	}
	return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[self stopPlay];
	[self.videoPlayer.playerLayer removeFromSuperlayer];
	self.videoPlayer = nil;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	self.videoPlayer.playerLayer.frame = self.previewImgView.layer.frame;
}

- (void)dealloc {
	LZCameraLog();
}

// MARK: - Public
+ (instancetype)instance {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraVideoEditorViewController"
														 bundle:bundle];
	return storyboard.instantiateInitialViewController;
}

// MARK: - UI Action
- (void)popDidClick {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)nextDidClick {
	
	LZCameraVideoEditMusicViewController *ctr = [LZCameraVideoEditMusicViewController instance];
	ctr.videoURL = self.editVideoURL;
	ctr.timeRange = self.timeRange;
	ctr.VideoEditCallback = self.VideoEditCallback;
	[self.navigationController pushViewController:ctr animated:YES];
}

// MAKR: - Private
- (void)setupUI {
	
	self.title = @"裁剪视频";
	
	self.editVideoURL = self.videoURL;
	AVAsset *asset = [AVAsset assetWithURL:self.editVideoURL];
    CMTime defaultTime = asset.duration;
    if (self.videoMaximumDuration < CMTimeGetSeconds(asset.duration)) {
        defaultTime = CMTimeMakeWithSeconds(self.videoMaximumDuration, asset.duration.timescale);
    }
	self.timeRange = CMTimeRangeMake(kCMTimeZero, defaultTime);
	self.previewImgView.image = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:self.editVideoURL];
	[self buildPlayer];
	[self fetchVideoThumbnails];
	
	self.videoClipView.duration = asset.duration;
	self.videoClipView.videoMaximumDuration = self.videoMaximumDuration;
	__weak typeof(self) weakSelf = self;
	self.videoClipView.TapPreviewClipCallback = ^(CMTimeRange timeRange) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.timeRange = timeRange;
		[strongSelf startPlay];
	};
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
	UIImage *navBackImage = [UIImage imageNamed:@"nav_back_default"
									   inBundle:bundle
				  compatibleWithTraitCollection:nil];
	self.navigationItem.leftBarButtonItem =
	[[UIBarButtonItem alloc] initWithImage:navBackImage
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(popDidClick)];
	self.navigationItem.rightBarButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"下一步"
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(nextDidClick)];
}

- (void)buildPlayer {
	
	if (self.videoPlayer) {
		
		[self.videoPlayer pause];
		[self.videoPlayer.playerLayer removeFromSuperlayer];
	}
	self.videoPlayer = [LZCameraPlayer playerWithURL:self.editVideoURL];
	self.videoPlayer.timeRange = self.timeRange;
	__weak typeof(self) weakSelf = self;
	self.videoPlayer.playToEndCallback = ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf.videoClipView updateProgressLine];
	};
	self.videoPlayer.playerLayer.frame = self.previewImgView.frame;
	[self.view.layer insertSublayer:self.videoPlayer.playerLayer above:self.previewImgView.layer];
}

- (void)startPlay {
	
	self.videoPlayer.timeRange = self.timeRange;
	[self.videoPlayer play];
}

- (void)stopPlay {
	
	[self.videoPlayer pause];
	[self.videoClipView removeProgressLine];
}

- (void)fetchVideoThumbnails {
	
	CMTimeValue interval= [self thumbnailInterval];
	__weak typeof(self) weakSelf = self;
	[LZCameraToolkit thumbnailBySecondForVideoAsset:self.editVideoURL
										   interval:interval
											maxSize:CGSizeMake(60, 0)
									progressHandler:^(NSArray<UIImage *> * _Nullable thumbnails, CGFloat progress) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.videoClipView updateVideoThumbnails:thumbnails progress:progress complete:NO];
    } completionHandler:^(NSArray<UIImage *> * _Nullable thumbnails) {
        
        typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.videoClipView updateVideoThumbnails:nil progress:1.0f complete:YES];
        [strongSelf.videoPlayer play];
    }];
}

- (CMTimeValue)thumbnailInterval {
    
    AVAsset *asset = [AVAsset assetWithURL:self.videoURL];
    CMTime duration = asset.duration;
    Float64 seconds = CMTimeGetSeconds(duration);
    CMTimeValue maxCount = 20;
    CMTimeValue interval = ceil(seconds / maxCount);
    return interval;
}

@end
