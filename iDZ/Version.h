//
//  Version.h
//  iDZ
//
//  Created by Hervé AZOULAY on 26/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Version : NSManagedObject

@property (nonatomic, retain) NSString * version;
@property (nonatomic, retain) NSDate * created;

@end
