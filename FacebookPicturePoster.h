//
//  FacebookPicturePoster.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 3/19/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "PicturePoster.h"

@class FBSession;
@class FBLoggerIn;

@protocol FacebookPicturePosterOwner;

@interface FacebookPicturePoster : PicturePoster
{
	NSMutableDictionary* m_permissionDictionary;
	NSString* _albumID;
	NSString* _albumName;
	NSString* _albumDesc;
	
	NSUInteger _requirementIndex;
	NSArray* _requirements;
	
	NSMutableArray* _uploaders;
	FBLoggerIn* _loggerIn;
}

@property (nonatomic, readonly, retain) FBSession* session;
@property (nonatomic, readonly)			BOOL loggedIn;

-(id)initWithOwner:(id<FacebookPicturePosterOwner>)owner;

@end
