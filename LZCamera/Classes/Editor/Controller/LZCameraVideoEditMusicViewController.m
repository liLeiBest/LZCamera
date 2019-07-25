//
//  LZCameraVideoEditMusicViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/25.
//

#import "LZCameraVideoEditMusicViewController.h"
#import "LZCameraEditorVideoMusicContainerView.h"
#import "LZCameraToolkit.h"

@interface LZCameraVideoEditMusicViewController ()

@property (weak, nonatomic) IBOutlet UIImageView *previewImgView;
@property (weak, nonatomic) IBOutlet LZCameraEditorVideoMusicContainerView *musicView;

/** 预览层 */
@property (strong, nonatomic) AVPlayerLayer *playerLayer;
/** 已编辑的视频地址 */
@property (copy, nonatomic) NSURL *editVideoURL;
/** 已编辑的视频时间 */
@property (assign, nonatomic) CMTimeRange editVideoTimeRange;
/** 背景音乐 */
@property (strong, nonatomic) LZCameraEditorMusicModel *musicModel;
/** 计时器 */
@property (strong, nonatomic) NSTimer *timer;

@end

@implementation LZCameraVideoEditMusicViewController

// AMRK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self setupUI];
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
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraVideoEditMusicViewController"
														 bundle:bundle];
	return storyboard.instantiateInitialViewController;
}

// MARK: - UI Action
- (void)popDidClick {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)doneDidClick {
	
	if (self.VideoEditCallback) {
		
		UIImage *previewImage = [LZCameraToolkit thumbnailAtFirstFrameForVideoAtURL:self.editVideoURL];
		self.VideoEditCallback(self.editVideoURL, previewImage);
	}
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

// MARK: - Private
- (void)setupUI {
	
	self.title = @"加音乐";
	
	self.editVideoURL = self.videoURL;
	self.editVideoTimeRange = CMTimeRangeMake(self.timeRange.start, self.timeRange.duration);
	[self buildPlayer];
	[self startTimer];
	
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
	
	__weak typeof(self) weakSelf = self;
	self.musicView.TapOriginalMusicCallback = ^{
		
		typeof(weakSelf) strongSelf = weakSelf;
		strongSelf.editVideoURL = strongSelf.videoURL;
		strongSelf.editVideoTimeRange = CMTimeRangeMake(strongSelf.timeRange.start, strongSelf.timeRange.duration);
		[strongSelf buildPlayer];
		[strongSelf startTimer];
	};
	self.musicView.TapMusicCallback = ^(LZCameraEditorMusicModel * _Nonnull musicModel) {
		
		typeof(weakSelf) strongSelf = weakSelf;
		[strongSelf stopTimer];
		
		strongSelf.musicModel = musicModel;
		NSBundle *bundle = LZCameraNSBundle(@"LZCameraEditor");
		NSString *musicPath = [bundle pathForResource:strongSelf.musicModel.thumbnail ofType:@"mp3"];
		NSURL *musicURL = [NSURL fileURLWithPath:musicPath];
		if (nil == musicURL) {
			return ;
		}
		[LZCameraToolkit mixAudioForAsset:strongSelf.videoURL timeRange:strongSelf.timeRange audioPathURL:musicURL originalAudio:YES originalVolume:1 audioVolume:0.5 presetName:AVAssetExportPresetMediumQuality completionHandler:^(NSURL * _Nullable outputFileURL, BOOL success) {
			
			strongSelf.editVideoURL = outputFileURL;
			AVAsset *asset = [AVAsset assetWithURL:outputFileURL];
			strongSelf.editVideoTimeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
			[strongSelf buildPlayer];
			[strongSelf startTimer];
		}];
	};
	
	self.navigationItem.leftBarButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"返回"
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(popDidClick)];
	self.navigationItem.rightBarButtonItem =
	[[UIBarButtonItem alloc] initWithTitle:@"完成"
									 style:UIBarButtonItemStylePlain
									target:self
									action:@selector(doneDidClick)];
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
	CGFloat duration = CMTimeGetSeconds(self.editVideoTimeRange.duration);
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
}

- (void)playPartVideo:(NSTimer *)timer {
	
	[self.playerLayer.player play];
	[self.playerLayer.player seekToTime:[self getStartTime]
						toleranceBefore:kCMTimeZero
						 toleranceAfter:kCMTimeZero];
}

- (CMTime)getStartTime {
	
	CMTime time = self.editVideoTimeRange.start;
	if (NO == CMTIME_IS_VALID(time)) {
		time = kCMTimeZero;
	}
	return time;
}

// MARK: - Obasever
- (void)appResignActive {
	[self stopTimer];
}

- (void)appBecomeActive {
	[self startTimer];
}

@end
