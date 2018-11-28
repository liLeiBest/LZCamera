//
//  LZCameraCaptureFlashControl.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/27.
//

#import "LZCameraCaptureFlashControl.h"

static const CGFloat BUTTON_SIZE = 60.0f;
static const CGFloat FONT_SIZE      = 17.0f;

#define BOLD_FONT   [UIFont fontWithName:@"AvenirNextCondensed-DemiBold" size:FONT_SIZE]
#define NORMAL_FONT [UIFont fontWithName:@"AvenirNextCondensed-Medium" size:FONT_SIZE]

#define LEFT_SHRINK     CGRectMake(BUTTON_SIZE, self.midY, 0.f, BUTTON_SIZE)
#define RIGHT_SHRINK    CGRectMake(BUTTON_SIZE + BUTTON_SIZE, 0, 0.f, BUTTON_SIZE)
#define MIDDLE_EXPANDED CGRectMake(BUTTON_SIZE, self.midY, BUTTON_SIZE, BUTTON_SIZE)

@interface LZCameraCaptureFlashControl()

@property (weak, nonatomic) UIImageView *imgView;
@property (nonatomic) BOOL expanded;
@property (nonatomic) CGFloat defaultWidth;
@property (nonatomic) CGFloat expandedWidth;
@property (nonatomic) NSUInteger selectedIndex;
@property (nonatomic) CGFloat midY;

@property (strong, nonatomic) NSArray *labels;

@end
@implementation LZCameraCaptureFlashControl

// MARK: - Initialization
- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self setupView];
	self.selectedIndex = 0;
}

- (void)setSelectedMode:(LZCameraFlashMode)selectedMode {
    
    if (_selectedMode != selectedMode) {
        _selectedMode = selectedMode;
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

// MARK: - UI Action
- (void)selectMode:(id)sender forEvent:(UIEvent *)event {
    
    if (!self.expanded) {
        [self animationToExpand:YES];
    } else {
        
        UILabel *label = nil;
        CGPoint touchPoint = CGPointZero;
        UITouch *touch = [[event allTouches] anyObject];
        for (NSUInteger i = 0; i < self.labels.count; i++) {
            
            label = self.labels[i];
            touchPoint = [touch locationInView:label];
            if ([label pointInside:touchPoint withEvent:event]) {
                
                self.selectedIndex = i;
                break;
            }
        }
        
        [self animationToExpand:NO];
    }
    self.expanded = !self.expanded;
}

//- (void)performDelegateSelectorIfSupported:(SEL)sel {
//    if ([self.delegate respondsToSelector:sel]) {
//        [self.delegate performSelector:sel withObject:nil];
//    }
//}

// MARK: - Private
/**
 加载图片资源
 
 @param imageName NSString
 @return UIImage
 */
- (UIImage *)imageInBundle:(NSString *)imageName {
    
    NSBundle *bundle = LZCameraNSBundle(@"LZCameraMedia");
    UIImage *image = [UIImage imageNamed:imageName inBundle:bundle compatibleWithTraitCollection:nil];
    return image;
}

- (void)setupView {
    
    self.backgroundColor = [UIColor redColor];
    self.clipsToBounds = YES;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.contentMode = UIViewContentModeCenter;
    imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self addSubview:imageView];
	self.imgView = imageView;
    
    self.midY = floorf(self.frame.size.width - BUTTON_SIZE) / 2.0f;
    self.labels = [self buildLabels:@[@"自动", @"打开", @"关闭"]];
    
    self.defaultWidth = self.frame.size.width;
    self.expandedWidth = [UIScreen mainScreen].bounds.size.width - self.frame.origin.x;
    
    [self addTarget:self action:@selector(selectMode:forEvent:) forControlEvents:UIControlEventTouchDown];
}

- (NSArray *)buildLabels:(NSArray *)labelStrings {
    
    CGFloat x = BUTTON_SIZE;
    NSMutableArray *labels = [NSMutableArray array];
    for (NSString *string in labelStrings) {
        
        CGRect frame = CGRectMake(x, self.midY, BUTTON_SIZE, BUTTON_SIZE);
        UILabel *label = [[UILabel alloc] initWithFrame:frame];
        label.text = string;
        label.font = NORMAL_FONT;
        label.textColor = [UIColor whiteColor];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = NSTextAlignmentCenter;
        [self addSubview:label];
        [labels addObject:label];
        x += BUTTON_SIZE;
    }
    return labels;
}

/**
 Setter

 @param selectedIndex NSUInteger
 */
- (void)setSelectedIndex:(NSUInteger)selectedIndex {
	
	BOOL change = _selectedMode != selectedIndex;
    _selectedIndex = selectedIndex;
    
    LZCameraFlashMode mode = LZCameraFlashModeAuto;
	NSString *imageName = @"media_flashlight_auto";
	switch (selectedIndex) {
		case 0: {
			imageName = @"media_flashlight_auto";
			mode = LZCameraFlashModeAuto;
		}
			break;
		case 1: {
			imageName = @"media_flashlight_on";
			mode = LZCameraFlashModeOn;
		}
			break;
		case 2: {
			imageName = @"media_flashlight_off";
			mode = LZCameraFlashModeOff;
		}
			break;
		default:
			break;
	}
	self.imgView.image = [self imageInBundle:imageName];
    self.selectedMode = mode;
	
	if (change) {
		
		if (self.TapToFlashModeHandler) {
			self.TapToFlashModeHandler(self.selectedMode);
		}
	}
}


/**
 展开折叠动画

 @param expand BOOL
 */
- (void)animationToExpand:(BOOL)expand {
    
    if (!expand) {
//        [self performDelegateSelectorIfSupported:@selector(flashControlWillCollapse)];
        [UIView animateWithDuration:0.2 animations:^{
            
            for (NSUInteger i = 0; i < self.labels.count; i++) {
                
                UILabel *label = self.labels[i];
                if (i < self.selectedIndex) {
                    label.frame = LEFT_SHRINK;
                } else if (i > self.selectedIndex) {
                    label.frame = RIGHT_SHRINK;
                } else if (i == self.selectedIndex) {
                    label.frame = MIDDLE_EXPANDED;
                }
            }
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.defaultWidth, self.frame.size.height);
        } completion:^(BOOL finished) {
//         [self performDelegateSelectorIfSupported:@selector(flashControlDidCollapse)];
        }];
    } else {
        
//        [self performDelegateSelectorIfSupported:@selector(flashControlWillExpand)];
        [UIView animateWithDuration:0.3 animations:^{
            
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.expandedWidth, self.frame.size.height);
            for (NSUInteger i = 0; i < self.labels.count; i++) {
                
                UILabel *label = self.labels[i];
                label.font = (i == self.selectedIndex) ? BOLD_FONT : NORMAL_FONT;
                label.frame = CGRectMake(BUTTON_SIZE + (i * BUTTON_SIZE), self.midY, BUTTON_SIZE, BUTTON_SIZE);
            }
        } completion:^(BOOL finished) {
//         [self performDelegateSelectorIfSupported:@selector(flashControlDidExpand)];
        }];
    }
}

@end
