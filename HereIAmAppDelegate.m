//
//  HereIAmAppDelegate.m
//  HereIAm
//
//  Created by Michael Rockhold on 1/17/10.
//  Copyright The Rockhold Company 2010. All rights reserved.
//

#import <QuartzCore/CALayer.h>

#import "HereIAmAppDelegate.h"
#import "MainViewController.h"
#import "JPEGManager.h"
#import <objc/runtime.h>
#import "OAToken.h"
#import "OAConsumer.h"
#import "TWSession.h"
#import "RCException.h"

static NSString* kTwitterAuthCallback = @"http://www.rockholdco.com/RC/Aktuala_Loko/authenticated/index.html";

enum PicturePostInfoIndex
{
	PicturePostInfoIndex_SingleCombined,
	PicturePostInfoIndex_Central,
	PicturePostInfoIndex_Left,
	PicturePostInfoIndex_Right
};


static void swapWidthAndHeight(CGSize* psz)
{
    CGFloat h = psz->height;  
	psz->height = psz->width;  
	psz->width = h;
}

static UIImage* makeCanonicalImage(UIImage *image, CGFloat maxResolution)  
{
    CGImageRef imgRef = image.CGImage;  
	
    CGFloat width = CGImageGetWidth(imgRef);  
    CGFloat height = CGImageGetHeight(imgRef);  

	if ( maxResolution < 0 ) maxResolution = width > height ? width : height;

    CGAffineTransform transform = CGAffineTransformIdentity;  
    CGRect bounds = CGRectMake(0, 0, width, height);  
    if ( width > maxResolution || height > maxResolution )
	{  
        CGFloat ratio = width/height;  
        if (ratio > 1)
		{  
            bounds.size.width = maxResolution;  
            bounds.size.height = bounds.size.width / ratio;  
        }  
        else
		{  
            bounds.size.height = maxResolution;  
            bounds.size.width = bounds.size.height * ratio;  
        }  
    }  
	
    CGFloat scaleRatio = bounds.size.width / width;  
    CGSize imageSize = CGSizeMake(width, height);  

	UIImageOrientation imageOrientation = image.imageOrientation;
    switch(imageOrientation)
	{
        case UIImageOrientationUp: //EXIF = 1  
            transform = CGAffineTransformIdentity;  
            break;  
			
        case UIImageOrientationUpMirrored: //EXIF = 2  
            transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);  
            transform = CGAffineTransformScale(transform, -1.0, 1.0);  
            break;  
			
        case UIImageOrientationDown: //EXIF = 3  
            transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);  
            transform = CGAffineTransformRotate(transform, M_PI);  
            break;  
			
        case UIImageOrientationDownMirrored: //EXIF = 4  
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);  
            transform = CGAffineTransformScale(transform, 1.0, -1.0);  
            break;  
			
        case UIImageOrientationLeftMirrored: //EXIF = 5  
			swapWidthAndHeight(&bounds.size);
            transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);  
            transform = CGAffineTransformScale(transform, -1.0, 1.0);  
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
            break;  
			
        case UIImageOrientationLeft: //EXIF = 6  
			swapWidthAndHeight(&bounds.size);
            transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);  
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);  
            break;  
			
        case UIImageOrientationRightMirrored: //EXIF = 7  
			swapWidthAndHeight(&bounds.size);
            transform = CGAffineTransformMakeScale(-1.0, 1.0);  
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
            break;  
			
        case UIImageOrientationRight: //EXIF = 8  
			swapWidthAndHeight(&bounds.size);
            transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);  
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);  
            break;  
			
        default:  
            [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];  
			
    }
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();  
	
	if ( imageOrientation == UIImageOrientationRight || imageOrientation == UIImageOrientationLeft )
	{  
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);  
		CGContextTranslateCTM(context, -height, 0);  
	}  
	else
	{  
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);  
		CGContextTranslateCTM(context, 0, -height);  
	}  
	
	CGContextConcatCTM(context, transform);  
	
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);  
	UIImage* imageCopy = UIGraphicsGetImageFromCurrentImageContext();  
	UIGraphicsEndImageContext();
	
	return imageCopy;
}  

@interface HereIAmAppDelegate (PrivateMethods)

