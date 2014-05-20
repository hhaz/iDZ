//
//  TestPlanlocationDetailsViewController.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface iDZlocationDetailsViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) NSNumber *longitude;
@property (weak, nonatomic) NSNumber *latitude;
@property (weak, nonatomic) NSNumber *altitude;


@end
