//
//  downloadDZ.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestPlanAppDelegate.h"

@interface downloadDZ : NSObject <NSURLConnectionDelegate>
{
    NSURLConnection *currentConnection;
}

@property (retain, nonatomic) NSMutableData *apiReturnXMLData;

@property (nonatomic, retain) TestPlanAppDelegate *appDelegate;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UIAlertView *alert;

- (void)downloadDZ;

@end
