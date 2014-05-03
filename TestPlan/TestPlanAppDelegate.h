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

@interface TestPlanAppDelegate : UIResponder <UIApplicationDelegate,UIAlertViewDelegate>
{
    UINavigationController *navigationController;
}

@property (strong, nonatomic) UIWindow *window;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, strong) AVAudioPlayer *theAudio;
@property (nonatomic, strong) NSMutableArray *soundDataArray;

@property (nonatomic, strong) UIAlertView *activityAlert;


- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
