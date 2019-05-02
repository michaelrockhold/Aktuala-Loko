//
//  MainViewController.h
//  HereIAm
//
//  Created by Michael Rockhold on 1/17/10.
//  Copyright The Rockhold Company 2010. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>
#import "SettingsViewController.h"

@class ParsedTwitterResponse;
@class MKPlacemark;

@interface MainViewController : UIViewController <
									UITextViewDelegate, 
									UIScrollViewDelegate, 
									SettingsViewControllerDelegate,
									UINavigationControllerDelegate
									>
{
	CGRect	m_textViewFrameBeforeKeyboardShown;
	CGRect m_characterCountLabelFrameBeforeKeyboardShown;
	
	BOOL	m_pageControlUsed;
	BOOL	fInitialized;
	
	IBOutlet UIActivityIndicatorView* m_gettingMapImageIndicatorView;
	IBOutlet UIImageView* m_mapImageView;
	IBOutlet UITextView* m_textView;
	IBOutlet UILabel* m_tapHereLabel;
	IBOutlet UILabel* m_characterCountLabel;
	IBOutlet UIPageControl* m_pageControl;
	IBOutlet UIView* m_page1;
	
	IBOutlet UIView*		m_scrollViewPlaceHolder;
	UIScrollView*			m_scrollView;
	NSInteger				m_currentPage;
		
	IBOutlet UIView* m_dimmerView;
	IBOutlet UIView* m_compositeMapView;
	IBOutlet UILabel* m_coordinateLabel;
	IBOutlet UILabel* m_placemarkLabel;
	
	IBOutlet UIBarButtonItem* m_postBarButtonItem;
	IBOutlet UIBarButtonItem* m_linkToTweetBarButtonItem;
	IBOutlet UIBarButtonItem* m_settingsBarButtonItem;
	
	IBOutlet UIActivityIndicatorView* m_postActivityIndicatorView;
}

@property (nonatomic, retain, readonly) UIImage* annotatedImage;
@property (nonatomic, readonly)			CGSize mapImageSize;

-(IBAction)postIt:(id)sender;
-(IBAction)goToTweet:(id)sender;
-(IBAction)adjustSettings:(id)sender;
-(IBAction)changePage:(id)sender;

-(void)picturePostingDidStart;
-(void)picturePostingDone;

-(void)keyboardWillShow:(NSNotification *)notification;
-(void)keyboardWillHide:(NSNotification *)notification;

-(void)setLatitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude;
-(void)downloadingMapDidStart;
-(void)downloadingMapDidEnd;

@end
