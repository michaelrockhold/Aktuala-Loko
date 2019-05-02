//
//  TwitPicPost.h
//  StaticMapHere
//
//  Created by Michael Rockhold on 1/12/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PicturePoster.h"

@protocol TwitPicPostClient;

@interface TwitPicPost : NSObject
{
	id<TwitPicPostClient> m_poster;	
	NSURL* m_twitpicAPIURL;
	NSMutableData* m_serverResponse;
}

-(id)initWithPoster:(id<TwitPicPostClient>)poster
	  twitpicAPIURL:(NSURL*)twitpicAPIURL;

-(void)start;

@end

@protocol TwitPicPostClient < PicturePoster >

-(void)twitPicPostSendDidStart:(TwitPicPost*)tp;
-(void)twitPicPost:(TwitPicPost*)tp sendReceivedHTTPResponseStatusCode:(int)statusCode;
-(void)twitPicPost:(TwitPicPost*)tp sendDidFail:(NSError*)error;
-(void)twitPicPost:(TwitPicPost*)tp sendDidEnd:(NSData*)serverResponse;

@end
