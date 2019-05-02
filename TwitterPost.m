//
//  TwitterPost.m
//  StaticMapHere
//
//  Created by Michael Rockhold on 1/12/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "TwitterPost.h"
#import "NSData+Base64.h"

const NSString* apiPostURLString = @"http://twitter.com/statuses/update.xml";

@implementation TwitterPost

-(id)initWithPoster:(id<TwitterPostClient>)poster
{
	if ( self = [self init] )
	{
		m_poster = [poster retain];
		m_serverResponse = nil;
	}
	return self;
}

-(void)dealloc
{
	[m_poster release];
	[m_serverResponse release];
	[super dealloc];
}

- (void)start
{
	NSURLCredential* credential = [NSURLCredential credentialWithUser:m_poster.username password:m_poster.password persistence:NSURLCredentialPersistenceForSession];
	NSURLProtectionSpace* protectionSpace = [[NSURLProtectionSpace alloc] initWithHost:@"twitter.com" port:0 protocol:@"http" realm:nil authenticationMethod:NSURLAuthenticationMethodHTTPBasic];
	
	[[NSURLCredentialStorage sharedCredentialStorage] setDefaultCredential:credential forProtectionSpace:protectionSpace];
	
	NSString *post = [NSString stringWithFormat:@"status=%@&lat=%lf&long=%lf", [m_poster.comment stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], m_poster.coordinate.latitude, m_poster.coordinate.longitude];
	NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"http://twitter.com/statuses/update.xml"]];
	
	[request setHTTPMethod:@"POST"];
	[request setHTTPBody:postData];
	[request setValue:@"application/x-www-form-urlencoded; charset=ISO-8859-1" forHTTPHeaderField:@"Content-Type"];
	[request setValue:[NSString stringWithFormat:@"%lu", postData.length] forHTTPHeaderField:@"Content-Length"];
	
	[[NSURLConnection connectionWithRequest:request delegate:self] retain];
	
	[m_poster twitterPostSendDidStart:self];
}

- (void)connection:(NSURLConnection *)theConnection didReceiveResponse:(NSURLResponse *)response
{
#pragma unused(theConnection)
    NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse *)response;
    
    if ( (httpResponse.statusCode / 100) != 2 ) 
	{
		[m_poster twitterPost:self sendReceivedHTTPResponseStatusCode:httpResponse.statusCode];
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
    [m_poster twitterPost:self sendDidFail:error];
	[m_serverResponse release];
	m_serverResponse = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)theConnection
{
    [theConnection release];
	
    [m_poster twitterPost:self sendDidEnd:m_serverResponse];
	[m_serverResponse release];
	m_serverResponse = nil;
}

-(void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if ( [challenge previousFailureCount] == 0 )
	{
        NSURLCredential *newCredential=[NSURLCredential credentialWithUser:m_poster.username password:m_poster.password persistence:NSURLCredentialPersistenceNone];
        [[challenge sender] useCredential:newCredential forAuthenticationChallenge:challenge];
    }
	else
	{
        [[challenge sender] cancelAuthenticationChallenge:challenge];
			// inform the user that the user name and password
			// in the preferences are incorrect
		NSLog(@"cancelling authentication challenge");
    }
}
@end
