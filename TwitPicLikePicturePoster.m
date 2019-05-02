	//
	//  TwitPicLikePicturePoster.m
	//  Here-I-Am
	//
	//  Created by Michael Rockhold on 3/19/10.
	//  Copyright 2010 The Rockhold Company. All rights reserved.
	//
/*
 TODO: all keys out!
 */

#import "TwitPicLikePicturePoster.h"
#import "TwitterLoginViewController.h"
#import "NSData+ResponseDecoding.h"
#import "RCHTTPBody.h"
#import "FBXMLHandler.h"
#import "OAAsynchronousDataFetcher.h"
#import "TWSession.h"
#import "TwitterOAuthLogin.h"
#import <CoreLocation/CoreLocation.h>
#import "RCError.h"

#pragma mark TwitterPicturePoster internal interface

@class TwitPicUploader;

@interface TwitPicLikePicturePoster () < TwitterOAuthLoginDelegate >

-(void)sendStatusUpdate;

-(void)sendStatusUpdateToTwitPic;

-(void)statusUpdateRequestor:(StatusUpdateRequestor*)statusUpdateRequestor didFinishRequest:(NSURLRequest*)request response:(NSURLResponse*)response responseString:(NSString*)responseStr succeeded:(BOOL)ok;

-(void)statusUpdateRequestor:(StatusUpdateRequestor*)statusUpdateRequestor didFailRequest:(NSURLRequest*)request response:(NSURLResponse*)response responseString:(NSString*)responseStr error:(NSError*)error;

-(void)twitpicUploader:(TwitPicUploader*)tpul didLoad:(id)result;

-(void)twitpicUploader:(TwitPicUploader*)tpul didFail:(NSError*)error;

@end

#pragma mark private classes

@interface StatusUpdateRequestor : OAAsynchronousDataFetcher < OADataFetcherDelegate >
{
	TwitPicLikePicturePoster* _twitterPicturePoster;
}
-(id)initWithTwitterPicturePoster:(TwitPicLikePicturePoster*)poster request:(OAMutableURLRequest*)request;
@end

@interface TwitPicUploader : NSObject
{
	TwitPicLikePicturePoster* _delegate;
	NSMutableData* _data;
	NSURLConnection* _urlConnection;
	NSTimer* _timer;
}

-(id)initWithDelegate:(TwitPicLikePicturePoster*)d
				  url:(NSURL*)url 
				 data:(NSData*)msgData 
 xAuthServiceProvider:(NSString*)xAuthServiceProvider
		  oAuthHeader:(NSString*)oAuthHeader
			 boundary:(NSString*)boundary;

-(void)start;
-(void)cancelUpload:(NSTimer*)theTimer;

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
-(void)connectionDidFinishLoading:(NSURLConnection *)connection;

@end

#pragma mark implementations

@implementation StatusUpdateRequestor

-(id)initWithTwitterPicturePoster:(TwitPicLikePicturePoster*)poster request:(OAMutableURLRequest*)r
{
	if ( self = [super initWithRequest:r delegate:self] )
	{
		_twitterPicturePoster = [poster retain];
	}
	return self;
}

-(void)dealloc
{
	[_twitterPicturePoster release];
	[super dealloc];
}

-(void)dataFetcher:(OADataFetcher*)fetcher didFailRequest:(NSURLRequest*)r response:(NSURLResponse*)resp data:(NSData*)data error:(NSError*)error
{
	[_twitterPicturePoster statusUpdateRequestor:self didFailRequest:r response:resp responseString:[data UTF8String] error:error];
}

-(void)dataFetcher:(OADataFetcher*)fetcher didFinishRequest:(NSURLRequest*)r response:(NSURLResponse*)resp data:(NSData*)data succeeded:(BOOL)ok
{
	NSString* dataStr = [[[NSString alloc] initWithBytes:data.bytes length:data.length encoding:NSUTF8StringEncoding] autorelease];
	[_twitterPicturePoster statusUpdateRequestor:self didFinishRequest:r response:resp responseString:dataStr succeeded:ok];
}
@end

@implementation TwitPicUploader

