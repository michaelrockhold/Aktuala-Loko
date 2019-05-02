//
//  SettingsViewController.h
//  HereIAm
//
//  Created by Michael Rockhold on 1/19/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FBConnect.h"
#import "FBLoginViewController.h"

@protocol SettingsViewControllerDelegate;
@class TwitterOAuthLogin;

@interface SettingsViewController :  UIViewController <UITableViewDelegate, UITableViewDataSource, RCWebDialogViewControllerDelegate >
{
	id <SettingsViewControllerDelegate> delegate;
		
	IBOutlet UITableView* m_tableView;	
	IBOutlet UITableViewCell* m_mapServiceURLCell;
	IBOutlet UITextField* m_mapServiceURLField;
	
	NSUInteger m_selectedPicturePostingServiceIndex;
	NSArray* m_postingServiceTitles;
	NSArray* m_postingServiceValues;
	NSString* m_postingServiceDefaultValue;
	NSString* m_postingServiceValue;
	
	TwitterOAuthLogin* _tol;
}

@property (nonatomic, assign) id <SettingsViewControllerDelegate> delegate;

-(id)initWithSettingsViewControllerDelegate:(id<SettingsViewControllerDelegate>)delegate;

@end


@protocol SettingsViewControllerDelegate

-(void)settingsViewControllerDidFinish:(SettingsViewController *)controller with:(BOOL)ok;

@end

