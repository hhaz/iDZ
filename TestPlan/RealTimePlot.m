//
//  RealTimePlot.m
//  CorePlotGallery
//

#import "RealTimePlot.h"

static const double kFrameRate = 5.0;  // frames per second

static const NSUInteger kMaxDataPoints = 52;
static NSString *const kPlotIdentifier = @"Data Source Plot";
static double maxAltitude = 100;
static double minAltitude = 0;

@implementation RealTimePlot

+(void)load
{
    [super registerPlotItem:self];
}

-(id)init
{
    if ( (self = [super init]) ) {
        plotData  = [[NSMutableArray alloc] initWithCapacity:kMaxDataPoints];
        dataTimer = nil;

        self.title   = @"Altitude";
        self.section = kLinePlots;
    }

    return self;
}

-(void)killGraph
{
    [dataTimer invalidate];
    //[dataTimer release];
    dataTimer = nil;

    [super killGraph];
}

-(void)generateData
{
    [plotData removeAllObjects];
    currentIndex = 0;
}

-(void)renderInLayer:(CPTGraphHostingView *)layerHostingView withTheme:(CPTTheme *)theme animated:(BOOL)animated
{
#if TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
    CGRect bounds = layerHostingView.bounds;
#else
    CGRect bounds = NSRectToCGRect(layerHostingView.bounds);
#endif

    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:bounds];
    [self addGraph:graph toHostingView:layerHostingView];
    [self applyTheme:theme toGraph:graph withDefault:[CPTTheme themeNamed:kCPTSlateTheme]];

    [self setTitleDefaultsForGraph:graph withBounds:bounds];
    [self setPaddingDefaultsForGraph:graph withBounds:bounds];

    graph.plotAreaFrame.paddingTop    = 5.0;
    graph.plotAreaFrame.paddingRight  = 5.0;
    graph.plotAreaFrame.paddingBottom = 15.0;
    graph.plotAreaFrame.paddingLeft   = 25.0;
    graph.plotAreaFrame.masksToBorder = YES;

    // Grid line styles
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineWidth = 0.75;
    majorGridLineStyle.lineColor = [[CPTColor colorWithGenericGray:0.2] colorWithAlphaComponent:0.75];

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineWidth = 0.25;
    minorGridLineStyle.lineColor = [[CPTColor whiteColor] colorWithAlphaComponent:0.1];

    // Axes
    // X axis
    CPTMutableTextStyle *labelTextStyleX = nil ;
    labelTextStyleX = [[CPTMutableTextStyle alloc]init];
    labelTextStyleX.color =[CPTColor blackColor];
    labelTextStyleX.fontSize = 8.0f ;
    
    CPTMutableLineStyle *majorTickStyle = [[CPTMutableLineStyle alloc]init];
    majorTickStyle.lineWidth = 1;
    
    CPTMutableLineStyle *minorTickStyle = [[CPTMutableLineStyle alloc]init];
    minorTickStyle.lineWidth = 0.5;

    
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
    CPTXYAxis *x          = axisSet.xAxis;
    x.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    x.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    x.majorGridLineStyle          = majorGridLineStyle;
    x.minorGridLineStyle          = minorGridLineStyle;
    x.minorTicksPerInterval       = 9;
    
    x.majorTickLength             = 4;
    x.majorTickLineStyle          = majorTickStyle;
    
    x.minorTickLength             = 3;
    x.minorTickLineStyle          = minorTickStyle;
    
    x.title                       = @"Time";
    x.titleOffset                 = 15.0;
    x.titleTextStyle              = labelTextStyleX;
    x.labelTextStyle              = labelTextStyleX;
    NSNumberFormatter *labelFormatter = [[NSNumberFormatter alloc] init];
    labelFormatter.numberStyle = NSNumberFormatterNoStyle;
    x.labelFormatter           = labelFormatter;

    // Y axis
    CPTXYAxis *y = axisSet.yAxis;
    CPTMutableTextStyle *labelTextStyleY = nil ;
    labelTextStyleY = [[CPTMutableTextStyle alloc]init];
    labelTextStyleY.color =[CPTColor blackColor];
    labelTextStyleY.fontSize = 8.0f ;

    y.labelingPolicy              = CPTAxisLabelingPolicyAutomatic;
    y.orthogonalCoordinateDecimal = CPTDecimalFromUnsignedInteger(0);
    y.majorGridLineStyle          = majorGridLineStyle;
    y.minorGridLineStyle          = minorGridLineStyle;
    y.minorTicksPerInterval       = 3;
    y.labelOffset                 = 1.0;
    y.title                       = @"";
    y.titleOffset                 = 15.0;
    y.labelTextStyle              = labelTextStyleY;
    y.titleTextStyle              = labelTextStyleY;
    
    y.majorTickLength             = 4;
    y.majorTickLineStyle          = majorTickStyle;
    
    y.minorTickLength             = 3;
    y.minorTickLineStyle          = minorTickStyle;
    
    y.axisConstraints             = [CPTConstraints constraintWithLowerOffset:0.0];
    
    y.labelFormatter = labelFormatter;

    // Rotate the labels by 45 degrees, just to show it can be done.
    x.labelRotation = M_PI_4;

    // Create the plot
    CPTScatterPlot *dataSourceLinePlot = [[CPTScatterPlot alloc] init];
    dataSourceLinePlot.identifier     = kPlotIdentifier;
    dataSourceLinePlot.cachePrecision = CPTPlotCachePrecisionDouble;

    CPTMutableLineStyle *lineStyle = [dataSourceLinePlot.dataLineStyle mutableCopy];
    lineStyle.lineWidth              = 1.0;
    lineStyle.lineColor              = [CPTColor blueColor];
    dataSourceLinePlot.dataLineStyle = lineStyle;

    dataSourceLinePlot.dataSource = self;
    [graph addPlot:dataSourceLinePlot];

    // Plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(0) length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(minAltitude) length:CPTDecimalFromUnsignedInteger(_altitude)];

    [dataTimer invalidate];

    if ( animated ) {
        dataTimer = [NSTimer timerWithTimeInterval:5.0 / kFrameRate
                                             target:self
                                           selector:@selector(newData:)
                                           userInfo:nil
                                            repeats:YES];
        [[NSRunLoop mainRunLoop] addTimer:dataTimer forMode:NSRunLoopCommonModes];
    }
    else {
        dataTimer = nil;
    }
}

