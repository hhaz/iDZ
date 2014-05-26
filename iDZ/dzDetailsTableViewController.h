//
//  dzDetailsTableViewController.h
//  iDZ
//
//  Created by Hervé AZOULAY on 26/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "iDZAppDelegate.h"

@interface dzDetailsTableViewController : UITableViewController
@property (weak, nonatomic) IBOutlet UILabel *dzVersion;
@property (weak, nonatomic) IBOutlet UILabel *nbrRecord;
@property (weak, nonatomic) IBOutlet UILabel *dateCreated;

@property (nonatomic, retain) iDZAppDelegate *appDelegate;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@end
