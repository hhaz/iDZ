//
//  checkVersion.m
//  iDZ
//
//  Created by Hervé AZOULAY on 25/05/2014.
//  Copyright (c) 2014 Hervé AZOULAY. All rights reserved.
//

#import "checkVersion.h"
#import "Version.h"

@implementation checkVersion

-(void)checkVersion:(UILabel *)text {
    _appDelegate = (iDZAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    _connectionInfo = text;
    
    NSString *restCallString = [NSString stringWithFormat:@"%@/api/checkVersion",_appDelegate.dzServerURL];
    
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
    currentConnection = nil;
    _appDelegate.serverVersion = nil;
    _appDelegate.dateCreated = nil;
    _connectionInfo.text = NSLocalizedString(@"Not connected",nil);
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse *)response {
    [self.apiReturnXMLData setLength:0];
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data {
    [self.apiReturnXMLData appendData:data];
}

-(void)updateData:(NSMutableData *)data {
    
    NSError *nserr;
    NSArray *jsonArray=[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&nserr];
    
    NSManagedObjectContext *localMOC = [[NSManagedObjectContext alloc]init];
    
    [localMOC setPersistentStoreCoordinator:_appDelegate.persistentStoreCoordinator];
    
    if(jsonArray != nil && jsonArray.count > 0 && nserr == nil && !([[jsonArray objectAtIndex:0] isEqual:[NSNull null]]))
    {
        NSString *version = [[jsonArray objectAtIndex:0] objectForKey:@"version"];
        NSString *dateCreated = [[jsonArray objectAtIndex:0] objectForKey:@"created"];
        
        _appDelegate.serverVersion = version;
        _appDelegate.dateCreated = dateCreated;
        
        if (_connectionInfo != nil) {
            _connectionInfo.text = NSLocalizedString(@"Connected",nil);
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    currentConnection = nil;
    
    [self performSelectorInBackground:@selector(updateData:) withObject:_apiReturnXMLData];
    
}

@end
