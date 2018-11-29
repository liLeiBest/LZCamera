//
//  LZCameraCodePreviewView.m
//  LZCamera
//
//  Created by Dear.Q on 2018/11/29.
//

#import "LZCameraCodePreviewView.h"

@interface LZCameraCodePreviewView()

@property (strong, nonatomic) NSMutableDictionary *codeLayers;

@end
@implementation LZCameraCodePreviewView

// MARK: - Lazy Loading
- (NSMutableDictionary *)codeLayers {
    
    if (nil == _codeLayers) {
        _codeLayers = [NSMutableDictionary dictionary];
    }
    return _codeLayers;
}

// MARK: - Public
- (void)detectCodes:(NSArray<AVMetadataObject *> *)codes {
    
    NSArray *transformedCodes = [self transformedCodesFromCodes:codes];
    NSMutableArray *lostCodes = [self.codeLayers.allKeys mutableCopy];
    for (AVMetadataMachineReadableCodeObject *codeObject in transformedCodes) {
        
        NSString *stringCode = codeObject.stringValue;
        if (stringCode) {
            [lostCodes removeObject:stringCode];
        } else {
            continue;
        }
        
        CAShapeLayer *cornersLayer = self.codeLayers[stringCode];
        if (!cornersLayer) {
            
            cornersLayer = [self makeCornersLayer];
            self.codeLayers[stringCode] = cornersLayer;
            [self.previewLayer addSublayer:cornersLayer];
        }
        cornersLayer.path = [self bezierPathForCorners:codeObject.corners].CGPath;
        cornersLayer.hidden = YES;
        [UIView animateWithDuration:0.15f
                              delay:0.0f
                            options:UIViewAnimationOptionCurveLinear
                         animations:^{
                             
                             cornersLayer.hidden = NO;
                             cornersLayer.transform = CATransform3DMakeScale(1.5, 1.5, 1.0);
                         } completion:^(BOOL finished) {
                             cornersLayer.transform = CATransform3DIdentity;
                         }];
    }
    
    for (NSString *stringCode in lostCodes) {
        
        CAShapeLayer *cornersLayer = self.codeLayers[stringCode];
        [cornersLayer removeFromSuperlayer];
        [self.codeLayers removeObjectForKey:stringCode];
    }
}

// MARK: - Private
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
- (CAShapeLayer *)makeCornersLayer {
    
    CAShapeLayer *cornerLayer = [CAShapeLayer layer];
    cornerLayer.strokeColor = [UIColor colorWithRed:0.172 green:0.671 blue:0.428 alpha:1.000].CGColor;
    cornerLayer.fillColor = [UIColor colorWithRed:0.190 green:0.753 blue:0.489 alpha:0.500].CGColor;
    cornerLayer.lineWidth = 2.0f;
    return cornerLayer;
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
