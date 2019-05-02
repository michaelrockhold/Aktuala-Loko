//
//  SettingsViewController.m
//  HereIAm
//
//  Created by Michael Rockhold on 1/19/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "SettingsViewController.h"
#import "FBLoginButton.h"
#import "FBRequest.h"
#import "PicturePoster.h"
#import "FBLoginViewController.h"
#import "FBGetUserName.h"
#import "TwitterLoginButton.h"
#import "TWSession.h"
#import "TwitterOAuthLogin.h"

@interface BaseLoginTableCell : UITableViewCell
{
}

@property (nonatomic, retain, readonly) UIControl* loginButton;

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier;
-(void)setUserName:(NSString*)name;

@end


@implementation BaseLoginTableCell

-(BaseLoginButton*)makeLoginButton { return nil; }

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
	if ( self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier] )
	{
		self.selectionStyle = UITableViewCellSelectionStyleNone;
		[self setUserName:nil];
		
		self.accessoryView = [self makeLoginButton];
	}
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(UIControl*)loginButton
{
	return (UIControl*)self.accessoryView;
}

-(void)layoutSubviews
{
	[super layoutSubviews];
	
	CGRect textFrame = self.textLabel.frame;
	textFrame.origin.y -= 4;
	self.textLabel.frame = textFrame;
	self.textLabel.font = [self.textLabel.font fontWithSize:self.textLabel.font.pointSize - 2.0];
	
	self.accessoryView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
	CGRect accessoryFrame = self.accessoryView.frame;
	accessoryFrame.origin.y -= 15;
	self.accessoryView.frame = accessoryFrame;
	
	self.detailTextLabel.textAlignment = UITextAlignmentCenter;
	CGRect detailTextFrame = self.detailTextLabel.frame;
	detailTextFrame.size.width = 280;
	self.detailTextLabel.frame = detailTextFrame;
	self.detailTextLabel.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
	detailTextFrame = self.detailTextLabel.frame;
	detailTextFrame.origin.y += 15;
	self.detailTextLabel.frame = detailTextFrame;
}

-(void)setUserName:(NSString*)name
{
	self.detailTextLabel.text = name ? [NSString stringWithFormat:@"Logged in as %@", name] : @"Not logged on";
}

@end

#pragma mark -

@interface FacebookLoginTableCell : BaseLoginTableCell < FBGetUserNameDelegate >
{
	FBGetUserName* _getUserName;
}

-(void)getUserNameFromSession:(FBSession*)s;
-(void)session_login:(NSNotification*)notification;
-(void)session_logout:(NSNotification*)notification;

@end


@implementation FacebookLoginTableCell

-(BaseLoginButton*)makeLoginButton
{
	FBLoginButton* facebookLoginButton = [[[FBLoginButton alloc] initWithFrame:CGRectMake(0, 0, 176, 31)] autorelease];
	facebookLoginButton.style = FBLoginButtonStyleWide;
	return facebookLoginButton;
}

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
	if ( self = [super initWithReuseIdentifier:reuseIdentifier] )
	{		
		FBSession* s = [FBSession session];
		if ( [s isConnected] )
			[self getUserNameFromSession:s];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(session_login:) name:cFBSessionLoginNotification object:s];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(session_logout:) name:cFBSessionLogoutNotification object:s];
	}
	return self;
}	

-(void)dealloc
{
	[_getUserName release];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[FBSession session]];
	[super dealloc];
}

-(void)getUserNameFromSession:(FBSession*)s
{
	if ( _getUserName ) return;
	
	_getUserName = [[FBGetUserName alloc] initWithGetUserNameDelegate:self userID:s.uid];
	[_getUserName start];
}

#pragma mark FBSession Login/logout notifications

-(void)session_login:(NSNotification*)notification
{	
	[self getUserNameFromSession:(FBSession*)[notification object]];
}

-(void)session_logout:(NSNotification*)notification
{
	[self setUserName:nil];
}

#pragma mark FBGetUserNameDelegate methods

-(void)fbGetUserName:(FBGetUserName*)gun username:(NSString*)username
{
	[_getUserName release]; _getUserName = nil;
	[self setUserName:username];
}

-(void)fbGetUserName:(FBGetUserName*)gun didFailWithError:(NSError*)error
{
	NSLog(@"fbGetUserName error: %@", error);
	[_getUserName release]; _getUserName = nil;
	[self setUserName:nil];
}

