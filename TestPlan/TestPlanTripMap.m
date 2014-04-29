//
//  TestPlanTripMap.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 23/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanTripMap.h"
#import "Tracking.h"
#import "TestPlanAppDelegate.h"
#import "TestPlanAnnotation.h"
#import "TestPlanAltitudeHistory.h"

@interface TestPlanTripMap ()

@end

@implementation TestPlanTripMap

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [_mapView setUserTrackingMode:MKUserTrackingModeFollowWithHeading];
    _mapView.zoomEnabled = YES;
    _mapView.scrollEnabled = YES;
    
    _mapView.delegate = self;
    
    _mapView.showsUserLocation = NO;
    
    integer_t i;
    
    if(_tracks.count > 1)
    {
        CLLocationCoordinate2D coordinateArray[_tracks.count];
        
        for(i=0;i<_tracks.count;i++)
        {
            Tracking *track = (Tracking *)_tracks[i];
            coordinateArray[i] = CLLocationCoordinate2DMake([track.latitude doubleValue], [track.longitude doubleValue]);
        }
        
        TestPlanAnnotation *annotationStart = [[TestPlanAnnotation alloc]initWithTitle:@"Start" AndCoordinate:coordinateArray[_tracks.count -1]];
        TestPlanAnnotation *annotationEnd = [[TestPlanAnnotation alloc]initWithTitle:@"End" AndCoordinate:coordinateArray[0]];
        
        [_mapView addAnnotation:annotationStart];
        [_mapView addAnnotation:annotationEnd];
        
        _routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:_tracks.count];
        [_mapView setVisibleMapRect:[_routeLine boundingMapRect]];
        [_mapView addOverlay:_routeLine];
    }
    else
    {
        CLLocationCoordinate2D coord;
        Tracking *track = (Tracking *)_tracks[0];
        coord = CLLocationCoordinate2DMake([track.latitude doubleValue], [track.longitude doubleValue]);
        MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coord, 100, 100);
        TestPlanAnnotation *annotationStart = [[TestPlanAnnotation alloc]initWithTitle:@"Start" AndCoordinate:coord];
        [_mapView addAnnotation:annotationStart];
        [_mapView setRegion:viewRegion animated:YES];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id < MKOverlay >)overlay
{
    if(overlay == self.routeLine)
    {
        if(nil == self.routeLineView)
        {
            _routeLineView = [[MKPolylineRenderer alloc] initWithPolyline:_routeLine];
            _routeLineView.fillColor = [UIColor blueColor];
            _routeLineView.strokeColor = [UIColor blueColor];
            _routeLineView.lineWidth = 5;
        }
        return _routeLineView;
    }
    
    return nil;
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
    
    static NSString *identifier = @"MyAnnotation";
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [_mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
    
    TestPlanAnnotation *myAnnotation = (TestPlanAnnotation*) annotation;
    
    if (annotationView == nil) {
        
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:myAnnotation reuseIdentifier:identifier];
        
        if ([myAnnotation.title isEqual: @"Start"]) {
            annotationView.pinColor = MKPinAnnotationColorGreen;
        }
        else {
            annotationView.pinColor = MKPinAnnotationColorRed;
        }
    }
    
    return annotationView;
}

-(void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender

{
    if ([[segue identifier] isEqualToString:@"segueAltitudeHisotry"])
    {
        
        TestPlanAltitudeHistory *historyAltitudeView = [segue destinationViewController];
        
        historyAltitudeView.tracks = _tracks;
        
    }
    
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
