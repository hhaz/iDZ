//
//  TestPlanTableViewControllerSettings.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iDZAppDelegate.h"

@interface iDZTableViewControllerSettings : UITableViewController

@property (nonatomic, retain) iDZAppDelegate *appDelegate;

@property (weak, nonatomic) IBOutlet UITextField *dzServerURL;
@property (weak, nonatomic) IBOutlet UITextField *frequency;
@property (weak, nonatomic) IBOutlet UISwitch *tripSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *dzSwitch;
@property (weak, nonatomic) IBOutlet UIButton *go;
@property (weak, nonatomic) IBOutlet UITextField *maxAnnotations;
@property (weak, nonatomic) IBOutlet UITextField *warningDistance;
@property (weak, nonatomic) IBOutlet UITextField *radius;
@property (weak, nonatomic) IBOutlet UILabel *dzLabel;

- (void)setSaveTrip;

-(IBAction)removeKeyBoard:(id)sender;

-(IBAction)saveSettings:(id)sender;

@end