+(NSData*)captureImage:(UIView*)view location:(CLLocation*)location title:(NSString*)title comment:(NSString*)comment;

-(NSString*)urlStringWithCoordinate:(CLLocationCoordinate2D)coordinate imageWidth:(int)imageWidth imageHeight:(int)imageHeight zoomLevel:(int)zoomLevel;

-(NSURL*)apiServiceURL;
-(NSString*)username;
-(NSString*)password;

-(void)setPhoto:(UIImage*)i photoMember:(UIImage**)pmi notification:(NSString*)notification;

-(NSString*)picturePostInfoFilename:(enum PicturePostInfoIndex)idx;
-(NSString*)picturePostInfoContentType:(enum PicturePostInfoIndex)idx;
-(NSData*)picturePostInfoJPEGData:(enum PicturePostInfoIndex)idx;

-(void)displayError:(NSString*)localizedString for:(NSString*)topicKey;

@end

@interface PrivatePicturePostInfo : NSObject < PicturePostInfo >
{
	HereIAmAppDelegate* _appDel;
	enum PicturePostInfoIndex _idx;
}

-(id)initWithHereIAmAppDelegate:(HereIAmAppDelegate*)appDel index:(enum PicturePostInfoIndex)idx;

@end

@implementation PrivatePicturePostInfo

-(id)initWithHereIAmAppDelegate:(HereIAmAppDelegate*)appDel index:(enum PicturePostInfoIndex)idx
{
	if ( self = [super init] )
	{
		_appDel = [appDel retain];
		_idx = idx;
	}
	return self;
}

-(void)dealloc
{
	[_appDel release];
	[super dealloc];
}

-(NSData*)pictureData
{
	return [_appDel picturePostInfoJPEGData:_idx];
}

-(NSString*)filename
{
	return [_appDel picturePostInfoFilename:_idx];
}

-(NSString*)contentType
{
	return [_appDel picturePostInfoContentType:_idx];
}

@end


@interface PrivateOAConsumer : NSObject < OAConsumer >

@property (nonatomic, retain, readonly) NSString* key;
@property (nonatomic, retain, readonly) NSString* secret;

@end


@implementation HereIAmAppDelegate
@synthesize window = m_window, mainViewController = m_mainViewController, navigationController = m_navigationController;
@synthesize twitterSession = _twitterSession;

+ (void)initialize
{
	NSDictionary* hardcodedDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
									   @"TwitPicPicturePoster",										@"service",	
									   @"http://dev.openstreetmap.de/staticmap/staticmap.php",		@"mappictureservice",
									   nil
									   ];
	[[NSUserDefaults standardUserDefaults] registerDefaults:hardcodedDefaults];
}

+(id<HereIAmModel>)model
{
	return (id<HereIAmModel>)[UIApplication sharedApplication].delegate;
}

-(id)init
{
	if ( self = [super init] )
	{
		_yyyyMMdd_HHmmFormatter = [[NSDateFormatter alloc] init];
		[_yyyyMMdd_HHmmFormatter setDateFormat:@"yyyyMMdd-HHmm"];
		
		_photoCopyrightDateFormatter = [[NSDateFormatter alloc] init];
		NSString* photoCopyrightDateFormat = [NSString stringWithFormat:@"'© ' yyyy ' %@, all rights reserved'", NSFullUserName()];
		[_photoCopyrightDateFormatter setDateFormat:photoCopyrightDateFormat];
		
		m_rg = nil;
		m_session = [[FBSession sessionWithDelegate:self] retain];
		
		_twitterSession = [[TWSession alloc] initWithOAConsumer:[[[PrivateOAConsumer alloc] init] autorelease]
									  authorizationCallback:kTwitterAuthCallback];	
		m_comment = nil;
		_bloggedURLString = nil;
		
		m_requestString = nil;
		m_connection = nil;
		m_receivedData = nil;
		m_locationManager = [[CLLocationManager alloc] init];		
	}
	return self;
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	NSLog(@"!! applicationDidReceiveMemoryWarning: !!");
}

- (void)applicationDidFinishLaunching:(UIApplication *)application
{
	[self.window addSubview:self.navigationController.view];
    [self.window makeKeyAndVisible];
		
	self.mainViewController.view.frame = [UIScreen mainScreen].applicationFrame;
		
	m_locationManager.delegate = self;
	if ( m_locationManager.locationServicesEnabled )
	{
		[self.mainViewController downloadingMapDidStart];
		[m_locationManager startUpdatingLocation];
	}
	
	[m_session resume];
}


