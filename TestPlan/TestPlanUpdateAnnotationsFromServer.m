//
//  TestPlanUpdateAnnotationsFromServer.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "TestPlanUpdateAnnotationsFromServer.h"
#import "TestPlanAnnotation.h"

@implementation TestPlanUpdateAnnotationsFromServer

-(void)updateAnnotations:(double)distance mapView:(MKMapView *)mapView{
    
    _mapView = mapView;

    _appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *restCallString = [NSString stringWithFormat:@"%@/api/findClosestDZ?latitude=%f&longitude=%f&distance=%f",_appDelegate.dzServerURL,_mapView.userLocation.location.coordinate.latitude, _mapView.userLocation.coordinate.longitude, distance];
    
    NSURL *restURL = [NSURL URLWithString:restCallString];
    NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL cachePolicy:0 timeoutInterval:3];
    
    if( currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
        _apiReturnXMLData = nil;
    }
    
    currentConnection = [[NSURLConnection alloc] initWithRequest:restRequest delegate:self];
    
    _apiReturnXMLData = [NSMutableData data];
}


- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;

}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];

}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
    NSError *nserr;
    
    NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:_apiReturnXMLData options:NSJSONReadingMutableContainers error:&nserr];
    
    if(jsonArray !=nil && jsonArray.count > 0 && nserr == nil && !([[jsonArray objectAtIndex:0] isEqual:[NSNull null]]))
    {
        for (int i=0; i<jsonArray.count; i++) {
            double latitude = [(NSNumber *)[[jsonArray objectAtIndex:i] objectForKey:@"latitude"] doubleValue];
            double longitude = [(NSNumber *)[[jsonArray objectAtIndex:i] objectForKey:@"longitude"] doubleValue];
            NSString *dzLabel = (NSString *)[[jsonArray objectAtIndex:i] objectForKey:@"description"];
            
            CLLocationCoordinate2D locationDZ;
            
            locationDZ.longitude    = longitude;
            locationDZ.latitude     = latitude;
            
            TestPlanAnnotation *annotationDZ = [[TestPlanAnnotation alloc]initWithTitle:dzLabel AndCoordinate:locationDZ];
            [_mapView addAnnotation:annotationDZ];
        }
    }
}

@end
