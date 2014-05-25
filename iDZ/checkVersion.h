//
//  checkVersion.h
//  iDZ
//
//  Created by Hervé AZOULAY on 25/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "iDZAppDelegate.h"

@interface checkVersion : NSObject <NSURLConnectionDelegate>
{
    NSURLConnection *currentConnection;
}

@property (retain, nonatomic) NSMutableData *apiReturnXMLData;

@property (nonatomic, retain) iDZAppDelegate *appDelegate;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) UILabel *connectionInfo;

-(void)checkVersion:(UILabel *)text;
@end
