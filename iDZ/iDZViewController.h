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
#import "DangerZone.h"
#import "iDZUpdateAnnotationsFromServer.h"
#import "iDZAlertDZView.h"
#import "gameScene.h"

#define kOverlayLimit 1000
#define kDZCheckFrequency 5
#define kDZRefreshFrequency 300
#define kWidth 300 // width of rect vision

@interface iDZViewController : UIViewController <CLLocationManagerDelegate,NSFetchedResultsControllerDelegate,MKMapViewDelegate,UIGestureRecognizerDelegate,UIAlertViewDelegate,NSURLConnectionDelegate>
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
@property (nonatomic) double regionSize;
@property (weak, nonatomic) IBOutlet UILabel *isConnected;

@property (nonatomic , strong) CLLocationManager *locationManager;
@property (nonatomic , strong) CLHeading *head;
@property (nonatomic, retain) UIAlertView *activityAlert;
@property (nonatomic, retain) iDZUpdateAnnotationsFromServer *updateAnnot;

@property (nonatomic , strong) gameScene *mainScene;

@property (nonatomic , strong) iDZAlertDZView *alertView;

@property (nonatomic, retain) UIProgressView *proximityPopup;

@property (nonatomic, retain) UIViewController *viewInPopup;

@property (nonatomic, retain) NSTimer *dzTimer;
@property (nonatomic, retain) NSTimer *dzRefreshTimer;
@property (nonatomic, retain) NSArray *dangerZones;
@property (nonatomic, retain) NSMutableArray *dangerZonesLocalInfos;
@property (nonatomic, retain) iDZAppDelegate *appDelegate;

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (strong, nonatomic) NSString *tripId;

@property (strong, nonatomic) UIAlertView *alert;
@property (strong, nonatomic) UIAlertView *popup;

@property (nonatomic, retain) MKPolyline *routeLine;

@property (nonatomic) NSDate *lastUpdateTimeInterval;
- (IBAction) startUpdatingLocation;
- (IBAction) stopUpdatingLocation;

@end
