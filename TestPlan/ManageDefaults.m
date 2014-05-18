//
//  ManageDefaults.m
//  DUiOS
//
//  Created by Hervé Azoulay on 10/06/12.
//  Copyright (c) 2012 Hervé Azoulay. All rights reserved.
//

#import "ManageDefaults.h"

@implementation ManageDefaults


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {

    }
    return self;
}

- (void)loadDefaults
{
    TestPlanAppDelegate *appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    appDelegate.saveTrip            = [defaults boolForKey:@"saveTrip"];
    appDelegate.dzServerURL         = [defaults objectForKey:@"dzServerURL"];
    appDelegate.frequency           = [defaults doubleForKey:@"frequency"];
    appDelegate.maxAnnotations      = [defaults doubleForKey:@"maxAnnotations"];
    appDelegate.newDZFileAvailable  = [defaults boolForKey:@"newDZFileAvailable"];
    appDelegate.warningDistance     = [defaults doubleForKey:@"warningDistance"];
    appDelegate.dzRadius            = [defaults doubleForKey:@"dzRadius"];
    appDelegate.alertDZ             = [defaults boolForKey:@"alertDZ"];
    
    appDelegate.defaultSaved        = [defaults boolForKey:@"defaultSaved"];
   if (appDelegate.defaultSaved == NO) {
       appDelegate.saveTrip = NO;
       appDelegate.dzServerURL = @"http://velhaz.hd.free.fr:3000";
       appDelegate.frequency = 10;
       appDelegate.maxAnnotations = 100;
       appDelegate.newDZFileAvailable = NO;
       appDelegate.warningDistance = 2000;
       appDelegate.dzRadius = 50;
       appDelegate.alertDZ = YES;
   }
    
}

- (void)saveDefaults
{
    TestPlanAppDelegate *appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    [defaults setBool:appDelegate.saveTrip forKey:@"saveTrip"];
    [defaults setObject:appDelegate.dzServerURL forKey:@"dzServerURL"];
    [defaults setDouble:appDelegate.frequency forKey:@"frequency"];
    [defaults setDouble:appDelegate.maxAnnotations forKey:@"maxAnnotations"];
    [defaults setBool:appDelegate.newDZFileAvailable forKey:@"newDZFileAvailable"];
    [defaults setDouble:appDelegate.warningDistance forKey:@"warningDistance"];
    [defaults setDouble:appDelegate.dzRadius forKey:@"dzRadius"];
    [defaults setBool:appDelegate.alertDZ forKey:@"alertDZ"];
    [defaults setBool:YES forKey:@"defaultSaved"];
    
    [defaults synchronize];

    
}


@end
