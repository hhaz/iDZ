//
//  Trip.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 31/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Trip : NSManagedObject

@property (nonatomic, retain) NSDate * dateandtime;
@property (nonatomic, retain) NSString * label;
@property (nonatomic, retain) NSString * tripid;
@property (nonatomic, retain) NSNumber * mileage;

@end
