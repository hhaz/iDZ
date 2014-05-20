//
//  TestPlanUpdateAnnotationsFromServer.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
#import "iDZAppDelegate.h"

@interface iDZUpdateAnnotationsFromServer : NSObject <NSURLConnectionDelegate>
{
    NSURLConnection *currentConnection;
}

@property (retain, nonatomic) NSMutableData *apiReturnXMLData;
@property (retain, nonatomic) MKMapView *mapView;
@property (nonatomic, retain) iDZAppDelegate *appDelegate;

-(void)updateAnnotations:(double)distance mapView:(MKMapView *)mapView;

@end

