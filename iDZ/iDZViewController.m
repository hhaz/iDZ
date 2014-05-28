//
//  TestPlanViewController.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 19/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZAppDelegate.h"
#import "iDZViewController.h"
#import "Tracking.h"
#import "Trip.h"
#import "iDZAnnotation.h"
#import "iDZdzInfos.h"
#import "checkVersion.h"


static CLLocationCoordinate2D coordinateArray[2];
static CLLocationDistance distance = 0;
static double previousDist;
static bool dzServerConnected = NO;
static NSMutableArray *dzNear;
static iDZdzInfos *firstDZ = nil;
static iDZdzInfos *previousDZ = nil;

@interface iDZViewController ()

@end

@implementation iDZViewController

#pragma mark - Initialization

- (void)viewDidLoad
{
    [super viewDidLoad];

    checkVersion *check = [[checkVersion alloc]init];
    
    [check checkVersion:_isConnected];
    
    _appDelegate = (iDZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _lastUpdateTimeInterval = [NSDate date];
    
    _managedObjectContext = _appDelegate.managedObjectContext;
    
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
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    _dangerZones = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    _dangerZonesLocalInfos = [[NSMutableArray alloc]init];
    for (DangerZone *dz in _dangerZones) {
        iDZdzInfos *dzCurrent = [[iDZdzInfos alloc]init];
        
        dzCurrent.latitude = dz.latitude;
        dzCurrent.longitude = dz.longitude;
        dzCurrent.descDZ = dz.label ;
        
        [_dangerZonesLocalInfos addObject:dzCurrent];
    }
    
    UIPinchGestureRecognizer *twoFingerPinch =
    [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    
    twoFingerPinch.delegate = self;
    [_mapView addGestureRecognizer:twoFingerPinch];
    
    dzNear = [[NSMutableArray alloc]init];
    
    _updateAnnot = [[iDZUpdateAnnotationsFromServer alloc]init];
    
    _popup = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"DZ Alert !",nil)
                                                   message:@""
                                                  delegate:nil
                                         cancelButtonTitle:@"OK"
                                         otherButtonTitles:nil];
    
    _viewInPopup = [[UIViewController alloc]initWithNibName:@"viewInPopup" bundle:[NSBundle mainBundle]];
    
    _viewInPopup.view.frame = CGRectMake(0, 0, 210, 145);
    
    [_popup setValue:_viewInPopup.view forKey:@"accessoryView"];
    
    _alertView = (iDZAlertDZView *)_viewInPopup.view;
    
   _regionSize= _appDelegate.warningDistance *1.2;

}

#pragma mark - Gesture Management

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (void)handlePinchGesture:(UIPinchGestureRecognizer *)pinchRecognizer {
    
    _regionSize += 100 * - pinchRecognizer.velocity;
    
    if (pinchRecognizer.state == UIGestureRecognizerStateEnded) {
        [self updateAnnotations];
    }
}

#pragma mark - Route drawing

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    
    MKPolylineRenderer *routeLineView;
    
    routeLineView = [[MKPolylineRenderer alloc] initWithPolyline:_routeLine];
    routeLineView.fillColor = [UIColor blueColor];
    routeLineView.strokeColor = [UIColor blueColor];
    routeLineView.lineWidth = 5;
    
    return routeLineView;
    
}

#pragma mark - Location update

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
    [_locationManager startUpdatingHeading];
    _mapView.showsUserLocation = YES;
    distance = 0;
    _buttonStop.enabled = YES;
    _buttonStart.enabled = NO;
    
    previousDist = _appDelegate.warningDistance;
    
    if(_appDelegate.alertDZ) {
        
        _dzTimer = [NSTimer timerWithTimeInterval:kDZCheckFrequency
                                           target:self
                                         selector:@selector(checkDZ:)
                                         userInfo:nil
                                          repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_dzTimer forMode:NSRunLoopCommonModes];
        
        _dzRefreshTimer = [NSTimer timerWithTimeInterval:kDZRefreshFrequency
                                                  target:self
                                                selector:@selector(refreshLocalNearDZTimer:)
                                                userInfo:nil
                                                 repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:_dzRefreshTimer forMode:NSRunLoopCommonModes];
        
        [self refreshLocalNearDZ];
    }
    
}

