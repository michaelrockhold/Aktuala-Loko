//
//  TwitPicPost.m
//  StaticMapHere
//
//  Created by Michael Rockhold on 1/12/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "TwitPicPost.h"
#import "NSData+Base64.h"

@implementation TwitPicPost

-(id)initWithPoster:(PicturePoster<TwitPicPostClient>*)poster
twitpicAPIURL:(NSURL*)twitpicAPIURL
{
	if ( self = [self init] )
	{
		m_poster = [poster retain];
		m_twitpicAPIURL = [twitpicAPIURL retain];
		m_serverResponse = nil;
	}
	return self;
}

-(void)dealloc
{
	[m_poster release];
	[m_twitpicAPIURL release];
	[m_serverResponse release];
	[super dealloc];
}

- (void)start
{	
		// Calculate the multipart/form-data body.  For more information about the 
		// format of the prefix and suffix, see:
		//
		// o HTML 4.01 Specification
		//   Forms
		//   <http://www.w3.org/TR/html401/interact/forms.html#h-17.13.4>
		//
		// o RFC 2388 "Returning Values from Forms: multipart/form-data"
		//   <http://www.ietf.org/rfc/rfc2388.txt>
	
    NSString* boundaryStr = [PicturePoster generateBoundaryString];
	
		// media, username, password, message
	
	NSMutableString* bodyStr = [NSMutableString stringWithCapacity:512];
		// no preamble							
	[bodyStr appendString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundaryStr]];
	[bodyStr appendString:[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"media\"; filename=\"%@\"\r\n", m_poster.filename]];
	[bodyStr appendString:[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", m_poster.contentType]];
	NSString* dataStr = [[[NSString alloc] initWithData:m_poster.pictureData encoding:NSISOLatin1StringEncoding] autorelease];
	[bodyStr appendString:dataStr];

	[bodyStr appendString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundaryStr]];
	[bodyStr appendString:                           @"Content-Disposition: form-data; name=\"username\"\r\n\r\n"];
	[bodyStr appendString:							 m_poster.username];
	
	[bodyStr appendString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundaryStr]];
	[bodyStr appendString:                           @"Content-Disposition: form-data; name=\"password\"\r\n\r\n"];
	[bodyStr appendString:							 m_poster.password];
	
	if ( m_poster.comment )
	{
	[bodyStr appendString:[NSString stringWithFormat:@"\r\n--%@\r\n", boundaryStr]];
	[bodyStr appendString:                           @"Content-Disposition: form-data; name=\"message\"\r\n\r\n"];
	[bodyStr appendString:							 m_poster.comment];
	}
	
	[bodyStr appendString:[NSString stringWithFormat:@"\r\n--%@--\r\n", boundaryStr]];
		// no epilogue
	
	NSData* msgData = [bodyStr dataUsingEncoding:NSISOLatin1StringEncoding];
		
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:m_twitpicAPIURL];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:msgData];
	[request setValue:[NSString stringWithFormat:@"multipart/form-data; charset=ISO-8859-1; boundary=%@", boundaryStr] forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%lu", msgData.length] forHTTPHeaderField:@"Content-Length"];

	[m_poster twitPicPostSendDidStart:self];

	[[NSURLConnection connectionWithRequest:request delegate:self] retain];	
}


- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response
    // A delegate method called by the NSURLConnection when the request/response 
    // exchange is complete.  We look at the response to check that the HTTP 
    // status code is 2xx.  If it isn't, we fail right now.
{
#pragma unused(theConnection)
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)response;
    
    if ( (httpResponse.statusCode / 100) != 2 ) 
	{
		[m_poster twitPicPost:self sendReceivedHTTPResponseStatusCode:httpResponse.statusCode];
    }
}

- (void)connection:(NSURLConnection *)theConnection didReceiveData:(NSData*)data
{
#pragma unused(theConnection)
	if ( m_serverResponse == nil )
	{
		m_serverResponse = [[data mutableCopy] retain];
	}
	else
	{
		[m_serverResponse appendData:data];
	}
}

- (void)connection:(NSURLConnection *)theConnection didFailWithError:(NSError *)error
{    
    [theConnection release];
    [m_poster twitPicPost:self sendDidFail:error];
	[m_serverResponse release];
	m_serverResponse = nil;
	[self release];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
    [theConnection release];
	
    [m_poster twitPicPost:self sendDidEnd:m_serverResponse];
	
	[m_serverResponse release];
	m_serverResponse = nil;
}
@end
