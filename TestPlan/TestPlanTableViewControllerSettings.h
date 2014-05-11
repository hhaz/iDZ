//
//  TestPlanTableViewControllerSettings.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TestPlanAppDelegate.h"

@interface TestPlanTableViewControllerSettings : UITableViewController

@property (nonatomic, retain) TestPlanAppDelegate *appDelegate;

@property (weak, nonatomic) IBOutlet UITextField *dzServerURL;
@property (weak, nonatomic) IBOutlet UITextField *frequency;
@property (weak, nonatomic) IBOutlet UISwitch *tripSwitch;
@property (weak, nonatomic) IBOutlet UIButton *go;
@property (weak, nonatomic) IBOutlet UITextField *maxAnnotations;

- (void)setSaveTrip;

-(IBAction)removeKeyBoard:(id)sender;

@end
