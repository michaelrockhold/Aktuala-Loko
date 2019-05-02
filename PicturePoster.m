//
//  PicturePoster.m
//  Here-I-Am
//
//  Created by Michael Rockhold on 3/19/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import "PicturePoster.h"

@implementation PicturePoster

+(NSString*)generateBoundaryString
{
    CFUUIDRef       uuid;
    CFStringRef     uuidStr;
    NSString *      result;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSString stringWithFormat:@"Boundary-%@", uuidStr];
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

-(id)initWithOwner:(id<PicturePosterOwner>)owner
{
	if ( self = [self init] )
	{
		m_owner = [owner retain];
	}
	return self;
}

-(id<PicturePosterOwner>)owner
{
	return m_owner;
}

-(void)dealloc
{
	[m_owner release];
	[super dealloc];
}

-(void)start
{
	NSLog(@"unimplemented abstract superclass method");
}

@end
