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
#import "TestPlanAnnotation.h"
#import "TestPlandzInfos.h"
#import "TestPlanUpdateAnnotationsFromServer.h"

static CLLocationCoordinate2D coordinateArray[2];
static CLLocationDistance distance = 0;
static double previousDist;
static bool playSound = YES;
static bool dzServerConnected = NO;
static NSMutableArray *dzNear;

@interface TestPlanViewController ()

@end

@implementation TestPlanViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    _stepper.hidden = YES;
    
    [self isDZLoaded];
    
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
    
    UIPinchGestureRecognizer *twoFingerPinch =
    [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    
    twoFingerPinch.delegate = self;
    [_mapView addGestureRecognizer:twoFingerPinch];
    
    _proximity.progress = 0;
    
    dzNear = [[NSMutableArray alloc]init];
    
    _isConnected.text = @"Not connected";
    
    _graphView.hidden = YES;
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchRecognizer {
    
    _stepper.value += 100 * - pinchRecognizer.velocity;
    
    if (pinchRecognizer.state == UIGestureRecognizerStateEnded) {
        [self updateAnnotations];
    }
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
    if(_appDelegate.saveTrip) {
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
    }
    [_locationManager startUpdatingLocation];
    _mapView.showsUserLocation = YES;
    distance = 0;
    _buttonStop.enabled = YES;
    _buttonStart.enabled = NO;
    
    _stepper.hidden = NO;
    
    previousDist = 2000;
    _proximity.progress = 0;
    
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
    _stepper.hidden = YES;
    [_locationManager stopUpdatingLocation];
    
    if(_appDelegate.saveTrip) {
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

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;
    dzServerConnected = NO;
    _isConnected.text = @"Not connected";
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];
    dzServerConnected = YES;
    _isConnected.text = @"Connected";
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
}

- (void)checkIfDzNear:(NSArray *)dzArray
{
    TestPlandzInfos *firstDZ = nil;
    double minDistance = 2000;
    
    for (TestPlandzInfos *dzCurrent in dzArray) {
        TestPlandzInfos *dzFound = nil;
        CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[dzCurrent.latitude doubleValue] longitude:[dzCurrent.longitude doubleValue]];
        double distance = [_mapView.userLocation.location distanceFromLocation:dzLoc];
        
        for (TestPlandzInfos *dzn in dzNear) {
            if ([dzn.latitude doubleValue] == [dzCurrent.latitude doubleValue] && [dzCurrent.longitude doubleValue] == [dzCurrent.longitude doubleValue] ) {
                dzFound = dzn;
            }
        }
        
        if (dzFound == nil) {
            dzCurrent.distance = [NSNumber numberWithDouble:-1]; // adding dz for the first time
            [dzNear addObject:dzCurrent];
            dzFound = [dzNear lastObject];
        }
        
        if(distance < minDistance && distance <= [dzFound.distance doubleValue])
        {
            minDistance = distance;
            firstDZ = dzCurrent;
        }
        if (distance > [dzFound.distance doubleValue] && [dzFound.distance doubleValue] != -1) {
            [dzNear removeObject:dzFound];
        }
        dzFound.distance = [NSNumber numberWithDouble:distance];
        
        TestPlanAnnotation *annotationDZ = [[TestPlanAnnotation alloc]initWithTitle:dzCurrent.description AndCoordinate:dzLoc.coordinate];
        [_mapView addAnnotation:annotationDZ];
    }
    if (firstDZ != nil) {
        CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[firstDZ.latitude doubleValue] longitude:[firstDZ.longitude doubleValue]];
        double distance = [_mapView.userLocation.location distanceFromLocation:dzLoc];
        
        if(playSound) {
            [_appDelegate.theAudio play];
            playSound = NO;
            _appDelegate.theAudio.rate = 1;
        }
        if (distance < previousDist) { //getting closer
            previousDist = distance;
            _proximity.progress = 1 - distance/2000;
            _proximityValue.text = [NSString stringWithFormat:@"%1.0f m",distance];
            if(distance < 500 ){
                playSound = YES;
                _appDelegate.theAudio.rate = 2;
            }
        }
        else {
            previousDist = 2000;
            playSound = YES;
            _proximity.progress = 0;
            _proximityValue.text = @"";
        }
    }
    else {
        previousDist = 2000;
        playSound = YES;
        _proximity.progress = 0;
        _proximityValue.text = @"";
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
    NSError *nserr;
    NSMutableArray *dzArray = [[NSMutableArray alloc]init];
    
    NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:_apiReturnXMLData options:NSJSONReadingMutableContainers error:&nserr];
    
    if(jsonArray !=nil && jsonArray.count > 0 && nserr == nil && !([[jsonArray objectAtIndex:0] isEqual:[NSNull null]]))
    {
        for (int i=0; i<jsonArray.count; i++) {
            if (![[jsonArray objectAtIndex:i] isEqual:[NSNull null]]) {
                double latitude = [(NSNumber *)[[jsonArray objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
                double longitude = [(NSNumber *)[[jsonArray objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
                NSString *dzLabel = (NSString *)[[jsonArray objectAtIndex:i] objectForKey:@"description"];
                
                TestPlandzInfos *dzCurrent = [[TestPlandzInfos alloc]init];
                
                dzCurrent.latitude = [NSNumber numberWithDouble:latitude];
                dzCurrent.longitude = [NSNumber numberWithDouble:longitude];
                dzCurrent.description = dzLabel;
                
                [dzArray addObject:dzCurrent];
            }
        }
    }
    [self checkIfDzNear:dzArray];
}


-(void)checkDZ:(NSTimer *)theTimer
{
    NSString *restCallString = [NSString stringWithFormat:@"%@/api/findClosestDZ?latitude=%f&longitude=%f&distance=%d", _appDelegate.dzServerURL,_mapView.userLocation.location.coordinate.latitude, _mapView.userLocation.coordinate.longitude, 2000];
    
    NSURL *restURL = [NSURL URLWithString:restCallString];
    NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL cachePolicy:0 timeoutInterval:3];
    
    if( currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
        self.apiReturnXMLData = nil;
    }
    
    currentConnection = [[NSURLConnection alloc] initWithRequest:restRequest delegate:self];
    
    _apiReturnXMLData = [NSMutableData data];
    
    if(!dzServerConnected) {
        NSMutableArray *dzArray = [[NSMutableArray alloc]init];
        for (DangerZone *dz in _dangerZones) {
            TestPlandzInfos *dzCurrent = [[TestPlandzInfos alloc]init];
            
            dzCurrent.latitude = dz.latitude;
            dzCurrent.longitude = dz.longitude;
            dzCurrent.description = dz.description ;
            
            [dzArray addObject:dzCurrent];
        }
        
        [self checkIfDzNear:dzArray];
    }
    
    [self updateAnnotations];
}

-(void)updateAnnotations {
    
    [_mapView removeAnnotations:_mapView.annotations];
    
    if(dzServerConnected || _buttonStart.enabled == YES)
    {
        MKMapRect mRect = _mapView.visibleMapRect;
        TestPlanUpdateAnnotationsFromServer *updateAnnot = [[TestPlanUpdateAnnotationsFromServer alloc]init];
        
        // get points of the visibleMapRect
        MKMapPoint eastMapPoint = MKMapPointMake(MKMapRectGetMinX(mRect), MKMapRectGetMidY(mRect));
        MKMapPoint westMapPoint = MKMapPointMake(MKMapRectGetMaxX(mRect), MKMapRectGetMidY(mRect));
        
        MKMapPoint northMapPoint = MKMapPointMake(MKMapRectGetMidX(mRect), MKMapRectGetMinY(mRect));
        MKMapPoint southMapPoint = MKMapPointMake(MKMapRectGetMidX(mRect), MKMapRectGetMaxY(mRect));
        
        CLLocationDistance widthDist = MKMetersBetweenMapPoints(eastMapPoint, westMapPoint);
        CLLocationDistance heightDist = MKMetersBetweenMapPoints(northMapPoint, southMapPoint);
        
        double maxDistance = 0;
        
        if (widthDist >= heightDist) {
            maxDistance = widthDist;
        } else {
            maxDistance = heightDist;
        }
        
        [updateAnnot updateAnnotations:maxDistance mapView:_mapView];
    }
    else {
        for (DangerZone *dz in _dangerZones) {
            CLLocationCoordinate2D locationDZ;
            
            locationDZ.longitude    = [dz.longitude doubleValue];
            locationDZ.latitude     = [dz.latitude doubleValue];
            
            if (MKMapRectContainsPoint(_mapView.visibleMapRect, MKMapPointForCoordinate(locationDZ))){
                TestPlanAnnotation *annotationDZ = [[TestPlanAnnotation alloc]initWithTitle:dz.label AndCoordinate:locationDZ];
                [_mapView addAnnotation:annotationDZ];
            }
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocationCoordinate2D zoomLocation;
    CLLocation *location = [locations lastObject];
    
    zoomLocation.latitude = location.coordinate.latitude;
    zoomLocation.longitude = location.coordinate.longitude;
    
    coordinateArray[1] = zoomLocation;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, _stepper.value, _stepper.value);
    [_mapView setRegion:viewRegion animated:YES];
    
    _mapView.userLocation.subtitle = [NSString stringWithFormat:@"Long : %f - Lat : %f", _mapView.userLocation.location.coordinate.longitude,_mapView.userLocation.coordinate.latitude];
    
    NSTimeInterval distanceBetweenDates = [[NSDate date] timeIntervalSinceDate:_lastUpdateTimeInterval];
    
    if( distanceBetweenDates > _appDelegate.frequency && location.horizontalAccuracy > 0 && _appDelegate.saveTrip)
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

- (void)isDZLoaded
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
        NSLog(@"Loaded %lu records for %@", (unsigned long)countRows, filePath);
    }
    
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Loaded %lu danger zones records", (unsigned long)count);
    
    _dangerZones = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self loadDZ];
    [alertView dismissWithClickedButtonIndex:0 animated:YES];
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