- (void)dealloc
{
	[m_rg release];
	[m_session release];
	[_twitterSession release];
	[m_connection release];
	[m_receivedData release];
	[_yyyyMMdd_HHmmFormatter release];
	[_photoCopyrightDateFormatter release];
	[m_requestString release];
	[_bloggedURLString release];

	self.comment = nil;
	self.window = nil;
	self.navigationController = nil;
	self.mainViewController = nil;

    [super dealloc];
}

-(NSString*)urlStringWithCoordinate:(CLLocationCoordinate2D)coordinate imageWidth:(int)imageWidth imageHeight:(int)imageHeight zoomLevel:(int)zoomLevel
{
	NSString* mapPictureService = [[NSUserDefaults standardUserDefaults] stringForKey:@"mappictureservice"];
	
	return mapPictureService
	? [NSString stringWithFormat:@"%@?center=%lf,%lf&zoom=%d&size=%dx%d", 
			mapPictureService,
			coordinate.latitude, 
			coordinate.longitude, 
			zoomLevel, 
			imageWidth, 
			imageHeight]
	: nil;
}

-(Class)classForUsersPreferredService
{
	NSString* svc = [[NSUserDefaults standardUserDefaults] stringForKey:@"service"];
	return objc_getClass([svc UTF8String]);
}

-(void)displayError:(NSString*)localizedString for:(NSString*)topicKey
{
	UIAlertView* av = [[UIAlertView alloc] initWithTitle:NSLocalizedString(topicKey, topicKey) 
												 message:localizedString 
												delegate:nil 
									   cancelButtonTitle:NSLocalizedString(@"Dismiss", @"Dismiss") 
									   otherButtonTitles:nil];
	[av show];
	[av release];	
}

- (void)alertView:(UIAlertView *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	[actionSheet dismissWithClickedButtonIndex:buttonIndex animated:YES];
}

-(void)post
{
	@try {
		Class picturePosterClass = [self classForUsersPreferredService];
		if ( picturePosterClass )
		{
			PicturePoster* pp = [[(PicturePoster*)class_createInstance(picturePosterClass, 0) initWithOwner:self] retain];
			[pp start];
			[self.mainViewController picturePostingDidStart];
		}
	}
	@catch (NSException * e)
	{
		NSString* reason = [e reason];
		NSString* localizedReason = nil;
		NSBundle* thisBundle = [NSBundle bundleWithPath:[[NSBundle bundleForClass:[self class]] pathForResource:[e name] ofType:@"bundle"]];
		
		NSArray* args = [[e userInfo] objectForKey:@"args"];
		if ( args )
		{
			NSMutableData* buffer = [[[NSMutableData alloc] initWithLength:args.count * sizeof(NSObject*)] autorelease];
			[args getObjects:buffer.mutableBytes range:NSMakeRange(0, args.count)];
			NSString* locString = [thisBundle localizedStringForKey:reason value:reason table:@"Errors"];
			
			localizedReason = [[[NSString alloc] initWithFormat:locString locale:[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] arguments:(va_list)buffer.bytes] autorelease];
		}
		else 
		{
			localizedReason = [thisBundle localizedStringForKey:reason value:reason table:@"Errors"];
		}

		[self displayError:localizedReason for:@"posting"];
	}
}

-(void)visitBlog
{
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:self.bloggedURLString]];
}

-(FBSession*)session
{
	return m_session;
}

-(CLLocationCoordinate2D)currentCoordinate
{
	return m_locationManager.location.coordinate;
}

-(MKPlacemark*)currentPlacemark
{
	return m_currentPlacemark;
}

-(void)setCurrentPlacemark:(MKPlacemark*)value
{
	[m_currentPlacemark release];
	m_currentPlacemark = [value retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:HereIAmModel_CurrentPlacemarkChanged_Notification 
														object:self 
													  userInfo:m_currentPlacemark ? [NSDictionary dictionaryWithObject:m_currentPlacemark forKey:@"placemark"] : nil];	
}

-(NSString*)bloggedURLString
{
	return _bloggedURLString;
}

