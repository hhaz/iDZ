//
//  TestPlanAltitudeHistory.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 06/04/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GradientScatterPlot.h"

@interface TestPlanAltitudeHistory : UIViewController

@property (weak, nonatomic) IBOutlet CPTGraphHostingView *graphView;

@property (strong, nonatomic) NSArray *tracks;
@property (nonatomic, retain) GradientScatterPlot *graph;

@end