@end

@interface TwitterLoginTableCell : BaseLoginTableCell
{
}

-(void)session_login:(NSNotification*)notification;
-(void)session_logout:(NSNotification*)notification;

@end


@implementation TwitterLoginTableCell

-(BaseLoginButton*)makeLoginButton
{
	TwitterLoginButton* b = [[[TwitterLoginButton alloc] initWithFrame:CGRectMake(0, 0, 176, 31)] autorelease];
	b.style = FBLoginButtonStyleNormal;
	return b;
}

-(id)initWithReuseIdentifier:(NSString *)reuseIdentifier
{
	if ( self = [super initWithReuseIdentifier:reuseIdentifier] )
	{		
		TWSession* s = [TWSession session];
		if ( [s isConnected] )
			[self setUserName:s.userName];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(session_login:) name:cTWSessionLoginNotification object:s];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(session_logout:) name:cTWSessionLogoutNotification object:s];
	}
	return self;
}	

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:nil object:[FBSession session]];
	[super dealloc];
}

#pragma mark TWSession Login/logout notifications

-(void)session_login:(NSNotification*)notification
{	
	[self setUserName:((TWSession*)[notification object]).userName];
}

-(void)session_logout:(NSNotification*)notification
{
	[self setUserName:nil];
}

@end

#pragma mark -

enum SettingsViewSection
{
	SettingsViewSection_PicturePostingService = 0,
	SettingsViewSection_FacebookLogin,
	SettingsViewSection_TwitterLogin,
	SettingsViewSection_MapServiceURL
};

@interface SettingsViewController ( PrivateMethods ) < TwitterOAuthLoginDelegate >

-(IBAction)done;
-(IBAction)cancel;
-(void)fbLoginTouchUpInside:(id)sender;
-(void)twLoginTouchUpInside:(id)sender;

@end

@implementation SettingsViewController

@synthesize delegate;

-(id)initWithSettingsViewControllerDelegate:(id<SettingsViewControllerDelegate>)d
{
	if ( self = [self initWithNibName:@"SettingsViewController" bundle:nil] )
	{
		self.delegate = d;
		m_selectedPicturePostingServiceIndex = 0;
		_tol = nil;
	}
	return self;
}

- (void)dealloc
{
	[m_postingServiceTitles release];
	[m_postingServiceValues release];
	[m_postingServiceDefaultValue release];
	[m_postingServiceValue release];
	[_tol release];
	self.delegate = nil;
    [super dealloc];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)];
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)];
	
	NSString* plistPath = [[NSBundle mainBundle] pathForResource:@"settings" ofType:@"plist"];
	
	NSDictionary* settings = [NSDictionary dictionaryWithContentsOfFile:plistPath];
	NSArray* preferenceSpecifiers = (NSArray*)[settings objectForKey:@"PreferenceSpecifiers"];
	NSDictionary* postingServiceSettings = (NSDictionary*)[preferenceSpecifiers objectAtIndex:1];
	m_postingServiceTitles = (NSArray*)[[postingServiceSettings objectForKey:@"Titles"] retain];
	m_postingServiceValues = (NSArray*)[[postingServiceSettings objectForKey:@"Values"] retain];
	m_postingServiceDefaultValue = (NSString*)[[postingServiceSettings objectForKey:@"DefaultValue"] retain];
	
	m_postingServiceValue = [[[NSUserDefaults standardUserDefaults] stringForKey:@"service"] retain];
	if ( m_postingServiceValue == nil )
	{
		m_postingServiceValue = [[m_postingServiceValue copy] retain]; // ???
			//[[NSUserDefaults standardUserDefaults] setObject:m_postingServiceValue forKey:@"service"];
	}

	m_selectedPicturePostingServiceIndex = [m_postingServiceValues indexOfObject:m_postingServiceValue];
	if ( NSNotFound == m_selectedPicturePostingServiceIndex )
	{
		self.navigationItem.leftBarButtonItem.enabled = NO;
	}

	NSDictionary* mapServiceSettings = (NSDictionary*)[preferenceSpecifiers objectAtIndex:6];
	NSString* mapServiceDefaultValue = (NSString*)[mapServiceSettings objectForKey:@"DefaultValue"];
	
	NSString* mapServiceURL =[[NSUserDefaults standardUserDefaults] stringForKey:@"mappictureservice"];
	if ( mapServiceURL == nil )
		mapServiceURL = mapServiceDefaultValue;
	
	m_mapServiceURLField.text = mapServiceURL;
}