-(void)setBloggedURLString:(NSString*)v
{
	[_bloggedURLString release];
	_bloggedURLString = [v retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:HereIAmModel_BloggedURLStringChanged_Notification 
														object:self 
													  userInfo:_bloggedURLString ? [NSDictionary dictionaryWithObject:_bloggedURLString forKey:@"bloggedURLString"] : nil];
	
}

-(UIImage*)mapImage
{
	return m_mapImage;
}

-(void)setMapImage:(UIImage *)value
{
	[m_mapImage release];
	m_mapImage = [value retain];
	[[NSNotificationCenter defaultCenter] postNotificationName:HereIAmModel_MapImageChanged_Notification 
														object:self 
													  userInfo:nil];	
}

-(void)setPhoto:(UIImage*)i photoMember:(UIImage**)pmi notification:(NSString*)notification
{
	if ( nil != pmi )
	{
		[*pmi release];
		
		*pmi = ( i == nil ) ? nil : [makeCanonicalImage(i, -1) retain];
			//*pmi = [i retain];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:notification 
															object:self 
														  userInfo:*pmi ? [NSDictionary dictionaryWithObject:*pmi forKey:@"photo"] : nil];
	}
}

-(UIImage*)photoA
{
	return m_photoA;
}

-(void)setPhotoA:(UIImage *)v
{
	[self setPhoto:v photoMember:&m_photoA notification:HereIAmModel_LeftPhotoChanged_Notification];
}

-(UIImage*)photoB
{
	return m_photoB;
}

-(void)setPhotoB:(UIImage *)v
{
	[self setPhoto:v photoMember:&m_photoB notification:HereIAmModel_RightPhotoChanged_Notification];
}

#pragma mark FBSessionDelegate methods

+(NSString*)harpseal //facebook sessionApiKey
{
		//b042 e335 c075 2fcc 3da7 29c3 2e2c b75f
	
	NSMutableString* as = [NSMutableString stringWithCapacity:8*4];
	for (int i = 0; i < 8; i++)
	{
		switch (i) {
			case 5:
				[as appendString:@"29c3"];
				break;
			case 2:
				[as appendString:@"c075"];
				break;
			case 1:
				[as appendString:@"e335"];
				break;
			case 6:
				[as appendString:@"2e2c"];
				break;
			case 3:
				[as appendString:@"2fcc"];
				break;
			case 7:
				[as appendString:@"b75f"];
				break;
			case 0:
				[as appendString:@"b042"];
				break;
			case 4:
				[as appendString:@"3da7"];
				break;
			default:
				break;
		}
	}
	return as;
}

+(NSString*)manatee // facebook sessionApiSecret
{
		//6d9b b43c 316a fa05 295a bdcb 9026 31dd
	
	NSMutableString* as = [NSMutableString stringWithCapacity:8*4];
	for (int i = 0; i < 8; i++)
	{
		switch (i) {
			case 4:
				[as appendString:@"295a"];
				break;
			case 7:
				[as appendString:@"31dd"];
				break;
			case 1:
				[as appendString:@"b43c"];
				break;
			case 3:
				[as appendString:@"fa05"];
				break;
			case 5:
				[as appendString:@"bdcb"];
				break;
			case 0:
				[as appendString:@"6d9b"];
				break;
			case 2:
				[as appendString:@"316a" ];
				break;
			case 6:
				[as appendString:@"9026"];
				break;
			default:
				break;
		}
	}
	return as;
}

- (NSString*)sessionProxyForGetSession:(FBSession*)session
{
	return nil; // @"<YOUR SESSION CALLBACK)>";
}

#pragma mark PicturePosterOwner

-(id<PicturePostInfo>)picturePostInfo
{
	return [[[PrivatePicturePostInfo alloc] initWithHereIAmAppDelegate:self index:PicturePostInfoIndex_SingleCombined] autorelease];
}

-(NSArray*)picturePostInfoArray
{
	NSMutableArray* rv = [NSMutableArray arrayWithCapacity:3];
	if (self.photoA) [rv addObject:[[[PrivatePicturePostInfo alloc] initWithHereIAmAppDelegate:self index:PicturePostInfoIndex_Left] autorelease]];
	[rv addObject:[[[PrivatePicturePostInfo alloc] initWithHereIAmAppDelegate:self index:PicturePostInfoIndex_Central] autorelease]];
	if (self.photoB) [rv addObject:[[[PrivatePicturePostInfo alloc] initWithHereIAmAppDelegate:self index:PicturePostInfoIndex_Right] autorelease]];
	return rv;
}


