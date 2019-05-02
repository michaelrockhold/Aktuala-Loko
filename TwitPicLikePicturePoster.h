//
//  TwitPicLikePicturePoster.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 3/19/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "PicturePoster.h"
#import "TwitterLoginViewController.h"

@class TWSession;

@protocol TwitterPicturePosterOwner < PicturePosterOwner >

@property (nonatomic, retain, readonly) TWSession* twitterSession;

@end

@class StatusUpdateRequestor;
@class TwitterOAuthLogin;
@class TwitPicUploader;

@interface TwitPicLikePicturePoster : PicturePoster < RCWebDialogViewControllerDelegate >
{
	NSString* _pictureURLString;
	TwitterOAuthLogin* _tol;
	StatusUpdateRequestor* _sur;
	TwitPicUploader* _tpu;
}

@property (nonatomic, retain, readonly) id<TwitterPicturePosterOwner> owner;

-(id)initWithOwner:(id<TwitterPicturePosterOwner>)owner;

-(NSData*)makeHTTPBodyData:(NSString*)boundary;

@end