-(id)initWithDelegate:(TwitPicLikePicturePoster*)d
				  url:(NSURL*)url 
				 data:(NSData*)msgData 
 xAuthServiceProvider:(NSString*)xAuthServiceProvider
		  oAuthHeader:(NSString*)oAuthHeader
			 boundary:(NSString*)boundary
{
	if ( self = [super init] )
	{
		_delegate = [d retain];
		
		_data = nil;
		
		_timer = [[NSTimer timerWithTimeInterval:60 target:self selector:@selector(cancelUpload:) userInfo:nil repeats:NO] retain];
		
		_urlConnection = nil;
		
		NSMutableURLRequest* statusUpdateRequest = [NSMutableURLRequest requestWithURL:url];
		[statusUpdateRequest setHTTPMethod:@"POST"];
		[statusUpdateRequest setHTTPBodyStream:[NSInputStream inputStreamWithData:msgData]];
		
		[statusUpdateRequest setValue:[TWSession X_Auth_Service_Provider]
				   forHTTPHeaderField:@"X-Auth-Service-Provider"];
		[statusUpdateRequest setValue:oAuthHeader
				   forHTTPHeaderField:@"X-Verify-Credentials-Authorization"];
		[statusUpdateRequest setValue:[NSString stringWithFormat:@"multipart/form-data; charset=ISO-8859-1; boundary=%@", boundary]
				   forHTTPHeaderField:@"Content-Type"];
		[statusUpdateRequest setValue:[NSString stringWithFormat:@"%lu", msgData.length]
				   forHTTPHeaderField:@"Content-Length"];
		
		_urlConnection = [[NSURLConnection alloc] initWithRequest:statusUpdateRequest delegate:self startImmediately:NO];
	}
	return self;
}

-(void)dealloc
{
	[_timer invalidate];
	[_timer release];
	[_urlConnection release];
	[_data release];
	[_delegate release];
	[super dealloc];
}

-(void)start
{
	[[NSRunLoop currentRunLoop]
	 addTimer:_timer 
	 forMode:NSDefaultRunLoopMode];
	
	[_urlConnection start];
}

-(void)cancelUpload:(NSTimer*)theTimer
{
	[_urlConnection cancel];
	[_delegate twitpicUploader:self didFail:nil];
}

