//
//  TestPlanViewController.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 19/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanAppDelegate.h"
#import "TestPlanViewController.h"
#import "Tracking.h"
#import "TestPlanHistoryTableView.h"

@interface TestPlanViewController ()

@end

@implementation TestPlanViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([CLLocationManager locationServicesEnabled]) {
        _locationManager = [[CLLocationManager alloc] init];
        _locationManager.delegate = self;
        _locationManager.distanceFilter = kCLDistanceFilterNone;
        _locationManager.desiredAccuracy = kCLLocationAccuracyBest;
    }
    
    [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    _mapView.zoomEnabled = YES;
    _mapView.scrollEnabled = YES;
    _mapView.userLocation.title = @"Me";
    
    _mapView.delegate = self;
    CLLocationCoordinate2D coordinateArray[2];
    _routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
    
    TestPlanAppDelegate *appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _lastUpdateTimeInterval = [NSDate date];
    
    self.managedObjectContext = appDelegate.managedObjectContext;
    
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    
    MKPolylineRenderer *routeLineView;
    
    routeLineView = [[MKPolylineRenderer alloc] initWithPolyline:_routeLine];
    routeLineView.fillColor = [UIColor blueColor];
    routeLineView.strokeColor = [UIColor blueColor];
    routeLineView.lineWidth = 5;
    
    return routeLineView;

}

-(void)startUpdatingLocation
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateandtime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    Tracking *newTracking = [[Tracking alloc]initWithEntity:entity insertIntoManagedObjectContext:[aFetchedResultsController managedObjectContext]];
    
    newTracking.dateandtime = [NSDate date];
    
    // Save the context.
    NSError *error = nil;
    if (![[aFetchedResultsController managedObjectContext] save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    else {
        _tripId = [self uuid];
    }
    _mapView.showsUserLocation = YES;
    [_locationManager startUpdatingLocation];
}

-(void)stopUpdatingLocation
{
    _mapView.showsUserLocation = NO;
    [_locationManager stopUpdatingLocation];
}

- (NSString *)uuid
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    return (__bridge NSString *)uuidStringRef;
}

- (void)insertNewObject:(CLLocation *)location
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    Tracking *newTracking = [[Tracking alloc]initWithEntity:entity insertIntoManagedObjectContext:context];
    
    newTracking.dateandtime = [NSDate date];
    newTracking.longitude = [NSNumber numberWithFloat:location.coordinate.longitude];
    newTracking.latitude = [NSNumber numberWithFloat:location.coordinate.latitude];
    newTracking.tripid = _tripId;
   
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Tracking" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateandtime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];

    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    NSLog(@"%lu records found", (unsigned long)self.fetchedResultsController.fetchedObjects.count);
    
    
    return _fetchedResultsController;
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    NSLog(@"Error : %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocationCoordinate2D zoomLocation;
    CLLocation *location = [locations lastObject];
    
    static CLLocationCoordinate2D coordinateArray[2];
    
    zoomLocation.latitude = location.coordinate.latitude;
    zoomLocation.longitude = location.coordinate.longitude;
    
    coordinateArray[1] = zoomLocation;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.05*METERS_PER_MILE, 0.05*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
    _mapView.userLocation.subtitle = [NSString stringWithFormat:@"Long : %f - Lat : %f", _mapView.userLocation.location.coordinate.longitude,_mapView.userLocation.coordinate.latitude];
    
    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:self.lastUpdateTimeInterval];
    
    if( distanceBetweenDates > 10)
    {
        [self insertNewObject:location];
        self.lastUpdateTimeInterval = [NSDate date];
    }
    
    if (coordinateArray[0].longitude != 0 || coordinateArray[0].latitude != 0) {
        _routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
        [_mapView addOverlay:self.routeLine];
    }
    
    if (_mapView.overlays.count > kOverlayLimit) {
        MKOverlayView *overlay = [[_mapView overlays] firstObject];
        [_mapView removeOverlay:(id)overlay];
    }
    coordinateArray[0] = zoomLocation;
    NSLog(@"Overlay count : %d", _mapView.overlays.count);

    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    if ([error code] == kCLErrorDenied) {
        //you had denied
    }
    [manager stopUpdatingLocation];
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender

{
    if ([[segue identifier] isEqualToString:@"historySegue"])
    {
        
        [self fetchedResultsController];
        
        NSError *error = nil;
        if (![self.fetchedResultsController performFetch:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        TestPlanHistoryTableView *historyView = [segue destinationViewController];
        
        historyView.managedObjectContext = self.managedObjectContext;
        historyView.fetchedResultsController = self.fetchedResultsController;
        
    }
    
}

- (void)viewWillAppear:(BOOL)animated {
  
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
