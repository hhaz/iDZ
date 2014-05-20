//
//  TestPlanAnnotation.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZAnnotation.h"

@implementation iDZAnnotation

-(id) initWithTitle:(NSString *) title AndCoordinate:(CLLocationCoordinate2D)coordinate
{
    self = [super init];
    _title = title;
    _coordinate = coordinate;
    return self;
}

@end