- (id)parseXMLResponse:(NSData*)data error:(NSError**)error
{
	FBXMLHandler* handler = [[[FBXMLHandler alloc] init] autorelease];
	NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:data] autorelease];
	parser.delegate = handler;
	[parser parse];
	
	if (handler.parseError)
	{
		if (error)
		{
			*error = [[handler.parseError retain] autorelease];
		}
		return nil;
	}
	else if ([handler.rootName isEqualToString:@"error_response"])
	{
		NSDictionary* errorDict = handler.rootObject;
		NSInteger code = [[errorDict objectForKey:@"error_code"] intValue];
		NSDictionary* info = [NSDictionary dictionaryWithObjectsAndKeys:
							  [errorDict objectForKey:@"error_msg"], NSLocalizedDescriptionKey,
							  [errorDict objectForKey:@"request_args"], @"request_args",
							  nil];
		if (error)
		{
			*error = [NSError errorWithDomain:FBAPI_ERROR_DOMAIN code:code userInfo:info];
		}
		return nil;
	}
	else
	{
		return [[handler.rootObject retain] autorelease];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData*)data
{
	if ( nil == _data )
	{
		_data = [data mutableCopy];
	}
	else
	{
		[_data appendData:data];
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse*)response
{
	NSLog(@"TwitPicUploader connection:didReceiveResponse: received %@", response);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[_timer invalidate];
	NSError* error = nil;
	NSDictionary* errorResult = nil;
	id result = [self parseXMLResponse:_data error:&error];
	
	if ( error )
	{
		[_delegate twitpicUploader:self didFail:error];
	}
	else if ( errorResult = [result objectForKey:@"error"] )
	{
		[_delegate twitpicUploader:self didFail:[RCError rcErrorWithSubdomain:@"PicturePosting" errorMsgKey:[errorResult objectForKey:@"message"], nil]];
	}
	else
	{
		[_delegate twitpicUploader:self didLoad:result];
	}
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[_timer invalidate];
	[_delegate twitpicUploader:self didFail:error];
}

-(void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
	NSLog(@"connection didSendBodyData %d, %d of %d", bytesWritten, totalBytesWritten, totalBytesExpectedToWrite);
}
@end

#pragma mark -
#pragma mark -

@implementation TwitPicLikePicturePoster

-(id)initWithOwner:(id<TwitterPicturePosterOwner>)owner
{
	if ( self = [super initWithOwner:owner] )
	{
		_pictureURLString = nil;
		_tol = nil;
		_sur = nil;
		_tpu = nil;
	}
	return self;
}

-(void)dealloc
{
	[_tol release];
	[_sur release];
	[_tpu release];
	[_pictureURLString release];
	[super dealloc];
}

-(id<TwitterPicturePosterOwner>)owner
{
	return (id<TwitterPicturePosterOwner>)[super owner];
}

-(NSURL*)uploadURL
{
	NSLog(@"warning: unimplemented base class method \"uploadURL\""); return nil;
}

-(NSData*)makeHTTPBodyData:(NSString*)boundary
{
	NSLog(@"warning: unimplemented base class method \"makeHTTPBodyData\"");
	return nil;
}

-(void)start
{
	if ( !self.owner.twitterSession.isConnected )
	{
		_tol = [[TwitterOAuthLogin alloc] initWithTwitterOAuthLoginDelegate:self];
		[_tol start];
	}
	else 
	{
		[self sendStatusUpdateToTwitPic];
	}
}

-(void)twitterOAuthLogin:(TwitterOAuthLogin*)twitterOAuthLogin didLogin:(BOOL)ok
{
	[self sendStatusUpdateToTwitPic];
}

-(void)twitterOAuthLogin:(TwitterOAuthLogin*)twitterOAuthLogin didFailWithError:(NSError*)error
{
	[self.owner picturePoster:self sendDidFail:error];
}

-(TWSession*)session { return self.owner.twitterSession; }

-(UINavigationController*)navigationController { return self.owner.navigationController; }

-(BOOL)pushControllerAnimated { return YES; }

#pragma mark -

-(void)sendStatusUpdate
{
	_sur = [[StatusUpdateRequestor alloc] initWithTwitterPicturePoster:self request:[self.owner.twitterSession makeStatusUpdateRequest:[NSString stringWithFormat:@"%@ %@", _pictureURLString, self.owner.comment]
																															coordinate:self.owner.currentCoordinate
																													displayCoordinates:YES]];
	[_sur start];
}

- (void)sendStatusUpdateToTwitPic
{
	NSString* boundary = [PicturePoster generateBoundaryString];
	OAMutableURLRequest* verifyCredentialsRequest = [self.owner.twitterSession newVerifyCredentialsRequest];
	
	_tpu = [[TwitPicUploader alloc] initWithDelegate:self 
												 url:self.uploadURL 
												data:[self makeHTTPBodyData:boundary] 
								xAuthServiceProvider:[TWSession X_Auth_Service_Provider]
										 oAuthHeader:verifyCredentialsRequest.oauthHeader
											boundary:boundary
			];
	[verifyCredentialsRequest release];
	[_tpu start];
}

-(void)twitpicUploader:(TwitPicUploader*)tpul didLoad:(id)result
{
	NSDictionary* resultDic = (NSDictionary*)result;
	_pictureURLString = [[resultDic objectForKey:@"url"] retain];
	[self sendStatusUpdate];
}

-(void)twitpicUploader:(TwitPicUploader*)tpul didFail:(NSError*)error
{
	[self.owner picturePoster:self sendDidFail:error];
}

-(void)statusUpdateRequestor:(StatusUpdateRequestor*)statusUpdateRequestor didFinishRequest:(NSURLRequest*)request response:(NSURLResponse*)response responseString:(NSString*)responseStr succeeded:(BOOL)ok
{
	if ( !ok )
	{
		NSError* error = nil;
		{
			FBXMLHandler* handler = [[[FBXMLHandler alloc] init] autorelease];
			NSXMLParser* parser = [[[NSXMLParser alloc] initWithData:[responseStr dataUsingEncoding:NSUTF8StringEncoding]] autorelease];
			parser.delegate = handler;
			[parser parse];
			
			if ( [handler.rootName isEqualToString:@"hash"] )
			{
				NSDictionary* errorDict = handler.rootObject;
				error = [RCError rcErrorWithSubdomain:@"PicturePosting" errorMsgKey:[errorDict objectForKey:@"error"], nil];
			}
			else
			{
				error = [RCError rcErrorWithSubdomain:@"PicturePosting" errorMsgKey:@"Unknown error while posting status update", nil];
			}
		}		
		
		[self.owner picturePoster:self sendDidFail:error]; 
	}
	else 
	{
		[self.owner picturePoster:self sendDidEnd:_pictureURLString];
	}
}

-(void)statusUpdateRequestor:(StatusUpdateRequestor*)statusUpdateRequestor didFailRequest:(NSURLRequest*)request response:(NSURLResponse*)resp responseString:(NSString*)responseStr error:(NSError*)error
{
	[self.owner picturePoster:self sendDidFail:error];
}


@end
