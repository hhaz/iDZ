//
//  downloadDZ.m
//  TestPlan
//
//  Created by Hervé AZOULAY on 03/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "downloadDZ.h"
#import "DangerZone.h"

@implementation downloadDZ

-(void)downloadDZ {
    _appDelegate = (TestPlanAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSString *restCallString = [NSString stringWithFormat:@"%@/api/findAllDZ",_appDelegate.dzServerURL];
    
    NSURL *restURL = [NSURL URLWithString:restCallString];
    NSURLRequest *restRequest = [NSURLRequest requestWithURL:restURL cachePolicy:0 timeoutInterval:3];
    
    if( currentConnection)
    {
        [currentConnection cancel];
        currentConnection = nil;
        self.apiReturnXMLData = nil;
    }
    
    currentConnection = [[NSURLConnection alloc] initWithRequest:restRequest delegate:self];
    
    _apiReturnXMLData = [NSMutableData data];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error {
    NSLog(@"URL Connection Failed!");
    currentConnection = nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
    NSError *nserr;
    int countRow = 0;
    
    NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:_apiReturnXMLData options:NSJSONReadingMutableContainers error:&nserr];
    
    if(jsonArray !=nil && jsonArray.count > 0 && nserr == nil && !([[jsonArray objectAtIndex:0] isEqual:[NSNull null]]))
    {
        _managedObjectContext = _appDelegate.managedObjectContext;
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:_managedObjectContext];
        [fetchRequest setEntity:entity];
        
        //Empty table
        NSArray *myObjectsToDelete = [_managedObjectContext executeFetchRequest:fetchRequest error:nil];
         
         for (DangerZone *objectToDelete in myObjectsToDelete) {
             countRow++;
             [_managedObjectContext deleteObject:objectToDelete];
         }
        
        NSLog(@"%d records deleted", countRow);
        
        countRow = 0;
        for (int i=0; i<jsonArray.count; i++) {
            if (![[jsonArray objectAtIndex:i] isEqual:[NSNull null]]) {
                DangerZone *newDZ = [[DangerZone alloc]initWithEntity:entity insertIntoManagedObjectContext:_managedObjectContext];
                
                newDZ.label = (NSString *)[[jsonArray objectAtIndex:i] objectForKey:@"description"];;
                newDZ.latitude = (NSNumber *)[[jsonArray objectAtIndex:i] objectForKey:@"latitude"];
                newDZ.longitude = (NSNumber *)[[jsonArray objectAtIndex:i] objectForKey:@"longitude"];
                
                NSError *error = nil;
                if (![_managedObjectContext save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
                else countRow++;
            }
        }
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"DownloadDZ" message:[NSString stringWithFormat:@"%d records imported", countRow] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

@end