-(void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	[self.navigationController setNavigationBarHidden:NO];
	[self.navigationController setToolbarHidden:YES];
}

-(void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
}

-(void)viewWillDisappear:(BOOL)animated
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardDidShowNotification object:nil];
	
	[super viewWillDisappear:animated];
}

-(IBAction)done
{
	[[NSUserDefaults standardUserDefaults] setObject:[m_postingServiceValues objectAtIndex:m_selectedPicturePostingServiceIndex] forKey:@"service"];
	[[NSUserDefaults standardUserDefaults] setObject:m_mapServiceURLField.text forKey:@"mappictureservice"];
	[delegate settingsViewControllerDidFinish:self with:NO];
}

-(IBAction)cancel
{
	[delegate settingsViewControllerDidFinish:self with:YES];
}

-(void)fbLoginTouchUpInside:(id)sender
{
	FBSession* s = [FBSession session];
	if (s.isConnected)
	{
		[s logout];
	}
	else
	{
		FBLoginViewController* loginWebDialog = [[FBLoginViewController alloc] initWithDelegate:self session:s];
		[self.navigationController pushViewController:loginWebDialog animated:YES];
			//[loginWebDialog release];
	}
}

-(void)twLoginTouchUpInside:(id)sender
{
	TWSession* s = [TWSession session];
	if (s.isConnected)
	{
		[s logout];
	}
	else
	{
		if ( _tol == nil )
		{
			_tol = [[TwitterOAuthLogin alloc] initWithTwitterOAuthLoginDelegate:self];
			[_tol start];
		}
	}
}


#pragma mark RCWebDialogViewControllerDelegate methods
- (void)webDialogViewController:(RCWebDialogViewController*)wdvc didSucceed:(BOOL)succeeded info:(id)info
{
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)webDialogViewController:(RCWebDialogViewController*)wdvc didFailWithError:(NSError*)error
{
	[self.navigationController popViewControllerAnimated:YES];
}


- (void)keyboardWillShow:(NSNotification *)notification {
    
    /*
     Reduce the size of the text view so that it's not obscured by the keyboard.
     Animate the resize so that it's in sync with the appearance of the keyboard.
     */
    NSDictionary *userInfo = [notification userInfo];
    
		// Get the origin of the keyboard when it's displayed.
    NSValue* aValue = [userInfo objectForKey:UIKeyboardBoundsUserInfoKey];
	
		// Get the top of the keyboard as the y coordinate of its origin in self's view's coordinate system. The bottom of the text view's frame should align with the top of the keyboard's final position.
    CGRect keyboardBounds = [aValue CGRectValue];
    
    CGRect newTableViewFrame = self.view.bounds;
    newTableViewFrame.size.height -= keyboardBounds.size.height;
    
		// Get the duration of the animation.
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
		// Animate the resize of the text view's frame in sync with the keyboard's appearance.
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    m_tableView.frame = newTableViewFrame;
	
    [UIView commitAnimations];
}


- (void)keyboardWillHide:(NSNotification *)notification {
    
    NSDictionary* userInfo = [notification userInfo];
    
    NSValue *animationDurationValue = [userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval animationDuration;
    [animationDurationValue getValue:&animationDuration];
    
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:animationDuration];
    
    m_tableView.frame = self.view.bounds;
    
    [UIView commitAnimations];
}

- (void)keyboardDidShow:(NSNotification *)notification
{
	CGRect u = m_mapServiceURLCell.frame;
	u.size.height *= 2;
	u.size.height += 1;
	
	[m_tableView scrollRectToVisible:u animated:NO];
}