-(void)stopUpdatingLocation
{
    _mapView.showsUserLocation = NO;
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

- (void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
    NSLog(@"Error : %@", error.localizedDescription);
}

- (void)locationManager:(CLLocationManager *)manager didUpdateHeading:(CLHeading *)newHeading
{
    _head = newHeading;
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocationCoordinate2D zoomLocation;
    CLLocation *location = [locations lastObject];
    
    zoomLocation.latitude = location.coordinate.latitude;
    zoomLocation.longitude = location.coordinate.longitude;
    
    coordinateArray[1] = zoomLocation;
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(zoomLocation, _regionSize, _regionSize);
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
            distanceString = [NSString localizedStringWithFormat:@"%.1F", distance/1000];
        }
        else {
            unit = @"m";
            distanceString = [NSString localizedStringWithFormat:@"%.1F", distance];
        }
        
        if (location.speed > 1) {
            unitSpeed = @"km/h";
            speedString = [NSString localizedStringWithFormat:@"%.1F", location.speed*3600/1000];
        }
        else {
            unitSpeed = @"m/s";
            speedString = [NSString localizedStringWithFormat:@"%.1F", location.speed];
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
        [_buttonAltitude setTitle:[NSString stringWithFormat:@"%1.0f",location.altitude] forState:UIControlStateNormal];
    }
    
    // Limit number of overlays when drawing the trip
    if (_mapView.overlays.count > kOverlayLimit) {
        MKOverlayView *overlay = [[_mapView overlays] firstObject];
        [_mapView removeOverlay:(id)overlay];
    }
    
    coordinateArray[0] = zoomLocation;
    
    if (firstDZ != nil && location.speed > 0.5) {
        
        CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[firstDZ.latitude doubleValue] longitude:[firstDZ.longitude doubleValue]];
        double distance = [_mapView.userLocation.location distanceFromLocation:dzLoc];
        
        _alertView.prox.progress = 1 - distance/_appDelegate.warningDistance;;
        _alertView.labelProx.text = [NSString stringWithFormat:@"%1.0f m",distance];
        _alertView.labelDZ.text = firstDZ.descDZ;
        _popup.message = firstDZ.descDZ;
        
        if([previousDZ.latitude doubleValue] != [firstDZ.latitude doubleValue] || [previousDZ.longitude doubleValue] != [firstDZ.longitude doubleValue]) {
            [_appDelegate.theAudio play];
            [_popup dismissWithClickedButtonIndex:0 animated:NO]; //dismiss the popup in case it's already displayed
            [_popup show];
        }
        previousDZ = firstDZ;
        if (distance <= previousDist) { //getting closer
            previousDist = distance;
            if(distance < _appDelegate.warningDistance/4 ){
                //_appDelegate.theAudio.rate = 2;
                //[_appDelegate.theAudio play];
            }
        }
        else {
            [_popup dismissWithClickedButtonIndex:0 animated:YES];
            previousDist = _appDelegate.warningDistance;
            firstDZ = nil;
        }
    }
    else {
        previousDist = _appDelegate.warningDistance;
    }
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
    NSLog(@"Error while getting core location : %@",[error localizedFailureReason]);
    if ([error code] == kCLErrorDenied) {
        //you had denied
        [self stopUpdatingLocation];
        _buttonStop.enabled = NO;
        _buttonStart.enabled = YES;
        
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error",nil) message:NSLocalizedString(@"Access to location service must be enabled",nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

#pragma mark - Core data management

- (NSString *)newUUID
{
    CFUUIDRef uuidRef = CFUUIDCreate(NULL);
    CFStringRef uuidStringRef = CFUUIDCreateString(NULL, uuidRef);
    CFRelease(uuidRef);
    NSString *uuid = CFBridgingRelease(uuidStringRef);
    return uuid;
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

#pragma mark - DZ Server connection & data retrieval

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;
    dzServerConnected = NO;
    _isConnected.text = NSLocalizedString(@"Not connected",nil);
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];
    dzServerConnected = YES;
    _isConnected.text = NSLocalizedString(@"Connected",nil);
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
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
                
                iDZdzInfos *dzCurrent = [[iDZdzInfos alloc]init];
                
                dzCurrent.latitude = [NSNumber numberWithDouble:latitude];
                dzCurrent.longitude = [NSNumber numberWithDouble:longitude];
                dzCurrent.descDZ = dzLabel;
                
                [dzArray addObject:dzCurrent];
            }
        }
    }
    [self checkIfDzNear:dzArray];
}