-(NSData*)combinedPictureData
{
	UIImageView* ivA = nil;
	UIImageView* mainImageView = [[UIImageView alloc] initWithImage:self.mainViewController.annotatedImage];
	UIImageView* ivB = nil;
	CGRect tallFrame = CGRectMake(0, 0, mainImageView.frame.size.width, mainImageView.frame.size.height);
	CGRect wideFrame = CGRectMake(0, 0, tallFrame.size.height, tallFrame.size.width);
	
	CGRect pictureFrame = CGRectMake(0, 0, mainImageView.frame.size.width, mainImageView.frame.size.height);
	if ( self.photoA )
	{
		CGRect f = ( self.photoA.size.width > self.photoA.size.height ) ? wideFrame : tallFrame;
		ivA = [[UIImageView alloc] initWithFrame:f];
		ivA.image = self.photoA;
		pictureFrame.size.width += ivA.frame.size.width;
	}
	if ( self.photoB )
	{
		CGRect f = ( self.photoB.size.width > self.photoB.size.height ) ? wideFrame : tallFrame;
		ivB = [[UIImageView alloc] initWithFrame:f];
		ivB.image = self.photoB;
		pictureFrame.size.width += ivB.frame.size.width;
	}
	UIView* pictureView = [[[UIView alloc] initWithFrame:pictureFrame] autorelease];
	
	if ( self.photoA )
	{
		CGRect f = ivA.frame;
		f.origin.y = (mainImageView.frame.size.height - ivA.frame.size.height) / 2;
		ivA.frame = f;
		[pictureView addSubview:ivA];
		
		f = mainImageView.frame;
		f.origin.x = f.origin.x + ivA.frame.size.width;
		mainImageView.frame = f;
	}
	[pictureView addSubview:mainImageView];
	if ( self.photoB )
	{
		CGRect f = ivB.frame;
		f.origin.x = mainImageView.frame.origin.x + mainImageView.frame.size.width;
		f.origin.y = (mainImageView.frame.size.height - ivB.frame.size.height) / 2;
		ivB.frame = f;
		[pictureView addSubview:ivB];
	}
	
	[ivA release];
	[mainImageView release];
	[ivB release];
	
	return [HereIAmAppDelegate captureImage:pictureView 
								   location:m_locationManager.location 
									  title:[NSString stringWithFormat:@"latitude %lf, longitude %lf at %@",
											 m_locationManager.location.coordinate.latitude, m_locationManager.location.coordinate.longitude, [NSDate date]] 
									comment:m_requestString];			
}

-(NSString*)picturePostInfoFilename:(enum PicturePostInfoIndex)idx
{
	NSString* rv = nil;
	
	switch (idx) {
		case PicturePostInfoIndex_SingleCombined:
		case PicturePostInfoIndex_Central:
			rv = [NSString stringWithFormat:@"%@.jpg", [_yyyyMMdd_HHmmFormatter stringFromDate:[NSDate date]]];
			break;
			
		case PicturePostInfoIndex_Left:
			rv = [NSString stringWithFormat:@"%@-left.jpg", [_yyyyMMdd_HHmmFormatter stringFromDate:[NSDate date]]];
			break;
			
		case PicturePostInfoIndex_Right:
			rv = [NSString stringWithFormat:@"%@-right.jpg", [_yyyyMMdd_HHmmFormatter stringFromDate:[NSDate date]]];
			break;

		default:
			break;
	}
	return rv;
}

-(NSString*)picturePostInfoContentType:(enum PicturePostInfoIndex)idx
{
	return @"image/jpeg";
}

