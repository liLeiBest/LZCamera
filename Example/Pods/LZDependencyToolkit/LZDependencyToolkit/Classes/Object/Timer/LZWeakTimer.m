//
//  LZWeakTimer.m
//  LZDependencyToolkit
//
//  Created by Dear.Q on 2019/6/28.
//

#import "LZWeakTimer.h"
#import <libkern/OSAtomic.h>

#if OS_OBJECT_USE_OBJC
#define lz_gcd_property_qualifier strong
#define lz_release_gcd_object(object)
#else
#define lz_gcd_property_qualifier assign
#define lz_release_gcd_object(object) dispatch_release(object)
#endif

@interface LZWeakTimer() {
	struct {
		uint32_t timerIsInvalidated;
	} _timerFlags;
}

@property (nonatomic, assign) NSTimeInterval timeStart;
@property (nonatomic, assign) NSTimeInterval timeInterval;
@property (nonatomic, assign) BOOL repeats;
@property (nonatomic, copy) LZTimeEventHandler eventHandler;
@property (nonatomic, lz_gcd_property_qualifier) dispatch_queue_t privateSerialQueue;
@property (nonatomic, lz_gcd_property_qualifier) dispatch_source_t timer;

@end
@implementation LZWeakTimer

@synthesize tolerance = _tolerance;

// MARK: - Initialization
- (void)dealloc {
	
	[self invalidate];
	lz_release_gcd_object(_privateSerialQueue);
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p> time_interval=%f repeats=%d timer=%@",
			NSStringFromClass([self class]),
			self,
			self.timeInterval,
			self.repeats,
			self.timer];
}

- (void)setTolerance:(NSTimeInterval)tolerance {
	@synchronized(self) {
		if (tolerance != _tolerance) {
			
			_tolerance = tolerance;
			[self resetTimerProperties];
		}
	}
}

- (NSTimeInterval)tolerance {
	@synchronized(self) {
		return _tolerance;
	}
}

// MARK: - Public
- (instancetype)initWithStart:(NSTimeInterval)start
                     interval:(NSTimeInterval)interval
                      repeats:(BOOL)repeats
                        queue:(dispatch_queue_t)queue
                 eventHandler:(LZTimeEventHandler)handler {
    NSParameterAssert(queue);
    NSParameterAssert(handler);
    if ((self = [super init])) {
        
        self.timeStart = start;
        self.timeInterval = interval;
        self.repeats = repeats;
        self.eventHandler = handler;
        
        NSString *privateQueueName = [NSString stringWithFormat:@"com.lz.weaktimer.%p", self];
        self.privateSerialQueue = dispatch_queue_create([privateQueueName cStringUsingEncoding:NSASCIIStringEncoding], DISPATCH_QUEUE_SERIAL);
        dispatch_set_target_queue(self.privateSerialQueue, queue);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.privateSerialQueue);
    }
    return self;
}

+ (instancetype)scheduledTimerWithStart:(NSTimeInterval)start
                               interval:(NSTimeInterval)interval
                                repeats:(BOOL)repeats
                                  queue:(dispatch_queue_t)queue
                           eventHandler:(LZTimeEventHandler)handler {
    
    LZWeakTimer *timer = [[self alloc] initWithStart:start
                                            interval:interval
                                             repeats:repeats
                                               queue:queue
                                        eventHandler:handler];
    [timer schedule];
    return timer;
}

- (instancetype)initWithInterval:(NSTimeInterval)interval
                         repeats:(BOOL)repeats
                           queue:(dispatch_queue_t)queue
                    eventHandler:(LZTimeEventHandler)handler {
    return [self initWithStart:interval interval:interval repeats:repeats queue:queue eventHandler:handler];
}

+ (instancetype)scheduledTimerWithInterval:(NSTimeInterval)interval
                                   repeats:(BOOL)repeats
                                     queue:(dispatch_queue_t)queue
                              eventHandler:(LZTimeEventHandler)handler {
    return [self scheduledTimerWithStart:interval interval:interval repeats:repeats queue:queue eventHandler:handler];
}

- (void)schedule {
	
	[self resetTimerProperties];
	
	__weak LZWeakTimer *weakSelf = self;
	dispatch_source_set_event_handler(self.timer, ^{
		[weakSelf timerFired];
	});
	dispatch_resume(self.timer);
}

- (void)fire {
	[self timerFired];
}

- (void)invalidate {
	if (!OSAtomicTestAndSetBarrier(7, &_timerFlags.timerIsInvalidated)) {
		
		dispatch_source_t timer = self.timer;
		dispatch_async(self.privateSerialQueue, ^{
			
			dispatch_source_cancel(timer);
			lz_release_gcd_object(timer);
		});
	}
}

// MARK: - Private
- (void)resetTimerProperties {
	
    int64_t startInNanoseconds = (int64_t)(self.timeStart * NSEC_PER_SEC);
	int64_t intervalInNanoseconds = (int64_t)(self.timeInterval * NSEC_PER_SEC);
	int64_t toleranceInNanoseconds = (int64_t)(self.tolerance * NSEC_PER_SEC);
	dispatch_source_set_timer(self.timer,
							  dispatch_time(DISPATCH_TIME_NOW, startInNanoseconds),
							  (uint64_t)intervalInNanoseconds,
							  toleranceInNanoseconds);
}

- (void)timerFired {
	if (OSAtomicAnd32OrigBarrier(1, &_timerFlags.timerIsInvalidated)) {
		return;
	}
	if (self.eventHandler) {
		self.eventHandler();
	}
	if (!self.repeats) {
		[self invalidate];
	}
}

// MARK: - Deprecated
- (id)initWithTimeInterval:(NSTimeInterval)timeInterval
                   repeats:(BOOL)repeats
             dispatchQueue:(dispatch_queue_t)dispatchQueue
              eventHandler:(LZTimeEventHandler)eventHandler {
    return [self initWithInterval:timeInterval repeats:repeats queue:dispatchQueue eventHandler:eventHandler];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval
                                       repeats:(BOOL)repeats
                                 dispatchQueue:(dispatch_queue_t)dispatchQueue
                                  eventHandler:(LZTimeEventHandler)eventHandler {
    return [self scheduledTimerWithInterval:timeInterval repeats:repeats queue:dispatchQueue eventHandler:eventHandler];
}

@end
