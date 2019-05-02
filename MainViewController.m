//
//  MainViewController.m
//  HereIAm
//
//  Created by Michael Rockhold on 1/17/10.
//  Copyright The Rockhold Company 2010. All rights reserved.
//

#import "MainViewController.h"
#import "SettingsViewController.h"
#import "HereIAmAppDelegate.h"
#import "PicturePoster.h"
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>
#import <MobileCoreServices/UTCoreTypes.h>
#import "HereIAmModel.h"
#import "SidePhotoView.h"

const NSUInteger MAXTWITTERCOMMENTLENGTH = 140;
const NSUInteger TWITPICSHORTURLLENGTH = 20;
const CGFloat kScrollObjWidth = 320.0;
const CGFloat kScrollObjHeight = 320.0;

@interface MainViewController (PrivateMethods) < SidePhotoViewDelegate >

-(void)priv_viewDidLoad;
-(void)priv_viewDidUnload;

-(void)updateRemainingCharactersString;
-(UIImage*)noPhotoImage;
-(void)gotoPage:(int)page animated:(BOOL)animated;

-(void)setComment:(NSString*)v;
-(void)setMapImage:(UIImage*)v;

-(void)mapImageChangedHandler:(NSNotification*)notification;
-(void)coordinateChangedHandler:(NSNotification*)notification;
-(void)commentChangedHandler:(NSNotification*)notification;
-(void)currentPlacemarkChangedHandler:(NSNotification*)notification;

-(void)bloggedURLStringChangedHandler:(NSNotification*)notification;

-(void)setPlacemark:(MKPlacemark*)value;
-(void)clearPlacemarkInfo;
@end

@implementation MainViewController

-(void)awakeFromNib
{
	m_pageControlUsed = NO;
	m_currentPage = 1;
}

-(void)viewDidLoad
{
	[super viewDidLoad];
	[self priv_viewDidLoad];
}

-(void)viewDidUnload
{
	[self priv_viewDidUnload];
	[super viewDidUnload];
}

-(void)priv_viewDidLoad
{
	UIBarButtonItem* space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	UIBarButtonItem* space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	self.toolbarItems = [NSArray arrayWithObjects:m_postBarButtonItem, space, m_linkToTweetBarButtonItem, space2, m_settingsBarButtonItem, nil];
	[space release];
	[space2 release];
	
	m_textView.delegate = self;	

	m_scrollView = [[UIScrollView alloc] initWithFrame:m_scrollViewPlaceHolder.frame];
	[m_scrollViewPlaceHolder addSubview:m_scrollView];
	
	SidePhotoView* leftSidePhotoView = [[SidePhotoView alloc] initWithFrame:m_scrollViewPlaceHolder.frame 
																 controller:self 
																photoSource:[HereIAmAppDelegate model]
														   setPhotoSelector:@selector(setPhotoA:)
															   initialPhoto:[HereIAmAppDelegate model].photoA
														 changeNotification:HereIAmModel_LeftPhotoChanged_Notification
										];
	
	SidePhotoView* rightSidePhotoView = [[SidePhotoView alloc] initWithFrame:m_scrollViewPlaceHolder.frame 
																  controller:self 
																 photoSource:[HereIAmAppDelegate model]
															setPhotoSelector:@selector(setPhotoB:)
																initialPhoto:[HereIAmAppDelegate model].photoB
														  changeNotification:HereIAmModel_RightPhotoChanged_Notification
										 ];
	
		// load all the page views from our bundle and add them to the scroll view
	NSUInteger i = 0;
	for (UIView* v in [NSArray arrayWithObjects:leftSidePhotoView, m_page1, rightSidePhotoView, nil])
	{
		CGRect frame = m_scrollView.frame;
		frame.origin.x = frame.size.width * i;
		frame.origin.y = 0;
		v.frame = frame;
		v.clipsToBounds = YES;
		[m_scrollView addSubview:v];
		i++;
	}
	[leftSidePhotoView release];
	[rightSidePhotoView release];
	
	[m_scrollView setContentSize:CGSizeMake((m_scrollView.subviews.count * m_scrollView.bounds.size.width), m_scrollView.bounds.size.height)];
	m_scrollView.pagingEnabled = YES;
	m_scrollView.delegate = self;	

	m_pageControl.currentPage = m_currentPage;
    [self gotoPage:m_currentPage animated:NO];
	
	id<HereIAmModel> model = [HereIAmAppDelegate model];
	NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
	CLLocationCoordinate2D position = model.currentCoordinate;
	
	[self setLatitude:position.latitude longitude:position.longitude];
	[self setComment:model.comment];
	[self setMapImage:model.mapImage];

	[notificationCenter addObserver:self selector:@selector(mapImageChangedHandler:)			name:HereIAmModel_MapImageChanged_Notification			object:model];
	[notificationCenter addObserver:self selector:@selector(commentChangedHandler:)				name:HereIAmModel_CommentChanged_Notification			object:model];
	[notificationCenter addObserver:self selector:@selector(currentPlacemarkChangedHandler:)	name:HereIAmModel_CurrentPlacemarkChanged_Notification	object:model];
	[notificationCenter addObserver:self selector:@selector(bloggedURLStringChangedHandler:)	name:HereIAmModel_BloggedURLStringChanged_Notification	object:model];
}

