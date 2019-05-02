//
//  HereIAmAppDelegate.h
//  HereIAm
//
//  Created by Michael Rockhold on 1/17/10.
//  Copyright The Rockhold Company 2010. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "FBSession.h"
#import "PicturePoster.h"
#import "HereIAmModel.h"

@class MainViewController;
@class TWSession;

@interface HereIAmAppDelegate : NSObject <
									UIApplicationDelegate,
									HereIAmModel,
									CLLocationManagerDelegate,
									MKReverseGeocoderDelegate,
									PicturePosterOwner,
									FBSessionDelegate
									>
{
	UIWindow*					m_window;
	UINavigationController*		m_navigationController;
	MainViewController *		m_mainViewController;
	FBSession*					m_session;
	TWSession*					_twitterSession;

	UIImage*					m_mapImage;
	NSString*					m_comment;
	UIImage*					m_photoA;
	UIImage*					m_photoB;
	MKPlacemark*				m_currentPlacemark;
	NSString*					_bloggedURLString;
	id<PicturePostInfo>			_picturePostInfo;
	
	MKReverseGeocoder*			m_rg;
	NSURLConnection*			m_connection;
	NSMutableData*				m_receivedData;	
	CLLocationManager*			m_locationManager;
	NSString*					m_requestString;
	NSDateFormatter*			_yyyyMMdd_HHmmFormatter;
	NSDateFormatter*			_photoCopyrightDateFormatter;
}

@property (nonatomic, retain) IBOutlet	UIWindow*				window;
@property (nonatomic, retain) IBOutlet	UINavigationController*	navigationController;
@property (nonatomic, retain) IBOutlet	MainViewController*		mainViewController;

@property (nonatomic, retain, readonly) TWSession*				twitterSession;
@property (nonatomic, readonly, retain) FBSession*				session;

@property (nonatomic, retain)			NSString*				bloggedURLString;

+(id<HereIAmModel>)model;

@end

