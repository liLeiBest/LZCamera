//
//  LZCameraVideoEditorViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/21.
//

#import "LZCameraVideoEditorViewController.h"
#import "LZCameraEditorVideoContainerView.h"
#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraToolkit.h"

@interface LZCameraVideoEditorViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoContainerView *videoClipView;;

/** 预览层 */
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
/** 计时器 */
@property (strong, nonatomic) NSTimer *timer;
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

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self fetchVideoThumbnails];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	
	[self stopTimer];
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];
	
	self.playerLayer.frame = self.previewImgView.layer.frame;
}

- (void)dealloc {
	LZCameraLog();
	[[NSNotificationCenter defaultCenter] removeObserver:self];
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
	self.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
	self.previewImgView.image = self.previewImage;
	[self buildPlayer];
	
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(appResignActive)
	 name:UIApplicationWillResignActiveNotification
	 object:nil];
	[[NSNotificationCenter defaultCenter]
	 addObserver:self
	 selector:@selector(appBecomeActive)
	 name:UIApplicationDidBecomeActiveNotification
	 object:nil];
	
	self.videoClipView.duration = asset.duration;
	self.videoClipView.videoMaximumDuration = self.videoMaximumDuration;
	__weak typeof(self) weakSelf = self;
	self.videoClipView.TapPreviewClipCallback = ^(CMTimeRange timeRange) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.timeRange = timeRange;
		[strongSelf startTimer];
	};
	
	self.navigationItem.leftBarButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"返回"
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
	
	if (self.playerLayer) {
		
		[self.playerLayer.player pause];
		[self.playerLayer removeFromSuperlayer];
	}
	AVAsset *asset = [AVAsset assetWithURL:self.editVideoURL];
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
	self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:player];
	self.playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
	self.playerLayer.frame = self.previewImgView.layer.frame;
	[self.view.layer insertSublayer:self.playerLayer above:self.previewImgView.layer];
}

- (void)startTimer {
	
	[self stopTimer];
	CGFloat duration = self.timeRange.duration.value / self.timeRange.duration.timescale;
	self.timer =
	[NSTimer scheduledTimerWithTimeInterval:duration
									 target:self
								   selector:@selector(playPartVideo:)
								   userInfo:nil
									repeats:YES];
	[self.timer fire];
}

- (void)stopTimer {
	
	[self.timer invalidate];
	self.timer = nil;
	[self.playerLayer.player pause];
	[self.videoClipView removeProgressLine];
}

- (void)playPartVideo:(NSTimer *)timer {
	
	[self.playerLayer.player play];
	[self.playerLayer.player seekToTime:[self getStartTime]
						toleranceBefore:kCMTimeZero
						 toleranceAfter:kCMTimeZero];
	[self.videoClipView updateProgressLine];
}

- (CMTime)getStartTime {
	
	CMTime time = self.timeRange.start;
	if (NO == CMTIME_IS_VALID(time)) {
		time = kCMTimeZero;
	}
	return time;
}

- (void)fetchVideoThumbnails {
	
	CMTimeValue interval= 1.0f;
	__weak typeof(self) weakSelf = self;
	[LZCameraToolkit thumbnailBySecondForVideoAsset:self.editVideoURL
										   interval:interval
											maxSize:CGSizeMake(60, 0)
								  completionHandler:^(NSArray<UIImage *> * _Nullable thumbnails) {
		
									  typeof(weakSelf) strongSelf = weakSelf;
									  [strongSelf.videoClipView updateVideoThumbnails:thumbnails];
									  [strongSelf startTimer];
								  }];
}

// MARK: - Obasever
- (void)appResignActive {
	[self stopTimer];
}

- (void)appBecomeActive {
	[self startTimer];
}

@end
