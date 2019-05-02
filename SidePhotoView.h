//
//  SidePhotoView.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 5/21/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HereIAmModel.h"

@protocol SidePhotoViewDelegate;

@class UIViewController;

@interface SidePhotoView : UIView < UIImagePickerControllerDelegate, UINavigationControllerDelegate >
{
	id<SidePhotoViewDelegate>	_controller;
	id<HereIAmModel>			_photoSource;
	SEL							_setPhotoSelector;
	
	UIImageView*				m_photoView;
	UIButton*					m_cameraButton;
	UIButton*					m_clearPhotoButton;
	UIImagePickerController*	_imagePickerController;
}

-(id)initWithFrame:(CGRect)frame
		controller:(id<SidePhotoViewDelegate>)controller
	   photoSource:(id<HereIAmModel>)photoSource
  setPhotoSelector:(SEL)setPhotoSelector
	  initialPhoto:(UIImage*)initialPhoto
changeNotification:(NSString*)changeNotification;

@end

@protocol SidePhotoViewDelegate <NSObject>

-(void)sidePhotoView:(SidePhotoView*)sidePhotoView tapped:(int)sidePhoto;
-(void)sidePhotoView:(SidePhotoView*)sidePhotoView clear:(int)sidePhoto;

	// taken directly from UIViewController
- (void)presentModalViewController:(UIViewController *)modalViewController animated:(BOOL)animated; // Display another view controller as a modal child. Uses a vertical sheet transition if animated.
- (void)dismissModalViewControllerAnimated:(BOOL)animated; // Dismiss the current modal child. Uses a vertical sheet transition if animated.

@end