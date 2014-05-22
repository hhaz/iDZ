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
    _appDelegate = (iDZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
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
    UIAlertView *alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"DownloadDZ",nil) message:NSLocalizedString(@"Connection Failed", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
    currentConnection = nil;
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
}

-(void)waitPanel {
    _alert = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"DownloadDZ",nil) message:NSLocalizedString(@"Downloading data",nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [_alert show];
}

-(void)displayStatus:(NSNumber *)countRow {
    UIAlertView *displayStatus = [[UIAlertView alloc]initWithTitle:NSLocalizedString(@"DownloadDZ",nil) message:[NSString stringWithFormat:NSLocalizedString(@"%@ records imported",nil),countRow] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [displayStatus show];
}

-(void)updateData:(NSMutableData *)data {
    
    NSError *nserr;
    int countRow = 0;
    NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&nserr];
    
    NSManagedObjectContext *localMOC = [[NSManagedObjectContext alloc]init];
    
    [localMOC setPersistentStoreCoordinator:_appDelegate.persistentStoreCoordinator];
    
    if(jsonArray !=nil && jsonArray.count > 0 && nserr == nil && !([[jsonArray objectAtIndex:0] isEqual:[NSNull null]]))
    {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"DangerZone" inManagedObjectContext:localMOC];
        [fetchRequest setEntity:entity];
        
        //Empty table
        NSArray *myObjectsToDelete = [localMOC executeFetchRequest:fetchRequest error:nil];
        
        for (DangerZone *objectToDelete in myObjectsToDelete) {
            countRow++;
            [localMOC deleteObject:objectToDelete];
        }
        
        NSLog(@"%d records deleted", countRow);
        
        countRow = 0;
        for (int i=0; i<jsonArray.count; i++) {
            if (![[jsonArray objectAtIndex:i] isEqual:[NSNull null]]) {
                DangerZone *newDZ = [[DangerZone alloc]initWithEntity:entity insertIntoManagedObjectContext:localMOC];
                
                NSString *stringLat = [[jsonArray objectAtIndex:i] objectForKey:@"latitude"];
                NSString *stringLong = [[jsonArray objectAtIndex:i] objectForKey:@"longitude"];
                
                newDZ.label = (NSString *)[[jsonArray objectAtIndex:i] objectForKey:@"description"];;
                newDZ.latitude = [NSNumber numberWithDouble:[stringLat doubleValue]];
                newDZ.longitude = [NSNumber numberWithDouble:[stringLong doubleValue]];
                
                NSError *error = nil;
                if (![localMOC save:&error]) {
                    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                    abort();
                }
                else countRow++;
            }
        }
         NSLog(@"%d records added", countRow);
        [_alert dismissWithClickedButtonIndex:0 animated:YES];
        [self performSelectorOnMainThread:@selector(displayStatus:) withObject:[NSNumber numberWithDouble:countRow] waitUntilDone:YES];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;

    [self performSelectorOnMainThread:@selector(waitPanel) withObject:nil waitUntilDone:YES];
    
    [self performSelectorInBackground:@selector(updateData:) withObject:_apiReturnXMLData];
    
}

@end
