//
//  RealTimePlot.h
//  CorePlotGallery
//

#import "PlotItem.h"

@interface RealTimePlot : PlotItem<CPTPlotDataSource>
{
    @private
    NSMutableArray *plotData;
    NSUInteger currentIndex;
    NSTimer *dataTimer;
}

@property  (nonatomic) double altitude;
-(void)newData:(NSTimer *)theTimer;

@end
