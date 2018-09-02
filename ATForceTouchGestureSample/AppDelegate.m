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

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTextField *label;

@end

@implementation AppDelegate

-(void)applicationDidFinishLaunching:(NSNotification*)aNotification
{
    // Insert code here to initialize your application
    ATForceTouchGesture *forceTouchGesture = [[ATForceTouchGesture alloc]initWithTarget:self action:@selector(startEditingLabelAction:)];
    [self.label addGestureRecognizer:forceTouchGesture];
}

-(void)startEditingLabelAction:(ATForceTouchGesture*)sender
{
    if (self.label.doesTextFieldHaveFocus)
    {
        NSLog(@"Ignore pressure event. Text field already editing.");
        return;
    }
    
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

@end
