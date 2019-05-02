//
//  SidePhotoView.m
//  Here-I-Am
//
//  Created by Michael Rockhold on 5/21/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "SidePhotoView.h"

@interface SidePhotoView (PrivateMethods)

-(void)photoChangedNotificationHandler:(NSNotification*)notification;

-(void)setPhoto:(UIImage*)p;

-(void)tappedButton:(id)sender;

-(void)clearButtonTapped:(id)sender;

@end

@implementation SidePhotoView


-(id)initWithFrame:(CGRect)frame
		controller:(id<SidePhotoViewDelegate>)controller
	   photoSource:(id<HereIAmModel>)photoSource
 setPhotoSelector:(SEL)setPhotoSelector
	  initialPhoto:(UIImage*)initialPhoto
changeNotification:(NSString*)changeNotification
{
    if ((self = [super initWithFrame:frame]))
	{
		_controller = controller; // note, not retained
		_photoSource = photoSource;
		_setPhotoSelector = setPhotoSelector;
		
        // Initialization code
		m_photoView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height)];
		m_photoView.contentMode = UIViewContentModeScaleAspectFill;
		m_photoView.backgroundColor = [UIColor grayColor];
		
		UIImage* cameraImage = [UIImage imageNamed:@"BigCamera.png"];
		m_cameraButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		CGFloat w = self.bounds.size.width / 2 - cameraImage.size.width / 2;
		CGFloat h = self.bounds.size.height / 2 - cameraImage.size.height / 2;
		h -= h/2;
		m_cameraButton.frame = CGRectMake(w, h, cameraImage.size.width, cameraImage.size.height);
		[m_cameraButton setImage:cameraImage forState:UIControlStateNormal];
		[m_cameraButton addTarget:self action:@selector(tappedButton:) forControlEvents:UIControlEventTouchUpInside];

		UIImage* clearPhotoImage = [UIImage imageNamed:@"ClearPhoto.png"];
		m_clearPhotoButton = [[UIButton buttonWithType:UIButtonTypeCustom] retain];
		m_clearPhotoButton.frame = CGRectMake(10, 10, clearPhotoImage.size.width, clearPhotoImage.size.height);
		[m_clearPhotoButton setImage:clearPhotoImage forState:UIControlStateNormal];
		[m_clearPhotoButton addTarget:self action:@selector(clearButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
		
		[self addSubview:m_photoView];
		[self addSubview:m_cameraButton];
		[self addSubview:m_clearPhotoButton];

		[self setPhoto:initialPhoto];
		
		if ( [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera] )
		{
			_imagePickerController = [[UIImagePickerController alloc] init];
			_imagePickerController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
			_imagePickerController.delegate = self;
			_imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;			
		}
		else
		{
			_imagePickerController = nil;
		}
		
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(photoChangedNotificationHandler:) 
													 name:changeNotification
												   object:_photoSource];
	}
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_imagePickerController release];
	[m_photoView release];
	[m_cameraButton release];
    [super dealloc];
}

-(void)photoChangedNotificationHandler:(NSNotification*)notification
{
	id photo = [[notification userInfo] objectForKey:@"photo"];
	[self setPhoto:(UIImage*)photo];
}

-(void)setPhoto:(UIImage*)p
{
	m_photoView.image = p;

	if ( p && ![p isEqual:[NSNull null]] )
	{
		m_cameraButton.hidden = YES;
		m_clearPhotoButton.hidden = NO;
	}
	else 
	{
		m_cameraButton.hidden = NO;
		m_clearPhotoButton.hidden = YES;
	}
}

-(void)tappedButton:(id)sender
{
	if ( _imagePickerController != nil )
		[_controller presentModalViewController:_imagePickerController animated:YES];
}

-(void)clearButtonTapped:(id)sender
{
	[_photoSource performSelector:_setPhotoSelector withObject:nil];
}

#pragma mark UIImagePickerControllerDelegate methods

-(void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary*)info
{	
	UIImage* photo = [info objectForKey:UIImagePickerControllerOriginalImage];
	if ( photo )
	{
		[_photoSource performSelector:_setPhotoSelector withObject:photo];
	}
	[_controller dismissModalViewControllerAnimated:YES];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController*)picker
{
	[_controller dismissModalViewControllerAnimated:YES];
}

#pragma mark UINavigationControllerDelegate methods

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
}

@end
