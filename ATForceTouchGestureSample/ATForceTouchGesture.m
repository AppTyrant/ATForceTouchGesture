//
//  ATForceTouchGesture.m
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//  Permission is hereby granted, free of charge, to any person obtaining a copy  of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//  The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "ATForceTouchGesture.h"

#if DEBUG
#define ATFTGLog( s, ... ) NSLog( @"<%s : (%d)> %@",__PRETTY_FUNCTION__, __LINE__, [NSString stringWithFormat:(s), ##__VA_ARGS__] )
#else
#define ATFTGLog(s,...)
#endif

#define DEFAULT_REQUIRED_AMOUNT_OF_TIMESINCE_MOUSEDOWN_TO_ENTER_BEGAN_PHASE 0.4
#define DEFAULT_MINIMUM_REQUIRED_STAGE_TRANSITION_TO_ENTER_BEGAN_PHASE 0.1

@interface ATForceTouchGesture()
{
    NSDate *_dateOfMouseDown;
    BOOL _isMouseDown;
    NSPoint _locationInMouseDown;
}

@property (nonatomic,readwrite) CGFloat stageTransition;

@end

@implementation ATForceTouchGesture
@dynamic delegate;

#pragma mark - Initializers
-(void)_doSetUpOnInitWithAllowableMovement:(CGFloat)allowableMovement
{
    _allowableMovement = allowableMovement;
    _canBeCancelledIfModifierKeyIsDown = YES;
    _requiredAmountOfTimeSinceMouseDownToEnterBeganPhase = DEFAULT_REQUIRED_AMOUNT_OF_TIMESINCE_MOUSEDOWN_TO_ENTER_BEGAN_PHASE;
    _minimumRequiredStageTransitionToEnterBeganPhase = DEFAULT_MINIMUM_REQUIRED_STAGE_TRANSITION_TO_ENTER_BEGAN_PHASE;
}

-(instancetype)initWithTarget:(id)target action:(SEL)action allowableMovement:(CGFloat)allowableMovement
{
    self = [super initWithTarget:target action:action];
    if (self)
    {
        [self _doSetUpOnInitWithAllowableMovement:allowableMovement];
    }
    return self;
}

#define DEFAULT_ALLOWABLE_MOVEMENT 1.5
-(instancetype)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self)
    {
        [self _doSetUpOnInitWithAllowableMovement:DEFAULT_ALLOWABLE_MOVEMENT];
    }
    return self;
}

-(instancetype)initWithTarget:(id)target action:(SEL)action
{
    return [self initWithTarget:target action:action allowableMovement:DEFAULT_ALLOWABLE_MOVEMENT];
}

#pragma mark - Reset
-(void)reset
{
    _dateOfMouseDown = nil;
    _isMouseDown = NO;
    self.stageTransition = 0.0;
    [super reset];
}

#pragma mark - Mouse Events
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
    
    if (doesEventHaveModifierKeyDown(event))
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
    if (self.canBeCancelledIfModifierKeyIsDown
        && doesEventHaveModifierKeyDown(event))
    {
        [self _doFailOrCancelDependingOnCurrentState];
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
                if ([self _shouldGestureEnterBeganPhaseCheckTimeAndStageTransitionConstraintsWithPressureEvent:event])
                {
                    ATFTGLog(@"Began");
                    self.state = NSGestureRecognizerStateBegan;
                }
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
        //ATFTGLog(@"Cancel in mouse up.");
    }
    else
    {
        //ATFTGLog(@"Fail in mouse up.");
    }
}

#pragma mark - Getters
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

#pragma mark - Private Helper Methods
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

static inline BOOL doesEventHaveModifierKeyDown(NSEvent *event)
{
    NSEventModifierFlags eventModifierFlagsClean = (event.modifierFlags & NSEventModifierFlagDeviceIndependentFlagsMask);
    BOOL isControlKeyDown = ((eventModifierFlagsClean & NSEventModifierFlagControl) == NSEventModifierFlagControl) ? YES : NO;
    BOOL isShiftKeyDown = ((eventModifierFlagsClean & NSEventModifierFlagShift) == NSEventModifierFlagShift) ? YES : NO;
    BOOL isCommandKeyDown = (eventModifierFlagsClean & NSEventModifierFlagCommand) == NSEventModifierFlagCommand ? YES : NO;
    if (isCommandKeyDown || isShiftKeyDown || isControlKeyDown)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

-(BOOL)_shouldGestureEnterBeganPhaseCheckTimeAndStageTransitionConstraintsWithPressureEvent:(NSEvent*)pressureEvent
{
    if (self.state == NSGestureRecognizerStatePossible)
    {
        if (self.requiredAmountOfTimeSinceMouseDownToEnterBeganPhase > 0.0)
        {
            NSTimeInterval timeElapsedSinceMouseDown = self.timeElapsedSinceMouseDownEvent;
            if (timeElapsedSinceMouseDown < self.requiredAmountOfTimeSinceMouseDownToEnterBeganPhase)
            {
                ATFTGLog(@"Don't enter began state because requiredAmountOfTimeSinceMouseDownToEnterBeganPhase threshold (%f) has not been met yet. Give the gesture more time to fail.",self.requiredAmountOfTimeSinceMouseDownToEnterBeganPhase);
                
                if ([self.delegate respondsToSelector:@selector(forceTouchGesture:receivedPressureEventNotMeetingBeganStateConstraints:)])
                {
                    [self.delegate forceTouchGesture:self receivedPressureEventNotMeetingBeganStateConstraints:pressureEvent];
                }
                
                return NO;
            }
        }
        if (self.minimumRequiredStageTransitionToEnterBeganPhase > 0.0)
        {
            CGFloat stageTransition = pressureEvent.stageTransition;
            if (stageTransition < self.minimumRequiredStageTransitionToEnterBeganPhase)
            {
                ATFTGLog(@"Don't enter began state because minimumRequiredStageTransitionToEnterBeganPhase threshold (%f) has not been met yet. Give the gesture more time to fail.",self.minimumRequiredStageTransitionToEnterBeganPhase);
                
                if ([self.delegate respondsToSelector:@selector(forceTouchGesture:receivedPressureEventNotMeetingBeganStateConstraints:)])
                {
                    [self.delegate forceTouchGesture:self receivedPressureEventNotMeetingBeganStateConstraints:pressureEvent];
                }
                
                return NO;
            }
        }
        
        //If we are here, we can enter the began phase. 
        return YES;
    }
    else
    {
        //If state is no longer possible, we already began.
        return NO;
    }
}

@end
