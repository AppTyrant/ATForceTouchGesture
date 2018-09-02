//
//  ATForceTouchGesture.m
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import "ATForceTouchGesture.h"

#if DEBUG
#define ATFTGLog( s, ... ) NSLog( @"<%s : (%d)> %@",__PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define ATFTGLog(s,...)
#endif

@interface ATForceTouchGesture()
{
    NSDate *_dateOfMouseDown;
    BOOL _isMouseDown;
    NSPoint _locationInMouseDown;
}

@property (nonatomic,readwrite) CGFloat stageTransition;

@end

@implementation ATForceTouchGesture

-(instancetype)initWithTarget:(id)target action:(SEL)action allowableMovement:(CGFloat)allowableMovement
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        _allowableMovement = allowableMovement;
    }
    return self;
}

#define DEFAULT_ALLOWABLE_MOVEMENT 1.5
-(instancetype)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        _allowableMovement = DEFAULT_ALLOWABLE_MOVEMENT;
    }
    return self;
}

-(instancetype)initWithTarget:(id)target action:(SEL)action
{
    return [self initWithTarget:target action:action allowableMovement:DEFAULT_ALLOWABLE_MOVEMENT];
}

-(void)reset
{
    _dateOfMouseDown = nil;
    _isMouseDown = NO;
    self.stageTransition = 0.0;
    [super reset];
}

-(void)mouseDown:(NSEvent*)event
{
    NSEventMask associatedEventMask = event.associatedEventsMask;
    NSEventMask maskPressureResult = (associatedEventMask & NSEventMaskPressure);
    
    if (maskPressureResult != NSEventMaskPressure)
    {
        //ATFTGLog(@"Fail, this device doesn't support force touch.");
        self.state = NSGestureRecognizerStateFailed;
        return;
    }
    if (self.view.isHiddenOrHasHiddenAncestor)
    {
        //ATFTGLog(@"Unexpected, got mouseDown but our view is hidden. Failing.");
        self.state = NSGestureRecognizerStateFailed;
        return;
    }
    if (event.clickCount == 2)
    {
        //ATFTGLog(@"Fail, no force press for double click.");
        self.state = NSGestureRecognizerStateFailed;
        return;
    }
    
    NSEventModifierFlags eventModifierFlagsClean = (event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask);
    BOOL isControlKeyDown = ((eventModifierFlagsClean & NSEventModifierFlagControl) == NSEventModifierFlagControl) ? YES : NO;
    BOOL isShiftKeyDown = ((eventModifierFlagsClean & NSEventModifierFlagShift) == NSEventModifierFlagShift) ? YES : NO;
    BOOL isCommandKeyDown = (eventModifierFlagsClean & NSEventModifierFlagCommand) == NSEventModifierFlagCommand ? YES : NO;
    if (isCommandKeyDown || isShiftKeyDown || isControlKeyDown)
    {
        //ATFTGLog(@"Fail because a modifier key is down.");
        self.state = NSGestureRecognizerStateFailed;
        return;
    }
    
    _dateOfMouseDown = [NSDate date];
    _isMouseDown = YES;
    _locationInMouseDown = event.locationInWindow;
    [super mouseDown:event];
}

