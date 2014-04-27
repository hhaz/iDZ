//
//  TestPlanLoadDZ.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 27/04/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanLoadDZ.h"
#import "DangerZone.h"

@implementation TestPlanLoadDZ

@synthesize managedObjectContext = _managedObjectContext;


- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)checkDZ
{
    _appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _managedObjectContext = _appDelegate.managedObjectContext;

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    //code to delete records in DangerZone
    /*NSArray *myObjectsToDelete = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    for (DangerZone *objectToDelete in myObjectsToDelete) {
        [_managedObjectContext deleteObject:objectToDelete];
    }*/
    
    NSError *err;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&err];
    
    if (count == 0) {
        
         _activityAlert = [[UIAlertView alloc]
                          initWithTitle:@"Danger Zone Locations Needs to be Updated"
                          message:@"Click OK and please wait"
                          delegate:self cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
       [_activityAlert show];
        
        
        // saving in core data in background seems ... tricky ... https://developer.apple.com/library/ios/documentation/cocoa/conceptual/coredata/Articles/cdConcurrency.html
        //[self performSelectorInBackground:@selector(loadDZ) withObject: nil];
        
    }
}

- (void)loadDZ
{
    
    NSError *err;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSArray *csvArray = [[NSBundle mainBundle] pathsForResourcesOfType:@"csv" inDirectory:nil];
    for(NSString *filePath in csvArray)
    {
        NSError *error;
        NSUInteger countRows = 0;
        
        NSString *csvData = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:&error];
        NSArray *rawData = [csvData componentsSeparatedByString:@"\n"];
        
        for(NSString *line in rawData)
        {
            NSArray *arrayValues = [line componentsSeparatedByString:@","];
            if (arrayValues.count > 2) {
                
                countRows++;
                
                DangerZone *newDZ = [[DangerZone alloc]initWithEntity:entity insertIntoManagedObjectContext:_managedObjectContext];
                
                newDZ.label           = arrayValues[2];
                newDZ.longitude       = [NSNumber numberWithFloat:[arrayValues[0] floatValue]];
                newDZ.latitude        = [NSNumber numberWithFloat:[arrayValues[1] floatValue]];
                // Save the context.
                NSError *error = nil;
                if (![_managedObjectContext save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        }
        NSLog(@"Loaded %d records for %@", countRows, filePath);
    }
    
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Loaded %d danger zones records", count);
    
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self loadDZ];
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
}


@end