-(NSData*)picturePostInfoJPEGData:(enum PicturePostInfoIndex)idx
{
	NSData* rv = nil;
	
	NSString* title = [NSString stringWithFormat:@"latitude %lf, longitude %lf at %@",
					   m_locationManager.location.coordinate.latitude, m_locationManager.location.coordinate.longitude, [NSDate date]];	
	
	switch (idx) {
		case PicturePostInfoIndex_SingleCombined:
			rv = [self combinedPictureData];
			break;
			
		case PicturePostInfoIndex_Central:
			rv = [JPEGManager dataWithImage:self.mainViewController.annotatedImage 
								   location:m_locationManager.location 
									  title:title 
									comment:m_requestString
									 artist:NSFullUserName()
								   software:@"OpenStreetMap @ http://www.openstreetmap.org"
								  copyright:@"OpenStreetMap data is licensed under the Creative Commons Attribution-Share Alike 2.0 Generic License"];
			break;
			
		case PicturePostInfoIndex_Left:
			rv = [JPEGManager dataWithImage:self.photoA 
									location:m_locationManager.location 
									   title:title 
									 comment:m_requestString
									 artist:NSFullUserName()
								   software:@"Aktuala Loko @ http://www.rockholdco.com/RC/Aktuala_Loko.html"
								  copyright:[_photoCopyrightDateFormatter stringFromDate:[NSDate date]]];
			break;
			
		case PicturePostInfoIndex_Right:
			rv = [JPEGManager dataWithImage:self.photoB 
								   location:m_locationManager.location 
									  title:title 
									comment:m_requestString
									 artist:NSFullUserName()
								   software:@"Aktuala Loko @ http://www.rockholdco.com/RC/Aktuala_Loko.html"
								  copyright:[_photoCopyrightDateFormatter stringFromDate:[NSDate date]]];
			break;
			
		default:
				// shouldn't happen; throw an exception
			[RCException rcExceptionWithSubDomain:@"Aktuala Loko" erroMsgKey:[NSString stringWithFormat:@"Internal error at %s:%d", __FILE__, __LINE__]];
			break;
	}
	return rv;
}


-(NSString*)comment
{
	return m_comment;
}

-(void)setComment:(NSString *)comment
{
	[m_comment release];
	m_comment = [comment retain];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:HereIAmModel_CommentChanged_Notification 
														object:self 
													  userInfo:nil];	
}

#pragma mark PicturePostInfo

+(NSData*)captureImage:(UIView*)view location:(CLLocation*)location title:(NSString*)title comment:(NSString*)comment
{
	UIGraphicsBeginImageContext(view.bounds.size);
	[view.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage* capturedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return [JPEGManager dataWithImage:capturedImage 
							 location:location 
								title:title 
							  comment:comment
							   artist:NSFullUserName()
							 software:NSLocalizedString(@"OSMSoftwareURL", @"OpenStreetMap @ http://www.openstreetmap.org")
							copyright:NSLocalizedString(@"OSMCopyright", @"OpenStreetMap data is licensed under the Creative Commons Attribution-Share Alike 2.0 Generic License")];
}

-(NSString*)filename
{
	return [NSString stringWithFormat:@"%@.jpg", [_yyyyMMdd_HHmmFormatter stringFromDate:[NSDate date]]];
}

-(NSString*)contentType
{
	return @"image/jpeg";
}

-(void)picturePoster:(PicturePoster*)pp sendDidFail:(NSError*)error
{	
	[pp release];
	
	self.bloggedURLString = nil;
	[self.mainViewController picturePostingDone];
	[self displayError:error.localizedDescription for:@"sending map"];
}


-(void)picturePoster:(PicturePoster*)pp sendDidEnd:(NSString*)mediaURL
{
	[pp release];
	
	[self.mainViewController picturePostingDone];
	self.bloggedURLString = mediaURL;
}

-(NSURL*)apiServiceURL
{
	return [NSURL URLWithString:[[NSUserDefaults standardUserDefaults] stringForKey:@"service"]];
}

-(NSString*)username
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"username"];
}

-(NSString*)password
{
	return [[NSUserDefaults standardUserDefaults] stringForKey:@"password"];
}

