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
#import "Trip.h"
#import "DangerZone.h"
#import "TestPlanAnnotation.h"


static CLLocationCoordinate2D coordinateArray[2];
static CLLocationDistance distance = 0;

@interface TestPlanViewController ()

@end

@implementation TestPlanViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _loadDZ = [[TestPlanLoadDZ alloc] init];
    
    [_loadDZ checkDZ];
    
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
    CLLocationCoordinate2D coordinateArrayLocal[2];
    _routeLine = [MKPolyline polylineWithCoordinates:coordinateArrayLocal count:2];
    
    _appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _lastUpdateTimeInterval = [NSDate date];
    
    _managedObjectContext = _appDelegate.managedObjectContext;
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    _dangerZones = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    _graph = [[RealTimePlot alloc]init];
    _graph.altitude = _mapView.userLocation.location.altitude;

    [_graph renderInLayer:_graphView withTheme:[CPTTheme themeNamed:kCPTSlateTheme] animated:YES];
    
    
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
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"dateandtime" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];

    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:nil];
    
    Trip *newTrip = [[Trip alloc]initWithEntity:entity insertIntoManagedObjectContext:[aFetchedResultsController managedObjectContext]];
    
    newTrip.dateandtime = [NSDate date];
    newTrip.tripid      = [self newUUID];
    newTrip.mileage     = [NSNumber numberWithDouble:distance];
    
    // Save the context.
    NSError *error = nil;
    if (![[aFetchedResultsController managedObjectContext] save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    else {
        _tripId = newTrip.tripid;
    }
    _mapView.showsUserLocation = YES;
    distance = 0;
    _buttonStop.enabled = YES;
    _buttonStart.enabled = NO;
    [_locationManager startUpdatingLocation];
    
    _dzTimer = [NSTimer timerWithTimeInterval:kDZCheckFrequency
                                        target:self
                                      selector:@selector(checkDZ:)
                                      userInfo:nil
                                       repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_dzTimer forMode:NSRunLoopCommonModes];

}

-(void)stopUpdatingLocation
{
    _mapView.showsUserLocation = NO;
    [_locationManager stopUpdatingLocation];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Trip" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"tripid == %@",_tripId]];
    
    [fetchRequest setFetchBatchSize:20];
    
    NSError *error = nil;
    NSArray *resultArray = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    coordinateArray[0].latitude = 0;
    coordinateArray[1].latitude = 0;
    coordinateArray[0].longitude = 0;
    coordinateArray[1].longitude = 0;
    
    if (resultArray.count > 0) {
        Trip *localTrip = (Trip *)resultArray[0];
        localTrip.mileage = [NSNumber numberWithDouble:distance];
        
        NSError *errorUpdate = nil;
        if (![_managedObjectContext save:&errorUpdate]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
    
    _buttonStop.enabled = NO;
    _buttonStart.enabled = YES;
    [_dzTimer invalidate];
    _dzTimer = nil;
}

- (NSString *)newUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uuid = CFBridgingRelease(uuidStringRef);
    return uuid;
    //return (__bridge NSString *)uuidStringRef;
}

- (void)insertNewObject:(CLLocation *)location
{
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    
    Tracking *newTracking = [[Tracking alloc]initWithEntity:entity insertIntoManagedObjectContext:context];
    
    newTracking.dateandtime     = [NSDate date];
    newTracking.longitude       = [NSNumber numberWithFloat:location.coordinate.longitude];
    newTracking.latitude        = [NSNumber numberWithFloat:location.coordinate.latitude];
    newTracking.tripid          = _tripId;
    newTracking.altitude        = [NSNumber numberWithFloat:location.altitude];
   
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
    
    return _fetchedResultsController;
}

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    NSLog(@"Error : %@", error.localizedDescription);
}

-(void)checkDZ:(NSTimer *)theTimer
{
    
    for (DangerZone *dz in _dangerZones) {
        CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[dz.latitude doubleValue] longitude:[dz.longitude doubleValue]];
        if ([_mapView.userLocation.location distanceFromLocation:dzLoc] < 2000) {
            CLLocationCoordinate2D locationDZ;
            
            locationDZ.longitude = [dz.longitude doubleValue];
            locationDZ.latitude = [dz.latitude doubleValue];
            
            TestPlanAnnotation *annotationDZ = [[TestPlanAnnotation alloc]initWithTitle:dz.label AndCoordinate:locationDZ];
            [_mapView addAnnotation:annotationDZ];
            
            [_appDelegate.theAudio play];
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocationCoordinate2D zoomLocation;
    CLLocation *location = [locations lastObject];
    
    zoomLocation.latitude = location.coordinate.latitude;
    zoomLocation.longitude = location.coordinate.longitude;
    
    coordinateArray[1] = zoomLocation;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, 0.05*METERS_PER_MILE, 0.05*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
    
    _mapView.userLocation.subtitle = [NSString stringWithFormat:@"Long : %f - Lat : %f", _mapView.userLocation.location.coordinate.longitude,_mapView.userLocation.coordinate.latitude];
    
    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:_lastUpdateTimeInterval];
    
    if( distanceBetweenDates > 10 && location.horizontalAccuracy > 0)
    {
        [self insertNewObject:location];
        self.lastUpdateTimeInterval = [NSDate date];
    }
    
    if (coordinateArray[0].longitude != 0 || coordinateArray[0].latitude != 0) {
        _routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:2];
        [_mapView addOverlay:self.routeLine];
        
        // Compute mileage
        CLLocation *previousLocation = [[CLLocation alloc]initWithLatitude:coordinateArray[0].latitude longitude:coordinateArray[0].longitude];
        
        distance += ([location distanceFromLocation:previousLocation]);
        
        NSString *unit = @"m";
        NSString *unitSpeed = @"m/s";
        NSString *distanceString;
        NSString *speedString;
        
        if (distance > 1000) {
            unit = @"km";
            distanceString = [NSString localizedStringWithFormat:@"%.3F", distance/1000];
        }
        else {
            unit = @"m";
            distanceString = [NSString localizedStringWithFormat:@"%.3F", distance];
        }
        
        if (location.speed > 1) {
            unitSpeed = @"km/h";
            speedString = [NSString localizedStringWithFormat:@"%.3F", location.speed*3600/1000];
        }
        else {
            unitSpeed = @"m/s";
            speedString = [NSString localizedStringWithFormat:@"%.3F", location.speed];
        }

        _labelDistance.text = [NSString stringWithFormat:@"%@ %@",distanceString,unit];
        if(location.speed > 0)
        {
            _labelSpeed.text    = [NSString stringWithFormat:@"%@ %@",speedString,unitSpeed];
        }
        else {
            _labelSpeed.text    = @"";
        }
    }
    
    if(location.verticalAccuracy > 0)
    {
        [_buttonAltitude setTitle:[NSString stringWithFormat:@"Alt. : %1.0f",location.altitude] forState:UIControlStateNormal];
        _graph.altitude = location.altitude;
    }
    else
       _graph.altitude = 0.0;
    
    if (_mapView.overlays.count > kOverlayLimit) {
        MKOverlayView *overlay = [[_mapView overlays] firstObject];
        [_mapView removeOverlay:(id)overlay];
    }
    
    coordinateArray[0] = zoomLocation;
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    if ([error code] == kCLErrorDenied) {
        //you had denied
        [self stopUpdatingLocation];
        _buttonStop.enabled = NO;
        _buttonStart.enabled = YES;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Access to location service must be enabled" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
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

-(void) showGraph
{
    _graphView.hidden = ! _graphView.hidden;
}

- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
