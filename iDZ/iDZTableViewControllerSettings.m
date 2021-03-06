//
//  TestPlanTableViewControllerSettings.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZTableViewControllerSettings.h"
#import "downloadDZ.h"
#import "ManageDefaults.h"
#import "checkVersion.h"

@interface iDZTableViewControllerSettings ()

@end

@implementation iDZTableViewControllerSettings

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated {
    UITabBarItem *itemSettings = _appDelegate.tabBarController.tabBar.items[2];
    
    if(itemSettings.badgeValue != nil) {
        _dzLabel.textColor = [UIColor redColor];
    }
    else _dzLabel.textColor = [UIColor blackColor];
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (iDZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _dzServerURL.text = _appDelegate.dzServerURL;
    _frequency.text = [NSString stringWithFormat:@"%1.0f",_appDelegate.frequency];
    _maxAnnotations.text = [NSString stringWithFormat:@"%1.0f",_appDelegate.maxAnnotations];
    _warningDistance.text = [NSString stringWithFormat:@"%1.0f",_appDelegate.warningDistance];
    _radius.text = [NSString stringWithFormat:@"%1.0f",_appDelegate.dzRadius];
    _tripSwitch.on = _appDelegate.saveTrip;
    _dzSwitch.on = _appDelegate.alertDZ;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setSaveTrip {
    _appDelegate.saveTrip = _tripSwitch.on;
}

- (IBAction)setAlertDZ {
    _appDelegate.alertDZ = _dzSwitch.on;
}


-(IBAction)removeKeyBoard:(id)sender {

    if(sender == _frequency) {
        _appDelegate.frequency = [_frequency.text doubleValue];
    }
    if (sender == _dzServerURL) {
        _appDelegate.dzServerURL = _dzServerURL.text;
    }
    if (sender == _maxAnnotations) {
        _appDelegate.maxAnnotations = [_maxAnnotations.text doubleValue];
    }
    if (sender == _warningDistance) {
        _appDelegate.warningDistance = [_warningDistance.text doubleValue];
    }
    if (sender == _radius) {
        _appDelegate.dzRadius = [_radius.text doubleValue];
    }
    
    [sender resignFirstResponder];
}

-(IBAction)saveSettings:(id)sender {
    ManageDefaults *defaults = [[ManageDefaults alloc]init];
    
    [defaults saveDefaults];

}

-(IBAction)download {
    checkVersion *version = [[checkVersion alloc]init];
    [version checkVersion:nil];
    downloadDZ *download = [[downloadDZ alloc]init];
    
    [download downloadDZ];
    
    UITabBarItem *itemSettings = _appDelegate.tabBarController.tabBar.items[2];
    
    itemSettings.badgeValue = nil;
    
}

@end
