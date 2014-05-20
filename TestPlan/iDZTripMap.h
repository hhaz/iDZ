//
//  TestPlanTripMap.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 23/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface iDZTripMap : UIViewController <MKMapViewDelegate>

@property (strong, nonatomic) NSString *tripId;
@property (strong, nonatomic) NSArray *tracks;

@property (nonatomic, retain) MKPolyline *routeLine;
@property (nonatomic, retain) MKPolylineRenderer *routeLineView;

@property (weak, nonatomic) IBOutlet MKMapView *mapView;

@end