-(void)pressureChangeWithEvent:(NSEvent*)event
{
    //According to WWDC video in 2015 they say pressureChangedWithEvent: could be called before mouse down. Wait until mouse down.
    if (!_isMouseDown)
    {
        ATFTGLog(@"Mouse not down yet. wait.");
        return;
    }
    
    CGPoint locationOfPressure = event.locationInWindow;
    CGFloat distanceFromOriginalMouseDown = hypot(_locationInMouseDown.x-locationOfPressure.x,
                                                  _locationInMouseDown.y-locationOfPressure.y);
    
    if (distanceFromOriginalMouseDown > self.allowableMovement)
    {
        if ([self _doFailOrCancelDependingOnCurrentState] == NSGestureRecognizerStateCancelled) { ATFTGLog(@"Cancel b/c mouse moved too far and we already started.");}
        else { ATFTGLog(@"Fail because mouse moved too far and we didn't start yet."); }
        return;
    }
    
    //A value of 0, 1, or 2, indicating the stage of a gesture event of type NSEventTypePressure.
    //Gesture events of type NSEventTypePressure can go through multiple stages. This property indicates the current stage of the event.
    switch (event.stage)
    {
            
        //If this property has a value of 0, there is not enough pressure being applied to initiate or continue with the gesture. Effectively, this value will exist only when an event ends, as some level of pressure will be applied throughout the gesture.
        case 0:
        {
            self.stageTransition = event.stageTransition;
            BOOL didEventPhaseEnd = ((event.phase & NSEventPhaseEnded) == NSEventPhaseEnded) ? YES : NO;
            BOOL didEventPhaseCancel = ((event.phase & NSEventPhaseCancelled) == NSEventPhaseCancelled) ? YES : NO;
            
            if (didEventPhaseEnd || didEventPhaseCancel)
            {
                //ATFTGLog(@"Fail. stage 0.");
                self.state = NSGestureRecognizerStateFailed;
            }
            else
            {
                //ATFTGLog(@"stage 0 but didn't end or cancel yet...unexpected. Failing anyway.");
                self.state = NSGestureRecognizerStateFailed;
            }
        }
        break;
            
        //A value of 1 indicates that the user has applied enough pressure to represent a mouse-down event.
        case 1:
        {
            CGFloat stageTransition = event.stageTransition;
            //ATFTGLog(@"Stage 1: set stage transition %f",stageTransition);
            self.stageTransition = stageTransition;

            if (self.state == NSGestureRecognizerStatePossible)
            {
                //ATFTGLog(@"Began");
                self.state = NSGestureRecognizerStateBegan;
            }
            else
            {
                //ATFTGLog(@"Changed");
                self.state = NSGestureRecognizerStateChanged;
            }
        }
        break;
           
        //A value of 2 suggests that the user has applied additional pressure beyond what is required for a typical mouse-down event. A stage value of 2 should generally be used to initiate a lookup or immediate action; for example, force clicking (pressing harder) on an element, such as a contact in an email message, to display a Quick Look window or to enter edit mode.
        case 2:
        {
            //ATFTGLog(@"Hit stage two!");
            self.stageTransition = event.stageTransition;
            self.state = NSGestureRecognizerStateEnded;
        }
        break;
            
        default:
        {
            ATFTGLog(@"Unexpected stage.");
        }
        break;
    }
}

-(void)mouseUp:(NSEvent*)event
{
    if ([self _doFailOrCancelDependingOnCurrentState] == NSGestureRecognizerStateCancelled)
    {
        //ATLog(@"Cancel in mouse up.");
    }
    else
    {
        //ATLog(@"Fail in mouse up.");
    }
}

-(NSTimeInterval)timeElapsedSinceMouseDownEvent
{
    NSTimeInterval timeSinceMouseDown = 0.0;
    if (_dateOfMouseDown != nil)
    {
        timeSinceMouseDown = [[NSDate date]timeIntervalSinceDate:_dateOfMouseDown];
    }
    else
    {
        ATFTGLog(@"_dateOfMouseDown is nil, must have called timeElapsedSinceMouseDownEvent before the mouseDown event. Returning 0.0");
    }
    return timeSinceMouseDown;
}

-(NSGestureRecognizerState)_doFailOrCancelDependingOnCurrentState
{
    if (self.state == NSGestureRecognizerStateBegan
        || self.state == NSGestureRecognizerStateChanged)
    {
        self.stageTransition = 0.0;
        self.state = NSGestureRecognizerStateCancelled;
        return NSGestureRecognizerStateCancelled;
    }
    else
    {
        self.stageTransition = 0.0;
        self.state = NSGestureRecognizerStateFailed;
        return NSGestureRecognizerStateFailed;
    }
}

@end
