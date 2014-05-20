//
//  GradientScatterPlot.h
//  CorePlotGallery
//
//  Created by Jeff Buck on 8/2/10.
//  Copyright 2010 Jeff Buck. All rights reserved.
//

#import "PlotItem.h"

@interface GradientScatterPlot : PlotItem<CPTPlotAreaDelegate,
                                          CPTPlotSpaceDelegate,
                                          CPTPlotDataSource,
                                          CPTScatterPlotDelegate>
{
    @private
    CPTPlotSpaceAnnotation *symbolTextAnnotation;

    NSArray *plotData;
}
@property (strong, nonatomic) NSArray *tracks;
@property (strong, nonatomic) NSNumber *minAltitude;
@property (strong, nonatomic) NSNumber *maxAltitude;

@end
