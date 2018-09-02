//
//  NSTextField+HasFocusProperty.m
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import "NSTextField+HasFocusProperty.h"

@implementation NSTextField (HasFocusProperty)

-(BOOL)doesTextFieldHaveFocus
{
    NSWindow *window = self.window;
    
    //Don't have focus if we are not in a window.
    if (window == nil) { return NO; }
    
    //Don't have focus if firstResponder is not a NSTextView.
    id firstResponder = window.firstResponder;
    if (firstResponder == nil
        || ![firstResponder isKindOfClass:[NSTextView class]])
    {
        return NO;
    }
    
    NSTextView *fieldEditorTextView = firstResponder;
    id searchField = self;
    
    if ([window fieldEditor:NO forObject:self] == fieldEditorTextView
        && fieldEditorTextView.delegate == searchField)
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

@end