-(void)priv_viewDidUnload
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[m_scrollView release];
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	[self.navigationController setToolbarHidden:NO animated:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];

	[super viewWillDisappear:animated];
}

-(CGSize)mapImageSize { return m_mapImageView.frame.size; }

- (void)settingsViewControllerDidFinish:(SettingsViewController *)controller with:(BOOL)ok
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)postIt:(id)sender
{
	[[HereIAmAppDelegate model] post];
}

- (IBAction)goToTweet:(id)sender
{
	[[HereIAmAppDelegate model] visitBlog];
}

- (IBAction)adjustSettings:(id)sender
{
	SettingsViewController* settingsViewController = [[SettingsViewController alloc] initWithSettingsViewControllerDelegate:self];
	settingsViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	[self.navigationController pushViewController:settingsViewController animated:YES];
	[settingsViewController release];
}

#pragma mark -

-(void)scrollViewDidScroll:(UIScrollView*)sender
{
		// We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
		// which a scroll event generated from the user hitting the page control triggers updates from
		// the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if ( !m_pageControlUsed )
	{
			// Switch the indicator when more than 50% of the previous/next page is visible
		CGFloat pageWidth = m_scrollView.frame.size.width;
		int page = floor((m_scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
		m_pageControl.currentPage = page;
		m_currentPage = page;
    }
}

	// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
-(void)scrollViewWillBeginDragging:(UIScrollView*)scrollView
{
	m_pageControlUsed = NO;
}

	// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
-(void)scrollViewDidEndDecelerating:(UIScrollView*)scrollView
{
	m_pageControlUsed = NO;
}

-(void)gotoPage:(int)page animated:(BOOL)animated
{
	m_currentPage = page;
		// update the scroll view to the appropriate page
    CGRect frame = m_scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [m_scrollView scrollRectToVisible:frame animated:animated];
    
		// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    m_pageControlUsed = YES;
}

-(IBAction)changePage:(id)sender
{
    [self gotoPage:m_pageControl.currentPage animated:YES];
}

#pragma mark -
-(void)setComment:(NSString*)v
{
	m_textView.text = v;
	[self updateRemainingCharactersString];
}

-(void)commentChangedHandler:(NSNotification*)notification;
{
	[self setComment:((id<HereIAmModel>)[notification object]).comment];
}
#pragma mark -

-(UIImage*)annotatedImage
{
	UIGraphicsBeginImageContext(m_compositeMapView.bounds.size);
	[m_compositeMapView.layer renderInContext:UIGraphicsGetCurrentContext()];
	UIImage* capturedImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return capturedImage;
}

-(UIImage*)noPhotoImage
{
	return [UIImage imageNamed:@"BigCamera.png"];
}

-(void)updateRemainingCharactersString
{
	m_characterCountLabel.text = [NSString stringWithFormat:@"%d", m_textView.text.length];
	if ( m_textView.text.length > MAXTWITTERCOMMENTLENGTH - TWITPICSHORTURLLENGTH )
	{
		m_characterCountLabel.backgroundColor = [UIColor redColor];
	}
	
	m_tapHereLabel.hidden = m_textView.text.length != 0;
	
	m_postBarButtonItem.enabled = 
		m_textView.text.length 
		&& m_mapImageView.image != nil 
		&& m_dimmerView.hidden 
		&& ( nil != [[HereIAmAppDelegate model] classForUsersPreferredService] );
}

#pragma mark -
- (void)keyboardWillShow:(NSNotification *)notification
{
	m_textViewFrameBeforeKeyboardShown = m_textView.frame;
	m_characterCountLabelFrameBeforeKeyboardShown = m_characterCountLabel.frame;
			
	NSDictionary* userInfo = [notification userInfo];
	
	NSValue* keyboardBoundsValue = [userInfo objectForKey:UIKeyboardBoundsUserInfoKey];
		//NSValue* keyboardCenterValue = [userInfo objectForKey:UIKeyboardCenterEndUserInfoKey];
	
	CGRect keyboardBounds = [keyboardBoundsValue CGRectValue];
		//CGPoint keyboardCenter = [keyboardCenterValue CGPointValue];
	
	CGRect newViewFrame = self.view.bounds;
	newViewFrame.size.height -= (keyboardBounds.size.height + m_characterCountLabel.bounds.size.height);
	if ( !self.navigationController.toolbarHidden )
		newViewFrame.size.height += self.navigationController.toolbar.bounds.size.height;
	
	CGRect characterCountLabelFrame = CGRectMake(0, newViewFrame.size.height, newViewFrame.size.width, m_characterCountLabel.frame.size.height);
	
		// Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
		// Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
	m_linkToTweetBarButtonItem.enabled = NO;
	
    m_textView.frame = newViewFrame;
	m_characterCountLabel.frame = characterCountLabelFrame;
	
	m_gettingMapImageIndicatorView.hidden = YES;
		//m_compositeMapView.hidden = YES;
	
    [UIView commitAnimations];	
	
	[self updateRemainingCharactersString];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
		// Get the duration of the animation.
	NSDictionary* userInfo = [notification userInfo];
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];

	[UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];

	if ( [m_gettingMapImageIndicatorView isAnimating] )
		m_gettingMapImageIndicatorView.hidden = NO;
	m_compositeMapView.hidden = NO;
	
	m_characterCountLabel.frame = m_characterCountLabelFrameBeforeKeyboardShown;
	m_textView.frame = m_textViewFrameBeforeKeyboardShown;
	
    [UIView commitAnimations];	
}

- (void)textViewDidChange:(UITextView *)textView
{
	if ( textView == m_textView )
		[HereIAmAppDelegate model].comment = m_textView.text;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
		// Any new character added is passed in as the "text" parameter
    if ([text isEqualToString:@"\n"])
	{
			// Be sure to test for equality using the "isEqualToString" message
        [textView resignFirstResponder];
		
			// Return FALSE so that the final '\n' character doesn't get added
        return FALSE;
    }
		// For any other character return TRUE so that the text gets added to the view,
		// assuming there's room
		//NSUInteger newLength = m_textView.text.length - range.length + text.length + TWITPICSHORTURLLENGTH;
	
	return TRUE; //newLength <= MAXTWITTERCOMMENTLENGTH;
}
#pragma mark -

-(void)setLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{	
	char latLetter = 'N';
	char longLetter = 'E';
	
	if ( latitude < 0 )
	{
		latLetter = 'S';
		latitude = -latitude;
	}
	if ( longitude < 0 )
	{
		longLetter = 'W';
		longitude = -longitude;
	}
	
	NSUInteger degreesLatitude = floor(latitude);
	latitude = (latitude - degreesLatitude) * 60;
	
	NSUInteger minutesLatitude = floor(latitude);
	latitude = (latitude - minutesLatitude) * 60;
	
	NSUInteger secondsLatitude = floor(latitude);
	
	NSUInteger degreesLongitude = floor(longitude);
	longitude = (longitude - degreesLongitude) * 60;
	
	NSUInteger minutesLongitude = floor(longitude);
	longitude = (longitude - minutesLongitude) * 60;
	
	NSUInteger secondsLongitude = floor(longitude);
	
	NSMutableString* retval = [[NSString stringWithFormat:@"%dº %d' %d\"", degreesLatitude, minutesLatitude, secondsLatitude] mutableCopy];
	
	if ( latitude != 0 )
	{
		[retval appendFormat:@" %c", latLetter];
	}
	[retval appendFormat:@", %dº %d' %d\"", degreesLongitude, minutesLongitude, secondsLongitude];
	if ( longitude != 0 )
	{
		[retval appendFormat:@" %c", longLetter];
	}
	m_coordinateLabel.text = retval;
	[m_coordinateLabel sizeToFit];
	m_coordinateLabel.hidden = NO;
}

-(void)coordinateChangedHandler:(NSNotification*)notification
{
	CLLocationCoordinate2D position = ((id<HereIAmModel>)[notification object]).currentCoordinate;
	[self setLatitude:position.latitude longitude:position.longitude];
}
#pragma mark -

-(void)setPlacemark:(MKPlacemark*)placemark
{
	NSMutableString* placemarkString = [NSMutableString stringWithCapacity:32];
	
	if ( placemark.subThoroughfare ) [placemarkString appendString:placemark.subThoroughfare];
	if ( placemark.thoroughfare )
	{
		if ( placemarkString.length ) [placemarkString appendString:@" "];
		[placemarkString appendString:placemark.thoroughfare];
	}
	
	NSMutableString* line1 = [NSMutableString stringWithCapacity:16];
	if ( placemark.subLocality ) [line1 appendString:placemark.subLocality];
	if ( placemark.locality )
	{
		if (line1.length ) [line1 appendString:@", "];
		[line1 appendString:placemark.locality];
	}
	if ( placemark.administrativeArea )
	{
		if (line1.length ) [line1 appendString:@", "];
		[line1 appendString:placemark.administrativeArea];
	}
	
	if ( placemarkString.length && line1.length ) [placemarkString appendString:@"\n"];
	if ( line1.length ) [placemarkString appendString:line1];
	
	if ( placemarkString.length && placemark.country ) [placemarkString appendString:@"\n"];
	if ( placemark.country ) [placemarkString appendString:placemark.country];
	
	unsigned numberOfLines, index, stringLength = [placemarkString length];
	for (index = 0, numberOfLines = 0; index < stringLength; numberOfLines++)
		index = NSMaxRange([placemarkString lineRangeForRange:NSMakeRange(index, 0)]);
	
	m_placemarkLabel.numberOfLines = numberOfLines;
	m_placemarkLabel.text = placemarkString;
	[m_placemarkLabel sizeToFit];
	m_placemarkLabel.hidden = NO;
}

-(void)clearPlacemarkInfo
{
	m_placemarkLabel.hidden = YES;
	m_placemarkLabel.text = nil;
}

-(void)currentPlacemarkChangedHandler:(NSNotification*)notification
{
	MKPlacemark* placemark = [HereIAmAppDelegate model].currentPlacemark;
 
	if ( placemark == nil )
		[self clearPlacemarkInfo];
	else
		[self setPlacemark:placemark];
}

-(void)bloggedURLStringChangedHandler:(NSNotification*)notification
{
	m_linkToTweetBarButtonItem.enabled =  nil != [notification.userInfo objectForKey:@"bloggedURLString"];
}

#pragma mark -

-(void)setMapImage:(UIImage*)v
{
	m_mapImageView.image = v;
	[self updateRemainingCharactersString];
}

-(void)mapImageChangedHandler:(NSNotification*)notification
{
	[self setMapImage:((id<HereIAmModel>)[notification object]).mapImage];
}
#pragma mark -

-(void)downloadingMapDidStart
{
	[m_gettingMapImageIndicatorView startAnimating];
}

-(void)downloadingMapDidEnd
{
	[m_gettingMapImageIndicatorView stopAnimating];
}

-(void)picturePostingDidStart
{
	m_dimmerView.hidden = NO;
	m_dimmerView.userInteractionEnabled = YES;
	[self updateRemainingCharactersString];
	[m_postActivityIndicatorView startAnimating];
}

-(void)picturePostingDone
{
	m_dimmerView.hidden = YES;
	m_dimmerView.userInteractionEnabled = NO;
	[m_postActivityIndicatorView stopAnimating];
	[self updateRemainingCharactersString];
}

@end
