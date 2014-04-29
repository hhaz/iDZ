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
#import "TestPlanLoadDZ.h"
#import "DangerZone.h"

#define kOverlayLimit 1000
#define kDZCheckFrequency 5

@interface TestPlanViewController : UIViewController <CLLocationManagerDelegate,NSFetchedResultsControllerDelegate,MKMapViewDelegate,UIGestureRecognizerDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *labelDistance;
@property (weak, nonatomic) IBOutlet UILabel *labelSpeed;
@property (weak, nonatomic) IBOutlet UIButton *buttonAltitude;
@property (weak, nonatomic) IBOutlet UIButton *buttonStart;
@property (weak, nonatomic) IBOutlet UIButton *buttonStop;
@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphView;
@property (weak, nonatomic) IBOutlet UIStepper *stepper;
@property (weak, nonatomic) IBOutlet UIProgressView *proximity;

@property (nonatomic , strong) CLLocationManager *locationManager;
@property (nonatomic, retain) RealTimePlot *graph;

@property (nonatomic, retain) NSTimer *dzTimer;
@property (nonatomic, retain) NSArray *dangerZones;
@property (nonatomic, retain) TestPlanLoadDZ *loadDZ;
@property (nonatomic, retain) TestPlanAppDelegate *appDelegate;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSString *tripId;

@property (nonatomic, retain) MKPolyline *routeLine;

@property (nonatomic) NSDate *lastUpdateTimeInterval;
- (IBAction) startUpdatingLocation;
- (IBAction) stopUpdatingLocation;

- (IBAction) showGraph;

@end
