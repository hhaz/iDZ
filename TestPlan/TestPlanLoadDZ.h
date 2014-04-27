//
//  TestPlanLoadDZ.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 27/04/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestPlanAppDelegate.h"

@interface TestPlanLoadDZ : UIView <UIAlertViewDelegate>

@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain) TestPlanAppDelegate *appDelegate;
@property (nonatomic, retain) UIAlertView *activityAlert;

@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

- (void)checkDZ;

@end
