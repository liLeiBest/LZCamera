//
//  UIImageView+LZTouchRect.m
//  LZCamera
//
//  Created by Dear.Q on 2019/8/2.
//

#import "UIImageView+LZTouchRect.h"
#import <objc/runtime.h>

@implementation UIImageView (LZTouchRect)

//MARK: - runtime
+ (void)load {
	
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		
		SEL originSelector = @selector(pointInside:withEvent:);
		SEL swizzleSelector = @selector(LZ_pointInside:withEvent:);
		
		Method swizzleMethod = class_getInstanceMethod(self, swizzleSelector);
		IMP swizzleIMP = method_getImplementation(swizzleMethod);
		const char *swizzleType = method_getTypeEncoding(swizzleMethod);
		
		BOOL exist = class_addMethod(self, swizzleSelector, swizzleIMP, swizzleType);
		if (!exist) {
			class_replaceMethod(self, originSelector, swizzleIMP, swizzleType);
		} else {
			
			Method originMethod = class_getInstanceMethod(self, originSelector);
			method_exchangeImplementations(originMethod, swizzleMethod);
		}
	});
}

- (BOOL)LZ_pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	
	UIEdgeInsets edgeInsets = self.touchExtendInset;
	if (UIEdgeInsetsEqualToEdgeInsets(edgeInsets, UIEdgeInsetsZero) ||
		self.hidden ||
		([self isKindOfClass:UIControl.class] && !((UIControl *)self).enabled)) {
		return [super pointInside:point withEvent:event];
	}
	CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, edgeInsets);
	hitFrame.size.width = MAX(hitFrame.size.width, 0);
	hitFrame.size.height = MAX(hitFrame.size.height, 0);
	
	return CGRectContainsPoint(hitFrame, point);
}

//MARK: - Setter、Getter
- (void)setTouchExtendInset:(UIEdgeInsets)touchExtendInset {
	objc_setAssociatedObject(self, _cmd, [NSValue valueWithUIEdgeInsets:touchExtendInset], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)touchExtendInset {
	
	NSValue *value = objc_getAssociatedObject(self, @selector(setTouchExtendInset:));
	if (value) {
		return [value UIEdgeInsetsValue];
	} else {
		return UIEdgeInsetsZero;
	}
}

@end
