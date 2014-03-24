//
//  TestPlanlocationDetailsViewController.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanlocationDetailsViewController.h"
#import "TestPlanAppDelegate.h"
#import "TestPlanAnnotation.h"
#import "TestPlanAnnotationView.h"

@interface TestPlanlocationDetailsViewController ()

@end

@implementation TestPlanlocationDetailsViewController

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
    CLLocationCoordinate2D coordinate;
    
    _mapView.delegate = self;
    
    coordinate.latitude = [_latitude doubleValue];
    coordinate.longitude = [_longitude doubleValue];

    [_mapView setCenterCoordinate:coordinate animated:YES];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 0.05*METERS_PER_MILE, 0.05*METERS_PER_MILE);
    [_mapView setRegion:viewRegion animated:YES];
    
    TestPlanAnnotation *annotation = [[TestPlanAnnotation alloc]initWithTitle:[NSString stringWithFormat:@"Long : %f  Lat : %f",coordinate.longitude,coordinate.latitude]AndCoordinate:coordinate];
    
    annotation.place = [NSString stringWithFormat:@"Long. : %f \nLat. : %f",coordinate.longitude,coordinate.latitude];
    
    [_mapView addAnnotation:annotation];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    else if ([annotation isKindOfClass:[TestPlanAnnotation class]]) // use whatever annotation class you used when creating the annotation
    {
        static NSString * const identifier = @"MyCustomAnnotation";
        
        TestPlanAnnotationView* annotationView = (TestPlanAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (annotationView)
        {
            annotationView.annotation = annotation;
        }
        else
        {
            annotationView = [[TestPlanAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifier];
        }
    
        annotationView.canShowCallout = YES;
        //annotationView.image = [UIImage imageNamed:@"ko.png"];
        
        return annotationView;
    }
    return nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
