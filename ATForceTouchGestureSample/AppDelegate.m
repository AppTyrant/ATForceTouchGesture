//
//  AppDelegate.m
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import "AppDelegate.h"
#import "ATForceTouchGesture.h"
#import "NSTextField+HasFocusProperty.h"
#import "NSView+CenterProp.h"

@interface AppDelegate () <NSGestureRecognizerDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *label;
@property (weak) IBOutlet NSImageView *imageViewForForceClick;
@property (strong,nonatomic) NSSound *bottleSound;

@end

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    // Insert code here to initialize your application
    ATForceTouchGesture *forceTouchGesture = [[ATForceTouchGesture alloc]initWithTarget:self action:@selector(startEditingLabelAction:)];
    [self.label addGestureRecognizer:forceTouchGesture];
    forceTouchGesture.delegate = self;
}

#pragma mark - Force Click To Edit Label Related Methods
-(void)startEditingLabelAction:(ATForceTouchGesture*)sender
{
    switch (sender.state)
    {
        case NSGestureRecognizerStateBegan:
        case NSGestureRecognizerStateChanged:
        {
            self.label.backgroundColor = NSColor.alternateSelectedControlColor;
            self.label.textColor = NSColor.whiteColor;
        }
        break;
            
        case NSGestureRecognizerStateRecognized:
        {
            self.label.backgroundColor = NSColor.windowBackgroundColor;
            self.label.textColor = NSColor.labelColor;
            
            self.label.editable = YES;
            [self.window makeFirstResponder:self.label];
            
            [self.bottleSound play];
        }
        break;
            
        case NSGestureRecognizerStateCancelled:
        {
            NSLog(@"Cancelled, reset label's appearance.");
            self.label.backgroundColor = NSColor.windowBackgroundColor;
            self.label.textColor = NSColor.labelColor;
        }
        break;
            
        default:
        {
            NSLog(@"Gesture state: %li",sender.state);
        }
        break;
    }
}

#define LABEL_MIN_WIDTH 50.0
-(IBAction)windowBackgroundClicked:(NSClickGestureRecognizer*)sender
{
    [self _endLabelEditingAndRespositionItsFrame];
}

-(void)_endLabelEditingAndRespositionItsFrame
{
    CGPoint currentCenter = self.label.center;
    self.label.editable = NO;
    [self.window makeFirstResponder:nil];
    [self.label sizeToFit];
    if (self.label.frame.size.width < LABEL_MIN_WIDTH)
    {
        CGRect adjustedFrame = self.label.frame;
        adjustedFrame.size.width = LABEL_MIN_WIDTH;
        self.label.frame = adjustedFrame;
    }
    self.label.center = currentCenter;
}

#pragma mark - Force Click Image View
#define NATURAL_IMAGE_VIEW_RECT NSMakeRect(88.0,144.0,191.0,169.0)
-(IBAction)forceClickOnImageView:(ATForceTouchGesture*)sender
{
    if (self.label.doesTextFieldHaveFocus) { [self _endLabelEditingAndRespositionItsFrame]; }
    
    switch (sender.state)
    {
        case NSGestureRecognizerStateBegan:
        case NSGestureRecognizerStateChanged:
        {
            CGFloat stageTransition = sender.stageTransition;
            self.imageViewForForceClick.frame = doComputeImageViewRectWithStageTransition(stageTransition);
        }
        break;
            
        case NSGestureRecognizerStateRecognized:
        {
            //NSLog(@"Recognized!");
            [self.bottleSound play];
            
            CGRect growRect = doComputeImageViewRectWithStageTransition(1.0);
            
            [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context)
             {
                 context.duration = 0.2;
                 self.imageViewForForceClick.animator.frame = growRect;
             }
             completionHandler:^{
                 
                 [NSAnimationContext runAnimationGroup:^(NSAnimationContext * _Nonnull context)
                  {
                     context.duration = 0.2;
                     self.imageViewForForceClick.animator.frame = NATURAL_IMAGE_VIEW_RECT;
                  }
                  completionHandler:nil];
            }];
        }
        break;
            
        case NSGestureRecognizerStateCancelled:
        {
            NSLog(@"Cancelled.");
            self.imageViewForForceClick.animator.frame = NATURAL_IMAGE_VIEW_RECT;
        }
        break;
            
        case NSGestureRecognizerStateFailed:
        {
             NSLog(@"Failed? Unexpected documentation states that the gesture will not call its action method on failed.");
            self.imageViewForForceClick.animator.frame = NATURAL_IMAGE_VIEW_RECT;
        }
        break;
            
        default:
        {
            NSLog(@"Unexpected state.");
            self.imageViewForForceClick.animator.frame = NATURAL_IMAGE_VIEW_RECT;
        }
        break;
    }
}

static NSRect doComputeImageViewRectWithStageTransition(CGFloat stageTransition)
{
    static const CGFloat GrowAmount = 150.0;
    CGFloat growAmountClampedToTransion = GrowAmount * stageTransition;
    
    if (growAmountClampedToTransion <= 0.0)
    {
        //NSLog(@"natural size.");
        return NATURAL_IMAGE_VIEW_RECT;
    }
    else
    {
        CGRect rectForPop = NATURAL_IMAGE_VIEW_RECT;
        rectForPop.origin.x -= ceil((growAmountClampedToTransion/2.0));
        rectForPop.origin.y -= ceil((growAmountClampedToTransion/2.0));
        
        CGFloat width = ceil(rectForPop.size.width+growAmountClampedToTransion);
        CGFloat height = ceil(rectForPop.size.height+growAmountClampedToTransion);
        rectForPop.size.width = width;
        rectForPop.size.height = height;
        return rectForPop;
    }
}

#pragma mark - NSGestureRecognizerDelegate
-(BOOL)gestureRecognizerShouldBegin:(NSGestureRecognizer*)gestureRecognizer
{
    if (gestureRecognizer.view == self.label
        && [gestureRecognizer isKindOfClass:[ATForceTouchGesture class]])
    {
        if (!self.label.doesTextFieldHaveFocus)
        {
            return YES;
        }
        else
        {
            NSLog(@"Ignore pressure event. Text field already editing.");
            return NO;
        }
    }
    else
    {
        return YES;
    }
}

#pragma mark - Getters
-(NSSound*)bottleSound
{
     if (_bottleSound == nil)
     {
         _bottleSound = [NSSound soundNamed:@"Bottle"];
     }
     return _bottleSound;
}

@end