#pragma mark textfield delegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder];
	return NO;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSInteger rows = 0;
	switch (section) {
		case SettingsViewSection_PicturePostingService:
			rows = m_postingServiceTitles.count;
			break;
			
		case SettingsViewSection_FacebookLogin:
		case SettingsViewSection_TwitterLogin:
		case SettingsViewSection_MapServiceURL:
			rows = 1;
			break;
			
		default:
			break;
	}
    return rows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	CGFloat h = 0;
	switch (indexPath.section)
	{
		case SettingsViewSection_FacebookLogin:
		case SettingsViewSection_TwitterLogin:
			h = 74;
			break;
		default:
			h = 44;
			break;
	}
	return h;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;

	switch (indexPath.section) {
		case SettingsViewSection_PicturePostingService:
			{
				static NSString *CellIdentifier = @"PicturePostingService_CellIdentifier";
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
				if (cell == nil)
					cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
				cell.accessoryType = (m_selectedPicturePostingServiceIndex == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
				cell.textLabel.text = [m_postingServiceTitles objectAtIndex:indexPath.row];
			}
			break;
			
		case SettingsViewSection_FacebookLogin:
			{
				static NSString *CellIdentifier = @"FacebookLogin_CellIdentifier";
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
				if (cell == nil)
				{
					FacebookLoginTableCell* fbCell = [[[FacebookLoginTableCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
					[fbCell.loginButton addTarget:self action:@selector(fbLoginTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
					cell = fbCell;
				}
			}
			break;
			
		case SettingsViewSection_TwitterLogin:
			{
				static NSString *CellIdentifier = @"TwitterLogin_CellIdentifier";
				cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
				if (cell == nil)
				{
					TwitterLoginTableCell* twCell = [[[TwitterLoginTableCell alloc] initWithReuseIdentifier:CellIdentifier] autorelease];
					[twCell.loginButton addTarget:self action:@selector(twLoginTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
					cell = twCell;
				}
			}
			break;			
			
		case SettingsViewSection_MapServiceURL:
			cell = m_mapServiceURLCell;
			cell.selectionStyle = UITableViewCellSelectionStyleNone;
			break;
			
		default:
			break;
	}
	
    return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	return ( indexPath.section == SettingsViewSection_PicturePostingService ) ? indexPath : nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	switch (indexPath.section) {
		case SettingsViewSection_PicturePostingService:
			{
				NSIndexPath* oldIndexPath = [NSIndexPath indexPathForRow:m_selectedPicturePostingServiceIndex inSection:SettingsViewSection_PicturePostingService];
				
				if ( oldIndexPath != nil )
					[[tableView cellForRowAtIndexPath:oldIndexPath] setAccessoryType:UITableViewCellAccessoryNone];
				[[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
				
				[tableView deselectRowAtIndexPath:indexPath animated:YES];
				m_selectedPicturePostingServiceIndex = indexPath.row;
				if ( m_selectedPicturePostingServiceIndex < m_postingServiceValues.count )
				{
					self.navigationItem.leftBarButtonItem.enabled = YES;
				}
			}
			break;
			
		default:
			break;
	}
}


- (NSString*)tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
	NSString* sectionHeader = nil;
	switch (section) {
		case SettingsViewSection_PicturePostingService:
			sectionHeader = NSLocalizedString(@"picturepostingserviceheader", @"Picture Posting Service");
			break;
			
		case SettingsViewSection_FacebookLogin:
			sectionHeader = NSLocalizedString(@"facebookheader", @"Facebook Account");
			break;
			
		case SettingsViewSection_TwitterLogin:
			sectionHeader = NSLocalizedString(@"twitterheader", @"Twitter Account");
			break;
			
		case SettingsViewSection_MapServiceURL:
			sectionHeader = NSLocalizedString(@"mapserviceheader", @"Map Service");
			break;
			
		default:
			break;
	}
	return sectionHeader;
}

#pragma mark TwitterOAuthLoginDelegate methods

-(TWSession*)session { return [TWSession session];}
								  								  
-(BOOL)pushControllerAnimated { return YES; }
								  
-(void)twitterOAuthLogin:(TwitterOAuthLogin*)twitterOAuthLogin didLogin:(BOOL)ok
{
	if ( twitterOAuthLogin == _tol )
	{
		[_tol release]; _tol = nil;
	}
	else 
		[twitterOAuthLogin release];
}

-(void)twitterOAuthLogin:(TwitterOAuthLogin*)twitterOAuthLogin didFailWithError:(NSError*)error
{
	if ( twitterOAuthLogin == _tol )
	{
		[_tol release]; _tol = nil;
	}
	else 
		[twitterOAuthLogin release];
}
								  
@end

