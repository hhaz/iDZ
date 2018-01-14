//
//  dzDetailsTableViewController.m
//  iDZ
//
//  Created by Hervé AZOULAY on 26/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "dzDetailsTableViewController.h"
#import "Version.h"

@interface dzDetailsTableViewController ()

@end

@implementation dzDetailsTableViewController

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
    _appDelegate = (iDZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _managedObjectContext = _appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entityDZ = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entityDZ];
    
    NSError *error;
    
    NSArray *dzArray = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error == nil)
    {
        _nbrRecord.text = [NSString stringWithFormat:@"%lu",(unsigned long)dzArray.count];
    }
    else {
        _nbrRecord.text = @"unknown";
    }
    
    NSEntityDescription *entityVersion = [NSEntityDescription entityForName:@"Version" inManagedObjectContext:_managedObjectContext];

    [fetchRequest setEntity:entityVersion];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MMM-dd"];
    
    NSArray *dzVersion = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    if(error == nil && dzVersion.count > 0)
    {
        Version *versionInfo = (Version *)dzVersion[0];
        
        _dzVersion.text = versionInfo.version;
        _dateCreated.text = [dateFormatter stringFromDate:versionInfo.created];
    }
    else {
        _dzVersion.text = NSLocalizedString(@"unknown", nil);

        _dateCreated.text = @"1970-Jan-01";
    }

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
