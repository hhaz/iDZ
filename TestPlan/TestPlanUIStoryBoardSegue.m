//
//  TestPlanUIStoryBoardSegue.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanUIStoryBoardSegue.h"

@implementation TestPlanUIStoryBoardSegue

- (void)perform {
    UIViewController* source = (UIViewController *)self.sourceViewController;
    UIViewController* destination = (UIViewController *)self.destinationViewController;
    
    CGRect sourceFrame      = source.view.frame;
    sourceFrame.origin.x    = -sourceFrame.size.width +40;
    
    CGRect destFrame        = destination.view.frame;
    destFrame.origin.x      = destination.view.frame.size.width;
    destination.view.frame  = destFrame;
    
    destFrame.origin.x      = 40;
    
    [source.view.superview addSubview:destination.view];
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         source.view.frame      = sourceFrame;
                         destination.view.frame = destFrame;
                     }
                     completion:^(BOOL finished) {

                     }];
}

@end
