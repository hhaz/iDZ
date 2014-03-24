//
//  Tracking.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 20/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Tracking : NSManagedObject

@property (nonatomic, retain) NSDate *dateandtime;
@property (nonatomic, retain) NSNumber *longitude;
@property (nonatomic, retain) NSNumber *latitude;
@property (nonatomic, retain) NSString *tripid;

@end
