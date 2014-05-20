//
//  TestPlanHistoryItemCell.h
//  TestPlan
//
//  Created by Hervé AZOULAY on 21/03/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface iDZHistoryItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *date;
@property (nonatomic, weak) IBOutlet UILabel *longitude;
@property (nonatomic, weak) IBOutlet UILabel *latitude;
@property (nonatomic, weak) IBOutlet UILabel *altitude;

@end
