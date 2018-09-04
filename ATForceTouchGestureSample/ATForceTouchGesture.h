//
//  ATForceTouchGesture.h
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class ATForceTouchGesture;

@protocol ATForceTouchGestureDelegate <NSGestureRecognizerDelegate>

@optional
/**
 Sent to the delegate when there is a pressure event on the view but the gesture has not yet met the constraints set to enter the began phase and therefore is still in the possible state (see the requiredAmountOfTimeSinceMouseDownToEnterBeganPhase and minimumRequiredStageTransitionToEnterBeganPhase properties below). The delegate may want to implement this method to do view highlighting or table view row selection, especially if delaysPrimaryMouseButtonEvents is YES.
 */
-(void)forceTouchGesture:(nonnull ATForceTouchGesture*)forceTouchGesture receivedPressureEventNotMeetingBeganStateConstraints:(nonnull NSEvent*)pressureEvent;

@end

@interface ATForceTouchGesture : NSGestureRecognizer

-(nonnull instancetype)initWithTarget:(nullable id)target
                               action:(nullable SEL)action
                    allowableMovement:(CGFloat)allowableMovement NS_DESIGNATED_INITIALIZER;

-(nullable instancetype)initWithCoder:(nonnull NSCoder*)coder NS_DESIGNATED_INITIALIZER;

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

/**
 YES to allow the user to cancel the in-progress gesture recognizer by pressing down either shift, comamnd, or the control key, otherwise NO. @note If shift, command, or the control key is down at the time of mouseDown: the gesture recognizer will fail no matter what this property is set to. Default is YES.
 */
@property (nonatomic) IBInspectable BOOL canBeCancelledIfModifierKeyIsDown;

/**
@brief The required amount of time since mouse down that needs to pass before the gesture recognizer can enter the began state.
@discussion If the target view also handles other mouse events (for example, if mouse dragging on the view can start a dragging session), you may want to set this to property to small value so this gesture won't swallow other events if the view is only lightly pressed for a short period of time (you also probably need to set delaysPrimaryMouseButtonEvents to YES as well). You can experiment with this value a bit to get the right sensitivity. Assuming delaysPrimaryMouseButtonEvents is set to YES, once the gesture enters the began phase, it will swallow other mouse events, even if it is later cancelled (my experience on 10.13.6).
 @note This value is only used during stage 1 of the pressure event. If stage 2 is hit even before this threshold is met the gesture sets its state to NSGestureRecognizerStateEnded. See also: minimumRequiredStageTransitionToEnterBeganPhase.
 */
@property (nonatomic) NSTimeInterval requiredAmountOfTimeSinceMouseDownToEnterBeganPhase;

/**
@brief The minimum value the stageTransition property must reach before the gesture recognizer can enter the began state.
@discussion If the target view also handles other mouse events (for example, if mouse dragging on the view can start a dragging session), you may want to set this to property to small value so this gesture won't swallow other events if the view is only lightly pressed on for a short period of time (you also probably need to set delaysPrimaryMouseButtonEvents to YES as well). You can experiment with this value a bit to get the right sensitivity. Assuming delaysPrimaryMouseButtonEvents is set to YES, once the gesture enters the began phase, it will swallow other mouse events, even if it is later cancelled (my experience on 10.13.6).
 @note This value is only used during stage 1 of the pressure event. If stage 2 is hit even before this threshold is met the gesture sets its state to NSGestureRecognizerStateEnded. See also: requiredAmountOfTimeSinceMouseDownToEnterBeganPhase.
 */
@property (nonatomic) CGFloat minimumRequiredStageTransitionToEnterBeganPhase;

/* the gesture recognizer's delegate */
@property (nullable, weak) id <ATForceTouchGestureDelegate> delegate;

@end
