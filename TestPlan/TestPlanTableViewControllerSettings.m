//
//  TestPlanTableViewControllerSettings.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanTableViewControllerSettings.h"
#import "downloadDZ.h"

@interface TestPlanTableViewControllerSettings ()

@end

@implementation TestPlanTableViewControllerSettings

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _dzServerURL.text = _appDelegate.dzServerURL;
    _frequency.text = [NSString stringWithFormat:@"%1.0f",_appDelegate.frequency];
    _tripSwitch.on = _appDelegate.saveTrip;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)setSaveTrip {
    _appDelegate.saveTrip = _tripSwitch.on;
}

-(IBAction)removeKeyBoard:(id)sender {
    if(sender == _frequency) {
        _appDelegate.frequency = [_frequency.text doubleValue];
    }
    if (sender == _dzServerURL) {
        _appDelegate.dzServerURL = _dzServerURL.text;
    }
    [sender resignFirstResponder];
}

-(IBAction)download {
    downloadDZ *download = [[downloadDZ alloc]init];
    
    [download downloadDZ];
}

@end
