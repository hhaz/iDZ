//
//  TestPlanHistoryTableView.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface iDZHistoryTableView : UITableViewController

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (strong, nonatomic) IBOutlet UITableView *historyTableView;

@property (strong, nonatomic) UIButton *currentButton;

@property (strong, nonatomic) NSMutableDictionary *content;
@property (strong, nonatomic) NSArray *sortedKeys;

@property (strong, nonatomic) UIRefreshControl *refresh;

@end
