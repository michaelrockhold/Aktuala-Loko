//
//  TwitterPost.h
//  StaticMapHere
//
//  Created by Michael Rockhold on 1/12/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "PicturePoster.h"

@protocol TwitterPostClient;


@interface TwitterPost : NSObject
{
	id<TwitterPostClient> m_poster;
	NSMutableData* m_serverResponse;
}

-(id)initWithPoster:(id<TwitterPostClient>)poster;

-(void)start;

@end

@protocol TwitterPostClient < PicturePoster >

-(void)twitterPostSendDidStart:(TwitterPost*)tp;
-(void)twitterPost:(TwitterPost*)tp sendReceivedHTTPResponseStatusCode:(int)statusCode;
-(void)twitterPost:(TwitterPost*)tp sendDidFail:(NSError*)error;
-(void)twitterPost:(TwitterPost*)tp sendDidEnd:(NSData*)serverResponse;

@end