#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	[m_connection release];
	m_connection = nil;
	
	[m_receivedData release];
	m_receivedData = nil;
	
	[self.mainViewController downloadingMapDidEnd];
	[self displayError:error.localizedDescription for:@"getting map"];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if ( nil == m_receivedData )
	{
		m_receivedData = [[NSMutableData data] retain];
	}

	[m_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	NSHTTPURLResponse* theHttpUrlResponse = (NSHTTPURLResponse*)response;
	
	[m_receivedData setLength:0];
	
	NSInteger statusCode = [theHttpUrlResponse statusCode];
	if ( statusCode != 200 )
	{
		[connection cancel];
		[self displayError:[NSHTTPURLResponse localizedStringForStatusCode:statusCode] for:@"received unexpected response from server"];
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[m_connection release];
	m_connection = nil;
	
	[self.mainViewController downloadingMapDidEnd];

	if ( [m_receivedData length] > 0 )
	{
		self.mapImage = [UIImage imageWithData:m_receivedData];
	}
	
	[m_receivedData release];
	m_receivedData = nil;
}

#pragma mark CLLocationManagerDelegate methods

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	int zoomLevel = 15;
	
	if ( m_connection )
	{
		[m_connection cancel];
		[m_connection release];
	}
	[m_receivedData release];
	m_receivedData = nil;
	
	if ( m_rg )
	{
		[m_rg cancel];
		[m_rg release];
	}
	[self.mainViewController setLatitude:newLocation.coordinate.latitude longitude:newLocation.coordinate.longitude];
	m_rg = [[MKReverseGeocoder alloc] initWithCoordinate:newLocation.coordinate];
	m_rg.delegate = self;
	[m_rg start];
	
	m_requestString = [[self urlStringWithCoordinate:newLocation.coordinate
										  imageWidth:self.mainViewController.mapImageSize.width 
										 imageHeight:self.mainViewController.mapImageSize.height 
										   zoomLevel:zoomLevel] retain];
	
	if ( !m_requestString )
		return;
	
	NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:m_requestString]];
	m_connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if ( m_connection )
	{
		[self.mainViewController downloadingMapDidStart];
	}
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError*)error
{
	[self.mainViewController downloadingMapDidEnd];

	switch ([error code])
	{
		case kCLErrorLocationUnknown:
				// let Location Manager keep trying
			break;

		case kCLErrorDenied:
			[m_locationManager stopUpdatingLocation];
			break;
			
				// do something more interesting
		case kCLErrorNetwork:
		case kCLErrorHeadingFailure:
			[self displayError:error.localizedDescription for:@"getting map"];
			break;
			
		default:
			break;
	}
}

#pragma mark MKReverseGeocoderDelegate methods

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFindPlacemark:(MKPlacemark*)placemark
{
	[m_rg release]; m_rg = nil;
	self.currentPlacemark = placemark;
}

- (void)reverseGeocoder:(MKReverseGeocoder *)geocoder didFailWithError:(NSError*)error
{
	[m_rg release]; m_rg = nil;
	self.currentPlacemark = nil;
}

@end

#pragma mark Twitter OAuthConsumerLib API key and secret

@implementation PrivateOAConsumer

-(NSString*)key
{
		// hafb F9II eVLP PV4O I0gDg
	NSMutableString* k = [NSMutableString stringWithCapacity:25];
	for (int i = 0; i<5; i++)
	{
		switch (i) {
			case 1:
				[k appendString:@"F9II"];
				break;
			case 3:
				[k appendString:@"PV4O"];
				break;
			case 4:
				[k appendString:@"I0gDg"];
				break;
			case 0:
				[k appendString:@"hafb"];
				break;
			case 2:
				[k appendString:@"eVLP"];
				break;
			default:
				break;
		}
	}
	return k;
}

-(NSString*)secret
{
		// fxBQ mJYk oOnl I2J1 OhhT EM0L ar1A odqf Trac 6UaM
	
	NSMutableString* s = [NSMutableString stringWithCapacity:40];
	for (int i = 0; i<10; i++)
	{
		switch (i) {
			case 3:
				[s appendString:@"I2J1"];
				break;
			case 8:
				[s appendString:@"Trac"];
				break;
			case 2:
				[s appendString:@"oOnl"];
				break;
			case 0:
				[s appendString:@"fxBQ"];
				break;
			case 4:
				[s appendString:@"OhhT"];
				break;
			case 9:
				[s appendString:@"6UaM"];
				break;
			case 5:
				[s appendString:@"EM0L"];
				break;
			case 1:
				[s appendString:@"mJYk"];
				break;
			case 7:
				[s appendString:@"odqf"];
				break;
			case 6:
				[s appendString:@"ar1A"];
				break;
			default:
				break;
		}
	}
	return s;
}
@end