//
//  HereIAmModel.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 7/6/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

typedef enum {
	SidePhoto_Left = 0,
	SidePhoto_Right
} SidePhoto;

@class MKPlacemark;

@protocol HereIAmModel < NSObject >

@property (nonatomic, retain)			UIImage*				mapImage;
@property (nonatomic, retain)			NSString*				comment;
@property (nonatomic, retain)			UIImage*				photoA;
@property (nonatomic, retain)			UIImage*				photoB;
@property (nonatomic, readonly)			CLLocationCoordinate2D	currentCoordinate;
@property (nonatomic, retain)			MKPlacemark*			currentPlacemark;

-(Class)classForUsersPreferredService;

-(void)post;

-(void)visitBlog;

@end

extern NSString* HereIAmModel_LeftPhotoChanged_Notification;
extern NSString* HereIAmModel_RightPhotoChanged_Notification;
extern NSString* HereIAmModel_MapImageChanged_Notification;
extern NSString* HereIAmModel_CommentChanged_Notification;
extern NSString* HereIAmModel_CurrentPlacemarkChanged_Notification;

extern NSString* HereIAmModel_BloggedURLStringChanged_Notification;