#pragma mark - DZ Detection

// This function helps restricting the number of dz to be considered by checkDZ when disconnected from the server. This function determines the DZ available aroung 100km. This improves a lot the performance when disconnected from server (the server is much faster than any iOS device ...for now !)
- (void)refreshLocalNearDZTimer:(NSTimer *)theTimer {
    [self refreshLocalNearDZ];
}

- (void)refreshLocalNearDZ {
    NSDate *startDate = [NSDate date];
    [_dangerZonesLocalInfos removeAllObjects];
    
    // put in _dangerZonesLocalInfos only DZ near by kDZProximityRadius meters to restrict the number of DZ to check
    
    for (DangerZone *dz in _dangerZones) {
        CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[dz.latitude doubleValue] longitude:[dz.longitude doubleValue]];
        double distance = [_mapView.userLocation.location distanceFromLocation:dzLoc];

        if(distance < _appDelegate.dzRadius * 1000)
        {
            iDZdzInfos *dzCurrent = [[iDZdzInfos alloc]init];
            
            dzCurrent.latitude = dz.latitude;
            dzCurrent.longitude = dz.longitude;
            dzCurrent.descDZ = dz.label ;
            
            [_dangerZonesLocalInfos addObject:dzCurrent];
        }
    }
    NSLog(@"refreshing local DZ array : %f for %lu records", [[NSDate date] timeIntervalSinceDate:startDate], (unsigned long)_dangerZonesLocalInfos.count);
}

- (void)checkIfDzNear:(NSArray *)dzArray
{
    NSDate *startDate = [NSDate date];
    double minDistance = _appDelegate.warningDistance;
    double count = 0;
    
    NSLog(@"Heading %f", _head.trueHeading);
    
    for (iDZdzInfos *dzCurrent in dzArray) {
        count++;
        iDZdzInfos *dzFound = nil;
        CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[dzCurrent.latitude doubleValue] longitude:[dzCurrent.longitude doubleValue]];
        double distance = [_mapView.userLocation.location distanceFromLocation:dzLoc];
        
        for (iDZdzInfos *dzn in dzNear) {
            if ([dzn.latitude doubleValue] == [dzCurrent.latitude doubleValue] && [dzCurrent.longitude doubleValue] == [dzCurrent.longitude doubleValue] ) {
                dzFound = dzn;
            }
        }
        
        if (distance < minDistance && dzFound == nil) {
            dzCurrent.distance = [NSNumber numberWithDouble:-1]; // adding dz for the first time
            [dzNear addObject:dzCurrent];
            dzFound = [dzNear lastObject];
        }
        
        if (dzFound != nil) {
            if(distance < minDistance && distance <= [dzFound.distance doubleValue])
            {
                minDistance = distance;
                firstDZ = dzCurrent;
            }
            if (distance > [dzFound.distance doubleValue] && [dzFound.distance doubleValue] != -1) {
                [dzNear removeObject:dzFound];
            }
            dzFound.distance = [NSNumber numberWithDouble:distance];
        }
        
    }
    NSLog(@"Computing near DZ Time : %1.3f for %f records", [[NSDate date] timeIntervalSinceDate:startDate],count);
}

-(void)checkDZ:(NSTimer *)theTimer
{
    NSDate *startDate = [NSDate date];
    
    NSString *restCallString = [NSString stringWithFormat:@"%@/api/findClosestDZ?latitude=%f&longitude=%f&distance=%f", _appDelegate.dzServerURL,_mapView.userLocation.location.coordinate.latitude, _mapView.userLocation.coordinate.longitude, _appDelegate.warningDistance];
    
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
        
        [self checkIfDzNear:_dangerZonesLocalInfos];
    }
    
    [self updateAnnotations];
    
    NSLog(@"Check DZ Time : %f", [[NSDate date] timeIntervalSinceDate:startDate]);
}

