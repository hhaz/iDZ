//
//  TestPlanAppDelegate.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 19/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreData/CoreData.h>
#import <AVFoundation/AVFoundation.h>

@interface iDZAppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate>
{
    UINavigationController *navigationController;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) AVAudioPlayer *theAudio;
@property (nonatomic, strong) NSMutableArray *soundDataArray;
@property (nonatomic) Boolean saveTrip;
@property (nonatomic) Boolean alertDZ;
@property (nonatomic) Boolean newDZFileAvailable;
@property (nonatomic) double frequency;
@property (nonatomic) double warningDistance;
@property (nonatomic) double maxAnnotations;
@property (nonatomic) double dzRadius;
@property (nonatomic, strong) NSString *dzServerURL;
@property (nonatomic, strong) NSString *serverVersion;
@property (nonatomic, strong) NSString *dateCreated;
@property (nonatomic) Boolean defaultSaved;

@property (nonatomic, strong) UITabBarController *tabBarController;

@property (nonatomic, strong) UIAlertView *activityAlert;

@property (nonatomic, retain) NSArray *args;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
