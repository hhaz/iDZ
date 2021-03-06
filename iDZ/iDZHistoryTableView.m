//
//  TestPlanHistoryTableView.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZHistoryTableView.h"
#import "iDZHistoryItemCell.h"
#import "Tracking.h"
#import "iDZlocationDetailsViewController.h"
#import "iDZTripMap.h"
#import "Trip.h"
#import "iDZAppDelegate.h"

#define kHeaderHeight 25

@interface iDZHistoryTableView ()

@end

@implementation iDZHistoryTableView

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)refreshHistory
{
    NSError *error = nil;
    if (![_fetchedResultsController performFetch:&error]) {
        [_refresh endRefreshing];
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    else {
        [self updateContent];
        [self.tableView reloadData];
        [_refresh endRefreshing];
    }
}

- (void)updateContent
{
    NSMutableArray *dateArray = [[NSMutableArray alloc]init];
    [_content removeAllObjects];
    
    NSString *tripIdTemp = @"";
    
    if(_fetchedResultsController.fetchedObjects.count > 0)
    {
        for(Tracking *object in _fetchedResultsController.fetchedObjects)
        {
            if (![object.tripid isEqualToString:tripIdTemp] && (dateArray.count > 0)) {
                [_content setObject:[[NSArray alloc]initWithArray:dateArray] forKey:tripIdTemp];
                [dateArray removeAllObjects];
            }
            tripIdTemp = object.tripid;
            [dateArray addObject:object];
        }
            [_content setObject:dateArray forKey:tripIdTemp];
    
            NSArray *keys = [_content allKeys];
    
            _sortedKeys = [keys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            Tracking *track1 = (Tracking *)[[_content objectForKey:obj1] firstObject];
            Tracking *track2 = (Tracking *)[[_content objectForKey:obj2] firstObject];
        
            NSTimeInterval distanceBetweenDates = [track1.dateandtime timeIntervalSinceDate:track2.dateandtime];
        
            if (distanceBetweenDates > 0) {
                return NSOrderedAscending;
            }
            else
                return NSOrderedDescending;
        }];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(_refresh == nil)
    {
        _refresh = [[UIRefreshControl alloc]initWithFrame:CGRectMake(0, 0 , 220, 22)];
        NSAttributedString *title = [[NSAttributedString alloc]initWithString:NSLocalizedString(@"Refreshing History",nil)];
        _refresh.attributedTitle = title;
        [_refresh addTarget:self action:@selector(refreshHistory) forControlEvents:UIControlEventValueChanged];
    }
    
    [self.tableView addSubview:_refresh];
    _content = [[NSMutableDictionary alloc] init];
    
    _currentButton  = [[UIButton alloc]init];
    
    _currentButton.tag = -1;
    
     iDZAppDelegate *appDelegate = (iDZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _managedObjectContext = appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tracking" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateandtime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    _fetchedResultsController.delegate = self;
    
    [self refreshHistory];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[_content allKeys] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (_currentButton.tag == section) {
        if ([_currentButton.titleLabel.text isEqualToString:@"Closed"]) {
            [_currentButton setTitle:@"Open" forState:UIControlStateNormal];
            return [[_content objectForKey:[_sortedKeys objectAtIndex:section]] count];
        }
        else
        {
            [_currentButton setTitle:@"Closed" forState:UIControlStateNormal];
            return 0;
        }
    }
    else
    {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CustomCell";
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm:ss"];
    
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    
    iDZHistoryItemCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[iDZHistoryItemCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    Tracking *newTracking       = [[_content objectForKey:[_sortedKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
    NSString *stringFromDate    = [formatter stringFromDate:newTracking.dateandtime];
    
    cell.date.text      = stringFromDate;
    cell.longitude.text = [NSString stringWithFormat:@"Longitude : %@",newTracking.longitude];
    cell.latitude.text  = [NSString stringWithFormat:@"Latitude : %@",newTracking.latitude];
    cell.altitude.text  = [NSString stringWithFormat:@"Altitude : %@",newTracking.altitude];
    
    return cell;
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return kHeaderHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *aView =[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, kHeaderHeight)];
    [aView setBackgroundColor:[UIColor lightGrayColor]];
    UILabel *label = [[UILabel alloc]initWithFrame:CGRectMake(10, 0, self.view.frame.size.width -50, kHeaderHeight)];
    label.font = [UIFont fontWithName:@"Arial" size:12];
    aView.tag = 0;
    [aView addSubview:label];
    
    UIButton *toggleView = [[UIButton alloc]initWithFrame:CGRectMake(10, 0, self.view.frame.size.width / 2, kHeaderHeight)];
    toggleView.tag = section;
    [toggleView setTitleColor:[UIColor clearColor] forState:UIControlStateNormal];
    NSInteger rowCount = [_historyTableView numberOfRowsInSection:section];

    if (rowCount == 0) {
        [toggleView setTitle:@"Closed" forState:UIControlStateNormal];
    }
    else [toggleView setTitle:@"Open" forState:UIControlStateNormal];
    [aView addSubview:toggleView];
    
    UIButton *map = [[UIButton alloc]initWithFrame:CGRectMake( self.view.frame.size.width - 50 , 0, 50 , kHeaderHeight)];
    [map setTitle:NSLocalizedString(@"Map",nil) forState:UIControlStateNormal];
    map.titleLabel.font = [UIFont fontWithName:@"Arial" size:12];
    map.tag = section;
    [aView addSubview:map];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd/MM/yyyy HH:mm:ss"];
    
    [formatter setTimeZone:[NSTimeZone timeZoneWithName:@"..."]];
    
    NSString *tripId = [_sortedKeys objectAtIndex:section];
    
    // get mileage
    NSNumber *mileAge;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tripid == %@",tripId]];
    
    NSError *error = nil;
    NSArray *resultArray = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    Trip *localTrip;
    
    if (resultArray.count > 0) {
       localTrip = (Trip *)resultArray[0];
        mileAge = localTrip.mileage;
    }

    NSString *unit = @"m";
    NSString *distanceString;
    
    if ([mileAge doubleValue]  > 1000) {
        unit = @"km";
        distanceString = [NSString localizedStringWithFormat:@"%.3F", [mileAge doubleValue]/1000];
    }
    else {
        unit = @"m";
        distanceString = [NSString localizedStringWithFormat:@"%.3F", [mileAge doubleValue]];
    }
    
    NSString *dateHeader = [formatter stringFromDate:localTrip.dateandtime];
    NSString *tripHeader = [NSString stringWithFormat:@"%@ - %@ %@",dateHeader,distanceString,unit];
    
    label.text = tripHeader;
    [map addTarget:self action:@selector(sectionTapped:) forControlEvents:UIControlEventTouchDown];
    [toggleView addTarget:self action:@selector(toggleView:) forControlEvents:UIControlEventTouchDown];
    return aView;
}

- (void)sectionTapped:(UIButton*)btn {
    [self performSegueWithIdentifier:@"segueMap" sender:btn];
}

- (void)toggleView:(UIButton*)btn {
    
    _currentButton = btn;
    
    [_historyTableView reloadData];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender

{
    if ([[segue identifier] isEqualToString:@"segueLocationDetails"])
    {
        iDZlocationDetailsViewController *detailView = [segue destinationViewController];
        iDZHistoryItemCell *cell = (iDZHistoryItemCell *)sender;
        
        NSIndexPath *selectedIndexPath = [self.tableView indexPathForCell:cell];
        
        Tracking *newTracking = [[_content objectForKey:[_sortedKeys objectAtIndex: selectedIndexPath.section]] objectAtIndex:selectedIndexPath.row];
        
        detailView.longitude    = newTracking.longitude;
        detailView.latitude     = newTracking.latitude;
        detailView.altitude     = newTracking.altitude;
    }
    
    if ([[segue identifier] isEqualToString:@"segueMap"])
    {
        UIButton *btn = (UIButton *)sender;
        
        iDZTripMap *detailView = [segue destinationViewController];

        detailView.tracks = [_content objectForKey:[_sortedKeys objectAtIndex:btn.tag]];
        
    }

}

@end