#pragma mark - Annotations management

-(void)updateAnnotations {
    
    NSDate *startDate = [NSDate date];
    double annotCount = 0;
    
    [_mapView removeAnnotations:_mapView.annotations];
    
    if(dzServerConnected)
    {
        MKMapRect mRect = _mapView.visibleMapRect;
        
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
        [_updateAnnot updateAnnotations:maxDistance mapView:_mapView];
    }
    else {
        for (DangerZone *dz in _dangerZones) {
            CLLocationCoordinate2D locationDZ;
            
            locationDZ.longitude    = [dz.longitude doubleValue];
            locationDZ.latitude     = [dz.latitude doubleValue];
            
            if (annotCount < _appDelegate.maxAnnotations) {
                if (MKMapRectContainsPoint(_mapView.visibleMapRect, MKMapPointForCoordinate(locationDZ))){
                    iDZAnnotation *annotationDZ = [[iDZAnnotation alloc]initWithTitle:dz.label AndCoordinate:locationDZ];
                    [_mapView addAnnotation:annotationDZ];
                    annotCount++;
                }
            }
            else {
                break;
            }
        }
    }
    NSLog(@"Updating Annot Time : %f", [[NSDate date] timeIntervalSinceDate:startDate]);
}

#pragma mark - Local DZ management

- (void)isDZLoaded
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError *err;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&err];
    
    if (count == 0) {
        
        _activityAlert = [[UIAlertView alloc]
                          initWithTitle:NSLocalizedString(@"No Danger Zone Information",nil)
                          message:NSLocalizedString(@"Download from settings",nil)
                          delegate:self cancelButtonTitle:NSLocalizedString(@"Close",nil)
                          otherButtonTitles:NSLocalizedString(@"Import",nil),nil];
        [_activityAlert show];
    }
}

-(void)waitPanel {
    _alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"ImportDZ",nil) message:NSLocalizedString(@"Importing data",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [_alert show];
}

-(void)importDZ {
    NSError *err;
    
    NSManagedObjectContext *localMOC = [[NSManagedObjectContext alloc]init];
    
    [localMOC setPersistentStoreCoordinator:_appDelegate.persistentStoreCoordinator];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:localMOC];
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
                
                DangerZone *newDZ = [[DangerZone alloc]initWithEntity:entity insertIntoManagedObjectContext:localMOC];
                
                newDZ.label           = arrayValues[2];
                newDZ.longitude       = [NSNumber numberWithFloat:[arrayValues[0] floatValue]];
                newDZ.latitude        = [NSNumber numberWithFloat:[arrayValues[1] floatValue]];
                // Save the context.
                NSError *error = nil;
                if (![localMOC save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
            }
        }
        NSLog(@"Loaded %lu records for %@", (unsigned long)countRows, filePath);
    }
    
    NSUInteger count = [localMOC countForFetchRequest:fetchRequest error:&err];
    NSLog(@"Loaded %lu danger zones records", (unsigned long)count);
    
    _dangerZones = [_appDelegate.managedObjectContext executeFetchRequest:fetchRequest error:nil];
    
    [self refreshLocalNearDZ];
    
     [_alert dismissWithClickedButtonIndex:0 animated:YES];
    
}

- (void)loadDZ
{
    
    [self performSelectorOnMainThread:@selector(waitPanel) withObject:nil waitUntilDone:YES];
    
    [self performSelectorInBackground:@selector(importDZ) withObject:nil];

}

- (void)willPresentAlertView:(UIAlertView *)alertView
{
    
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    switch (buttonIndex) {
        case 1:
            [self loadDZ];
            [alertView dismissWithClickedButtonIndex:1 animated:YES];
            break;
            
        default:
            [alertView dismissWithClickedButtonIndex:0 animated:YES];
            break;
    }
}

#pragma mark - Misc.

- (void)viewWillAppear:(BOOL)animated {
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];

}


@end
