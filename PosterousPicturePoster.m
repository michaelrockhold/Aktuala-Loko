//
//  PosterousPicturePoster.m
//  Here-I-Am
//
//  Created by Michael Rockhold on 6/17/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "PosterousPicturePoster.h"
#import "RCHTTPBody.h"

static NSURL* s_uploadURL = nil;

@interface PosterousPicturePosterHTTPBody : RCHTTPBody
{
}

-(id)initWithBoundary:(NSString*)boundary pictures:(NSArray*)pictures message:(NSString*)msg;

@end
@implementation PosterousPicturePosterHTTPBody

-(id)initWithBoundary:(NSString*)boundary pictures:(NSArray*)pictures message:(NSString*)msg
{
	if ( self = [super initWithBoundary:boundary] )
	{
		int i = 0;
		for (id<PicturePostInfo> ppi in pictures)
		{
			[self appendData:ppi.pictureData 
							name:[NSString stringWithFormat:@"media[%d]", i++] 
							type:ppi.contentType 
						filename:ppi.filename];
		}
		
		if ( msg )
			[self appendString:msg name:@"message"];	
		
			//[self appendString:body_of_post name:@"body"];	
		
			//"source" - Optional. The name of your application or website
		[self appendString:@"Aktuala Loko" name:@"source"];	
		
			//"sourceLink" - Optional. Link to your application or website
		[self appendString:@"http://www.rockholdco.com/RC/Aktuala_Loko.html" name:@"sourceLink"];	
	}
	return self;
}

@end


@implementation PosterousPicturePoster

-(NSURL*)uploadURL
{
	if ( nil == s_uploadURL )
		s_uploadURL = [[NSURL alloc] initWithString:@"http://posterous.com/api2/upload.xml"];
	return s_uploadURL;
}


-(NSData*)makeHTTPBodyData:(NSString*)boundary
{
	RCHTTPBody* body = [[PosterousPicturePosterHTTPBody alloc] initWithBoundary:boundary pictures:self.owner.picturePostInfoArray message:self.owner.comment];
	NSData* rv = [body data];
	[body release];
	return rv;
}

@end