-(void)dealloc
{
    [dataTimer invalidate];
}

#pragma mark -
#pragma mark Timer callback

-(void)newData:(NSTimer *)theTimer
{
    CPTGraph *theGraph = (self.graphs)[0];
    CPTPlot *thePlot   = [theGraph plotWithIdentifier:kPlotIdentifier];

    if ( thePlot ) {
        if ( plotData.count >= kMaxDataPoints ) {
            [plotData removeObjectAtIndex:0];
            [thePlot deleteDataInIndexRange:NSMakeRange(0, 1)];
        }
        
        if (_altitude > maxAltitude) {
            maxAltitude = _altitude;
        }
        
        if(_altitude < minAltitude)
        {
            minAltitude = _altitude;
        }

        CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)theGraph.defaultPlotSpace;
        NSUInteger location       = (currentIndex >= kMaxDataPoints ? currentIndex - kMaxDataPoints + 2 : 0);

        CPTPlotRange *oldXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger( (location > 0) ? (location - 1) : 0 )
                                                              length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];
        CPTPlotRange *newXRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(location)
                                                              length:CPTDecimalFromUnsignedInteger(kMaxDataPoints - 2)];

        [CPTAnimation animate:plotSpace
                     property:@"xRange"
                fromPlotRange:oldXRange
                  toPlotRange:newXRange
                     duration:CPTFloat(1.0 / kFrameRate)];
        
        plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromUnsignedInteger(minAltitude*1.1) length:CPTDecimalFromUnsignedInteger(maxAltitude*1.1)];

        currentIndex++;
        [plotData addObject:@(_altitude)];
        [thePlot insertDataAtIndex:plotData.count - 1 numberOfRecords:1];
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [plotData count];
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
    NSNumber *num = nil;

    switch ( fieldEnum ) {
        case CPTScatterPlotFieldX:
            num = @(index + currentIndex - plotData.count);
            break;

        case CPTScatterPlotFieldY:
            num = plotData[index];
            break;

        default:
            break;
    }

    return num;
}

@end
