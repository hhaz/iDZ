//
//  TestPlanAnnotationView.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "iDZAnnotationView.h"
#import "iDZAnnotation.h"

static CGFloat kMaxViewWidth = 150.0;

static CGFloat kViewWidth = 100;
static CGFloat kViewLength = 40;

static CGFloat kLeftMargin = 15.0;
static CGFloat kRightMargin = 5.0;
static CGFloat kTopMargin = 5.0;
//static CGFloat kBottomMargin = 10.0;
static CGFloat kRoundBoxLeft = 10.0;

@interface iDZAnnotationView ()
@property (nonatomic, strong) UILabel *annotationLabel;
@property (nonatomic, strong) UIImageView *annotationImage;
@end


@implementation iDZAnnotationView

- (id)initWithAnnotation:(id <MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self != nil)
    {
        self.backgroundColor = [UIColor clearColor];
        
        // offset the annotation so it won't obscure the actual lat/long location
        self.centerOffset = CGPointMake(50.0, 50.0);
        
        // add the annotation's label
        _annotationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        iDZAnnotation *mapItem = (iDZAnnotation *)self.annotation;
        self.annotationLabel.font = [UIFont systemFontOfSize:9.0];
        self.annotationLabel.textColor = [UIColor whiteColor];
        self.annotationLabel.numberOfLines = 3;
        self.annotationLabel.text = mapItem.place;
        [self.annotationLabel sizeToFit];   // get the right vertical size
        
        // compute the optimum width of our annotation, based on the size of our annotation label
        CGFloat optimumWidth = self.annotationLabel.frame.size.width + kRightMargin + kLeftMargin;
        CGRect frame = self.frame;
        if (optimumWidth < kViewWidth)
            frame.size = CGSizeMake(kViewWidth, kViewLength);
        else if (optimumWidth > kMaxViewWidth)
            frame.size = CGSizeMake(kMaxViewWidth, kViewLength);
        else
            frame.size = CGSizeMake(optimumWidth, kViewLength);
        self.frame = frame;
        
        self.annotationLabel.lineBreakMode = NSLineBreakByClipping;
        self.annotationLabel.backgroundColor = [UIColor clearColor];
        CGRect newFrame = self.annotationLabel.frame;
        newFrame.origin.x = kLeftMargin;
        newFrame.origin.y = kTopMargin;
        newFrame.size.width = self.frame.size.width - kRightMargin - kLeftMargin;
        self.annotationLabel.frame = newFrame;
        [self addSubview:self.annotationLabel];
    }
    
    return self;
}

- (void)setAnnotation:(id <MKAnnotation>)annotation
{
    [super setAnnotation:annotation];
    
    // this annotation view has custom drawing code.  So when we reuse an annotation view
    // (through MapView's delegate "dequeueReusableAnnoationViewWithIdentifier" which returns non-nil)
    // we need to have it redraw the new annotation data.
    //
    // for any other custom annotation view which has just contains a simple image, this won't be needed
    //
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
    iDZAnnotation *mapItem = (iDZAnnotation *)self.annotation;
    if (mapItem != nil)
    {
        [[UIColor lightGrayColor] setFill];
        
        // draw the pointed shape
        UIBezierPath *pointShape = [UIBezierPath bezierPath];
        [pointShape moveToPoint:CGPointMake(14.0, 0.0)];
        [pointShape addLineToPoint:CGPointMake(0.0, 0.0)];
        [pointShape addLineToPoint:CGPointMake(self.frame.size.width, self.frame.size.height)];
        [pointShape fill];
        
        // draw the rounded box
        UIBezierPath *roundedRect =
        [UIBezierPath bezierPathWithRoundedRect:
         CGRectMake(kRoundBoxLeft, 0.0, self.frame.size.width - kRoundBoxLeft, self.frame.size.height) cornerRadius:3.0];
        roundedRect.lineWidth = 2.0;
        [roundedRect fill];
    }
}

@end
