//
//  TwitPicPicturePoster.m
//  Here-I-Am
//
//  Created by Michael Rockhold on 6/17/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "TwitPicPicturePoster.h"
#import "RCHTTPBody.h"

static NSURL* s_uploadURL = nil;

@interface TwitPicPicturePosterHTTPBody : RCHTTPBody
{
}
-(id)initWithBoundary:(NSString*)boundary pictureInfo:(id<PicturePostInfo>)picturePostInfo message:(NSString*)msg;
@end

@implementation TwitPicPicturePosterHTTPBody

-(id)initWithBoundary:(NSString*)boundary pictureInfo:(id<PicturePostInfo>)picturePostInfo message:(NSString*)msg
{
	if ( self = [super initWithBoundary:boundary] )
	{
			//TODO: obfuscate api key
		[self appendString:@"08c6d1f78d2b249cd629d031e1d0be1a" name:@"key"];
		
		[self appendData:picturePostInfo.pictureData 
						name:@"media" 
						type:picturePostInfo.contentType 
					filename:picturePostInfo.filename];
		
		if ( msg )
			[self appendString:msg name:@"message"];	
	}
	return self;
}
@end


@implementation TwitPicPicturePoster

-(NSURL*)uploadURL
{
	if ( nil == s_uploadURL )
		s_uploadURL = [[NSURL alloc] initWithString:@"http://api.twitpic.com/2/upload.xml"];
	return s_uploadURL;
}


-(NSData*)makeHTTPBodyData:(NSString*)boundary
{
	RCHTTPBody* body = [[TwitPicPicturePosterHTTPBody alloc] initWithBoundary:boundary pictureInfo:self.owner.picturePostInfo message:self.owner.comment];
	NSData* rv = [body data];
	[body release];
	return rv;
}

@end
