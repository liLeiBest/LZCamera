//
//  LZCameraCodePreviewView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/29.
//

#import "LZCameraCodePreviewView.h"
#import "LZCameraCodeScanView.h"

@interface LZCameraCodePreviewView()

@property (strong, nonatomic) NSMutableDictionary *codeLayers;
@property (weak, nonatomic) CAShapeLayer *boundsLayer;
@property (weak, nonatomic) LZCameraCodeScanView *scanView;
@property (assign, nonatomic) CGRect defaultRectForScanView;

@end
@implementation LZCameraCodePreviewView

// MARK: - Lazy Loading
- (NSMutableDictionary *)codeLayers {
    
    if (nil == _codeLayers) {
        _codeLayers = [NSMutableDictionary dictionary];
    }
    return _codeLayers;
}

// MARK: - Initialization
- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self setupScanViw];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        
        self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self setupScanViw];
    }
    return self;
}

// MARK: - Public
- (void)detectCodes:(NSArray<AVMetadataObject *> *)codes {
    
    if (0 == codes.count) {
        
        self.scanView.hidden = NO;
        self.scanView.frame = self.defaultRectForScanView;
    }
    NSArray *transformedCodes = [self transformedCodesFromCodes:codes];
    NSMutableArray *lostCodes = [self.codeLayers.allKeys mutableCopy];
    for (AVMetadataMachineReadableCodeObject *codeObject in transformedCodes) {
        
        NSString *stringCode = codeObject.stringValue;
        if (stringCode) {
            [lostCodes removeObject:stringCode];
        } else {
            continue;
        }
        
        CAShapeLayer *boundsLayer = nil;
        CAShapeLayer *cornersLayer = nil;
        NSArray *layers = self.codeLayers[stringCode];
        if (!layers) {
            
            boundsLayer = [self makeBoundsLayer];
            cornersLayer = [self makeCornersLayer];
            layers = @[boundsLayer, cornersLayer];
            self.codeLayers[stringCode] = layers;
            [self.previewLayer addSublayer:boundsLayer];
            [self.previewLayer addSublayer:cornersLayer];
        } else {
            
            boundsLayer = layers[0];
            cornersLayer = layers[1];
        }
        
        boundsLayer.path = [self bezierPathForBounds:codeObject.type == AVMetadataObjectTypeQRCode ? CGRectZero : codeObject.bounds].CGPath;
        cornersLayer.path = [self bezierPathForCorners:codeObject.corners].CGPath;
        self.scanView.hidden = codeObject.type != AVMetadataObjectTypeQRCode;
        self.scanView.frame = codeObject.bounds;
        break;
    }
    
    for (NSString *stringCode in lostCodes) {
        
        for (CAShapeLayer *layer in self.codeLayers[stringCode]) {
            [layer removeFromSuperlayer];
        }
        [self.codeLayers removeObjectForKey:stringCode];
    }
}

// MARK: - Private

- (void)setupScanViw {
    
    LZCameraCodeScanView *scanView = [[LZCameraCodeScanView alloc] init];
    scanView.backgroundColor = [UIColor clearColor];
    CGSize size = [UIScreen mainScreen].bounds.size;
    CGFloat w = 220.0f;
    CGFloat h = 220.0f;
    CGFloat x = (size.width - w) * 0.5;
    CGFloat y = (size.height - h) * 0.5f;
    self.defaultRectForScanView = (CGRect){x, y, w, h};
    scanView.frame = self.defaultRectForScanView;
    [self addSubview:scanView];
    self.scanView = scanView;
}


/**
 坐标系转换

 @param codes @[AVMetadataObject]
 @return NSArray
 */
- (NSArray *)transformedCodesFromCodes:(NSArray<AVMetadataObject *> *)codes {
    
    NSMutableArray *transformedCodes = [NSMutableArray arrayWithCapacity:codes.count];
    for (AVMetadataObject *codeObject in codes) {
        
        AVMetadataObject *transformedCode = [self.previewLayer transformedMetadataObjectForMetadataObject:codeObject];
        [transformedCodes addObject:transformedCode];
    }
    return [transformedCodes copy];
}

/**
 创建边框图层

 @return CAShapeLayer
 */
- (CAShapeLayer *)makeBoundsLayer {
    
    CAShapeLayer *boundsLayer = [CAShapeLayer layer];
    boundsLayer.strokeColor = [UIColor colorWithRed:0.172 green:0.671 blue:0.428 alpha:1.000].CGColor;
    boundsLayer.fillColor = [UIColor clearColor].CGColor;
    boundsLayer.lineWidth = 2.0f;
    return boundsLayer;
}

/**
 创建边框图层

 @return CAShapeLayer
 */
- (CAShapeLayer *)makeCornersLayer {
    
    CAShapeLayer *cornerLayer = [CAShapeLayer layer];
    cornerLayer.strokeColor = [UIColor clearColor].CGColor;
    cornerLayer.fillColor = [UIColor colorWithRed:0.190 green:0.753 blue:0.489 alpha:0.500].CGColor;
    cornerLayer.lineWidth = 2.0f;
    return cornerLayer;
}

/**
 创建UIBezierPath, 绘制边框

 @param bounds CGRect
 @return UIBezierPath
 */
- (UIBezierPath *)bezierPathForBounds:(CGRect)bounds {
    
    CGFloat adjust = 0.0f;
    CGRect rect = CGRectInset(bounds, -adjust, -adjust);
    
    return [UIBezierPath bezierPathWithRect:rect];
}

/**
 创建UIBezierPath, 绘制矩形

 @param corners NSArray
 @return UIBezierPath
 */
- (UIBezierPath *)bezierPathForCorners:(NSArray *)corners {
    
    UIBezierPath *bezierPath = [UIBezierPath bezierPath];
    for (NSUInteger i = 0; i < corners.count; i++) {
        
        CGPoint point = [self pointForCorner:corners[i]];
        if (i == 0) {
            [bezierPath moveToPoint:point];
        } else {
            [bezierPath addLineToPoint:point];
        }
    }
    [bezierPath closePath];
    return bezierPath;
}

/**
 把字典转换为点

 @param corner NSDictionary
 @return CGPoint
 */
- (CGPoint)pointForCorner:(NSDictionary *)corner {
    
    CGPoint point;
    CGPointMakeWithDictionaryRepresentation((__bridge CFDictionaryRef)corner, &point);
    return point;
}

@end
