//
//  LZCameraToastViewController.m
//  LZCamera
//
//  Created by Dear.Q on 2019/7/27.
//

#import "LZCameraToastViewController.h"

@interface LZCameraToastViewController () {
	
	IBOutlet UIActivityIndicatorView *indicatorView;
	IBOutlet UILabel *messageLabel;
}

@property (copy, nonatomic) NSString *message;

@end

@implementation LZCameraToastViewController

// MARK: - Initialization
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[indicatorView startAnimating];
	NSShadow *shadow = [[NSShadow alloc] init];
	shadow.shadowBlurRadius = 10.0f;
	shadow.shadowOffset = CGSizeMake(0, 0);
	shadow.shadowColor = [UIColor blackColor];
	NSDictionary *attributes = @{NSShadowAttributeName : shadow,
								 NSFontAttributeName : messageLabel.font};
	NSMutableAttributedString *attributedString =
	[[NSMutableAttributedString alloc] initWithString:self.message attributes:attributes];
	messageLabel.attributedText = attributedString;
}

- (void)dealloc {
	LZCameraLog();
}
// MARK: - Public
+ (instancetype)instance {
	
	NSBundle *bundle = LZCameraNSBundle(@"LZCameraCore");
	UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"LZCameraToastViewController"
														 bundle:bundle];
	return storyboard.instantiateInitialViewController;
}

- (void)showMessage:(NSString *)message {
	
	@synchronized (self) {
		self.message = message;
	}
}

- (void)hideAfterDelay:(CGFloat)delay
	 completionHandler:(void (^)(void))handler {
	
	@synchronized (self) {
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			
			[self->indicatorView stopAnimating];
			[self dismissViewControllerAnimated:YES completion:^{
				if (handler) {
					handler();
				}
			}];
		});
	}
}

@end
