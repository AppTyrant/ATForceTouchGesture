//
//  NSView+CenterProp.m
//  ATForceTouchGestureSample
//
//  Created by ANTHONY CRUZ on 9/2/18.
//  Copyright © 2018 ANTHONY CRUZ. All rights reserved.
//

#import "NSView+CenterProp.h"

@implementation NSView (CenterProp)

-(void)setCenter:(CGPoint)center
{
    CGRect frame = self.frame;
    frame.origin.x = center.x - frame.size.width / 2.0;
    frame.origin.y = center.y - frame.size.height / 2.0;
    self.frame = frame;
}

-(CGPoint)center
{
    CGRect frame = self.frame;
    return CGPointMake(frame.origin.x + (frame.size.width / 2.0), frame.origin.y + (frame.size.height / 2.0));
}

@end
