//
//  TestPlanTripMap.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 23/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanTripMap.h"
#import "Tracking.h"

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
    
    CLLocationCoordinate2D coordinateArray[_tracks.count];
    for(i=0;i<_tracks.count;i++)
    {
        Tracking *track = (Tracking *)_tracks[i];
        coordinateArray[i] = CLLocationCoordinate2DMake([track.latitude doubleValue], [track.longitude doubleValue]);
    }
    
    _routeLine = [MKPolyline polylineWithCoordinates:coordinateArray count:_tracks.count];
    [_mapView setVisibleMapRect:[_routeLine boundingMapRect]];
    [_mapView addOverlay:_routeLine];
    
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
