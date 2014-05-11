//
//  TestPlanViewController.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 19/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreData/CoreData.h>
#import "RealTimePlot.h"
#import "DangerZone.h"
#import "TestPlanUpdateAnnotationsFromServer.h"

#define kOverlayLimit 1000
#define kDZCheckFrequency 5

@interface TestPlanViewController : UIViewController <CLLocationManagerDelegate,NSFetchedResultsControllerDelegate,MKMapViewDelegate,UIGestureRecognizerDelegate,UIAlertViewDelegate,NSURLConnectionDelegate>
{
    NSURLConnection *currentConnection;
}

@property (retain, nonatomic) NSMutableData *apiReturnXMLData;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;
@property (weak, nonatomic) IBOutlet UILabel *labelSpeed;
@property (weak, nonatomic) IBOutlet UIButton *buttonAltitude;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart;
@property (weak, nonatomic) IBOutlet UIButton *buttonStop;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphView;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UIProgressView *proximity;
@property (weak, nonatomic) IBOutlet UILabel *proximityValue;
@property (weak, nonatomic) IBOutlet UILabel *isConnected;

@property (nonatomic , strong) CLLocationManager *locationManager;
@property (nonatomic, retain) RealTimePlot *graph;
@property (nonatomic, retain) UIAlertView *activityAlert;
@property (nonatomic, retain) TestPlanUpdateAnnotationsFromServer *updateAnnot;

@property (nonatomic, retain) NSTimer *dzTimer;
@property (nonatomic, retain) NSArray *dangerZones;
@property (nonatomic, retain) NSMutableArray *dangerZonesLocalInfos;
@property (nonatomic, retain) TestPlanAppDelegate *appDelegate;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSString *tripId;

@property (strong, nonatomic) UIAlertView *alert;

@property (nonatomic, retain) MKPolyline *routeLine;

@property (nonatomic) NSDate *lastUpdateTimeInterval;
- (IBAction) startUpdatingLocation;
- (IBAction) stopUpdatingLocation;

- (IBAction) showGraph;

@end
