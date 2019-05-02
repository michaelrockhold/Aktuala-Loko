	//
	//  FacebookPicturePoster.m
	//  Here-I-Am
	//
	//  Created by Michael Rockhold on 3/19/10.
	//  Copyright 2010 The Rockhold Company. All rights reserved.
	//

#import "FacebookPicturePoster.h"
#import "FBLoggerIn.h"
#import "FBPermissionQuery.h"
#import "FBPermissionSetter.h"
#import "FBAlbumIDQuery.h"
#import "FBAlbumCreator.h"
#import "FBPhotoUploader.h"
#import "FBConnect.h"
#import "RCError.h"

@protocol FacebookPicturePosterOwner < PicturePosterOwner >

@end

@interface FacebookPicturePoster () < FBLoggerInDelegate, FBPermissionQueryDelegate, FBPermissionSetterDelegate, FBAlbumIDQueryDelegate, FBAlbumCreatorDelegate, FBPhotoUploaderDelegate >

-(void)doNextRequirement;

-(void)didFailWithError:(NSError*)error;

-(void)doLogIn;

-(void)queryPermission:(NSString*)p;

-(void)queryOfflineAccessPermission;

-(void)queryPublishStreamPermission;

-(void)acquirePermission:(NSString*)p;

-(void)acquireOfflineAccessPermission;

-(void)acquirePublishStreamPermission;

-(void)queryAlbumID;

-(void)acquireAlbumID;

-(void)doUploads;

@end


@implementation FacebookPicturePoster

-(id)initWithOwner:(id<FacebookPicturePosterOwner>)owner
{
	if ( self = [super initWithOwner:owner] )
	{
		m_permissionDictionary = [[NSMutableDictionary dictionaryWithCapacity:3] retain];	
		_albumID = nil;

		NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		NSString* today = [dateFormatter stringFromDate:[NSDate date]];
		[dateFormatter release];
		
		_albumName = [[NSString stringWithFormat:@"Aktuala Loko Maps for %@", today] retain];
		
		_albumDesc = [[NSString stringWithFormat:@"Maps of places where I've used Aktuala Loko to record my present location on %@", today] retain];
				
		_requirementIndex = 0;
		_requirements = [[NSArray arrayWithObjects:
						  @"doLogIn", 
						  @"queryOfflineAccessPermission", 
						  @"queryPublishStreamPermission",
						  @"acquireOfflineAccessPermission",
						  @"acquirePublishStreamPermission",
						  @"queryAlbumID",
						  @"acquireAlbumID",
						  @"doUploads",
						  nil] retain];
		
		FBSession* s = self.session;
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionLoginNotification:) name:cFBSessionLoginNotification object:s];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidLogoutNotification:) name:cFBSessionLogoutNotification object:s];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionDidNotLoginNotification:) name:cFBSessionDidNotLoginNotification object:s];		
	}
	return self;
}

-(void)dealloc
{
	[_albumID release];
	[_albumName release];
	[_albumDesc release];
	[m_permissionDictionary release];
	[_loggerIn release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:self.session];
	[super dealloc];
}

-(id<FacebookPicturePosterOwner>)owner
{
	return (id<FacebookPicturePosterOwner>)m_owner;
}

-(void)start
{
	[self.session resume];

		// do stuff, ultimately doUploads
	[self doNextRequirement];
}

-(void)doNextRequirement
{
	if ( _requirementIndex >= _requirements.count )
		return;
	
	NSString* r = [_requirements objectAtIndex:_requirementIndex];
	_requirementIndex++;
	[self performSelectorOnMainThread:NSSelectorFromString(r) withObject:nil waitUntilDone:NO];
}

-(void)didFailWithError:(NSError*)error
{
	[self.owner picturePoster:self sendDidFail:error];
}

#pragma mark -
#pragma mark Logging In methods
-(void)doLogIn
{
	if ( _loggerIn )
	{
			//create error to indicate logging-in already in progress (shouldn't happen)
		[self didFailWithError:[NSError errorWithDomain:FBAPI_ERROR_DOMAIN code:FBAPI_EC_TOO_MANY_CALLS userInfo:nil]];
	}
	
	_loggerIn = [[FBLoggerIn alloc] initWithFBLoggerInDelegate:self];
	[_loggerIn start];
}

-(BOOL)loggedIn { return self.session.isConnected; }

-(UINavigationController*)navigationController { return self.owner.navigationController; }

-(void)loggerInDidLogIn:(FBLoggerIn*)loggerIn
{
	[_loggerIn release]; _loggerIn = nil;
	[self doNextRequirement];
}

-(void)loggerIn:(FBLoggerIn*)loggerIn didFailWithError:(NSError*)error
{
	[_loggerIn release]; _loggerIn = nil;
	[self didFailWithError:error];
}

#pragma mark -
-(void)queryPermission:(NSString*)p
{
	NSNumber* permission = [m_permissionDictionary objectForKey:p];
	if ( nil == permission )
	{
		FBPermissionQuery* pq = [[FBPermissionQuery alloc] initWithFBPermissionQueryDelegate:self permission:p];
		[pq start];
	}
	else if ( [permission boolValue] )
	{
		[self doNextRequirement];
	}
}

-(void)queryOfflineAccessPermission { [self queryPermission:@"offline_access"]; }

-(void)queryPublishStreamPermission { [self queryPermission:@"publish_stream"]; }

