//
//  TestPlanAltitudeHistory.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 06/04/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZAltitudeHistory.h"

@interface iDZAltitudeHistory ()

@end

@implementation iDZAltitudeHistory

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    _graph = [[GradientScatterPlot alloc]init];
    
    _graph.tracks = _tracks;

    [_graph generateData];
    
    [_graph renderInLayer:_graphView withTheme:[CPTTheme themeNamed:kCPTSlateTheme] animated:YES];
        
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
