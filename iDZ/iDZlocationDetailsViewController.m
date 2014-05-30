//
//  TestPlanlocationDetailsViewController.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZlocationDetailsViewController.h"
#import "iDZAppDelegate.h"
#import "iDZAnnotation.h"
#import "iDZAnnotationView.h"
#import <AddressBookUI/AddressBookUI.h>

@interface iDZlocationDetailsViewController ()

@end

@implementation iDZlocationDetailsViewController

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
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(coordinate, 100, 100);
    [_mapView setRegion:viewRegion animated:YES];
    
    iDZAnnotation *annotation = [[iDZAnnotation alloc]initWithTitle:[NSString stringWithFormat:@"Long : %f  Lat : %f",coordinate.longitude,coordinate.latitude]AndCoordinate:coordinate];
    
    annotation.place = [NSString stringWithFormat:@"Long. : %f \nLat. : %f \nAlt. : %@",coordinate.longitude,coordinate.latitude,_altitude];
    
    [_mapView addAnnotation:annotation];
    
    _geoCoder = [[CLGeocoder alloc]init];
    
}

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[MKUserLocation class]])
    {
        return nil;
    }
    else if ([annotation isKindOfClass:[iDZAnnotation class]]) // use whatever annotation class you used when creating the annotation
    {
        static NSString * const identifier = @"MyCustomAnnotation";
        
        iDZAnnotationView* annotationView = (iDZAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier:identifier];
        
        if (annotationView)
        {
            annotationView.annotation = annotation;
        }
        else
        {
            annotationView = [[iDZAnnotationView alloc] initWithAnnotation:annotation
                                                          reuseIdentifier:identifier];
        }
        UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
        [rightButton addTarget:self action:@selector(writeSomething) forControlEvents:UIControlEventTouchUpInside];
        [rightButton setTitle:@"GeoCoding" forState:UIControlStateNormal];
        annotationView.rightCalloutAccessoryView = rightButton;
        annotationView.canShowCallout = YES;
        
        return annotationView;
    }
    return nil;
}

- (void)writeSomething{
    CLLocation *dzLoc = [[CLLocation alloc]initWithLatitude:[_latitude doubleValue] longitude:[_longitude doubleValue]];
    
    [_geoCoder reverseGeocodeLocation:dzLoc completionHandler:
     ^(NSArray* placemarks, NSError* error){
         if ([placemarks count] > 0)
         {
             CLPlacemark *mark = placemarks[0];
             NSString *messageString = ABCreateStringWithAddressDictionary(mark.addressDictionary, YES);
             UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"GeoCoding" message:messageString delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
             [alert show];
         }
         if(error !=nil) {
             
             NSString *errorMessage = [error.userInfo valueForKeyPath:@"NSLocalizedDescription"];
             NSLog(@"%@",errorMessage);
         }
     }];
  }


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