-(void)fbPermissionQuery:(FBPermissionQuery*)pq value:(NSNumber*)fPermission
{	
	[m_permissionDictionary setObject:fPermission forKey:pq.permission];
	[pq release];
	
	[self doNextRequirement];
}

-(void)fbPermissionQuery:(FBPermissionQuery*)pq didFailWithError:(NSError*)error
{
	[pq release];
	[self didFailWithError:error];
}

#pragma mark -
-(void)acquirePermission:(NSString*)p
{
	NSNumber* permission = [m_permissionDictionary objectForKey:p];
	if ( nil == permission )
	{
		[self didFailWithError:[RCError rcErrorWithSubdomain:@"PicturePosting" errorMsgKey:@"no such permission \"%@\"", p, nil]];
	}
	else if ( [permission boolValue] )
	{
		[self doNextRequirement];
	}
	else
	{
		FBPermissionSetter* ps = [[FBPermissionSetter alloc] initWithFBPermissionSetterDelegate:self permission:p];
		[ps start];
	}
}

-(void)acquireOfflineAccessPermission { [self acquirePermission:@"offline_access"]; }

-(void)acquirePublishStreamPermission { [self acquirePermission:@"publish_stream"]; }


-(void)fbPermissionSetter:(FBPermissionSetter*)ps permissionSet:(NSString*)permission
{
	[ps release];
	[self doNextRequirement];
}

-(void)fbPermissionSetter:(FBPermissionSetter*)ps didFailWithError:(NSError*)error
{
	[ps release];
	[self didFailWithError:error];
}

#pragma mark -
-(void)queryAlbumID
{
	if ( _albumID )
	{
		[self doNextRequirement];
	}
	else
	{
		FBAlbumIDQuery* aiq = [[FBAlbumIDQuery alloc] initWithFBAlbumIDQueryDelegate:self userID:self.session.uid albumName:_albumName];
		[aiq start];
	}
}

-(void)fbAlbumIDQuery:(FBAlbumIDQuery*)aiq albumID:(NSString*)albumID
{
	[aiq release];
	
	if ( albumID )
		_albumID = [albumID retain];
	[self doNextRequirement];
}

-(void)fbAlbumIDQuery:(FBAlbumIDQuery*)fiq didFailWithError:(NSError*)error
{
	[self didFailWithError:error];
}

-(void)acquireAlbumID
{
	if ( _albumID )
	{
		[self doNextRequirement];
	}
	else
	{
		FBAlbumCreator* ac = [[FBAlbumCreator alloc] initWithFBAlbumCreatorDelegate:self name:_albumName location:@"My current location" description:_albumDesc];
		[ac start];
	}
}

-(void)fbAlbumCreator:(FBAlbumCreator*)ac albumID:(NSString*)albumID
{
	[ac release];
	_albumID = [albumID retain];
	if ( nil == _albumID )
	{
		[self didFailWithError:[NSError errorWithDomain:FBAPI_ERROR_DOMAIN code:FBAPI_EC_PARAM_ALBUM_ID userInfo:nil]];
	}
	else
		[self doNextRequirement];
}

-(void)fbAlbumCreator:(FBAlbumCreator*)ac didFailWithError:(NSError*)error
{
	[self didFailWithError:error];
}

#pragma mark -
#pragma mark Upload methods

-(void)doUploads
{
	NSString* comment = self.owner.comment;
	comment = (( comment == nil || [comment isEqualToString:@""] ) 
			   ? [NSString stringWithFormat:@"http://maps.google.com/?ll=%lf,%lf&z=16", self.owner.currentCoordinate.latitude, self.owner.currentCoordinate.longitude] 
			   : [NSString stringWithFormat:@"%@ (http://maps.google.com/?ll=%lf,%lf&z=16)", self.owner.comment, self.owner.currentCoordinate.latitude, self.owner.currentCoordinate.longitude]);

	NSArray* pictures = self.owner.picturePostInfoArray;

	_uploaders = [[NSMutableArray arrayWithCapacity:3] retain];
	for (int i = 0; i<pictures.count; i++)
	{
		id<PicturePostInfo> ppi = [pictures objectAtIndex:i];
		
		[_uploaders addObject:[[FBPhotoUploader alloc] initWithFBPhotoUploaderDelegate:self
																			 photoData:ppi.pictureData 
																			   caption:comment 
																			   albumID:_albumID]];
	}
	FBPhotoUploader* op = [[_uploaders lastObject] retain];
	[_uploaders removeLastObject];
	[op start];
}

-(void)photoUploader:(FBPhotoUploader*)photoUploader photoInfo:(NSDictionary*)result
{
	[photoUploader release];
	
	if ( _uploaders.count )
	{
		FBPhotoUploader* op = [[_uploaders lastObject] retain];
		[_uploaders removeLastObject];
		[op start];
	}
	else 
	{
		[self.owner picturePoster:self sendDidEnd:[result objectForKey:@"link"]];
	}
}

-(void)photoUploader:(FBPhotoUploader*)photoUploader didFailWithError:(NSError*)error
{
	[photoUploader release];
	[self didFailWithError:error];
}

#pragma mark -

-(FBSession*)session { return [FBSession session]; }

#pragma mark -
#pragma mark FBSession notifications

-(void)sessionLoginNotification:(NSNotification*)notification
{
	NSLog(@"Logged in");
}

-(void)sessionDidNotLoginNotification:(NSNotification*)notification
{
	NSLog(@"Canceled login");
}

-(void)sessionDidLogoutNotification:(NSNotification*)notification
{
	NSLog(@"Disconnected");
}

@end
