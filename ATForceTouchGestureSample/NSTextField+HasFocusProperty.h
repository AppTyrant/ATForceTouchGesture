//
//  NSTextField+HasFocusProperty.h
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTextField (HasFocusProperty)

@property (nonatomic,readonly) BOOL doesTextFieldHaveFocus;

@end
