//
//  ATForceTouchGesture.h
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ATForceTouchGesture : NSGestureRecognizer

-(instancetype)initWithTarget:(id)target
                       action:(SEL)action
            allowableMovement:(CGFloat)allowableMovement NS_DESIGNATED_INITIALIZER;

-(instancetype)initWithCoder:(NSCoder*)coder NS_DESIGNATED_INITIALIZER;

/**
 As pressure increases for the gesture and a new stage approaches, this property provides a value between 0 and 1, indicating the approach of the next stage. When pressure is reduced for the gesture and a new stage is approached, this property provides a value between 0 and -1, indicating the approach of the current stage’s release.
 */
@property (nonatomic,readonly) CGFloat stageTransition;

/*
 Maximum movement allowed before the gesture fails.
 */
@property IBInspectable CGFloat allowableMovement;

/**
 @return The time elapsed since the initial mouse down event or 0 if mouseDown: hasn't happened yet.
 */
@property (nonatomic,readonly) NSTimeInterval timeElapsedSinceMouseDownEvent;

@end
