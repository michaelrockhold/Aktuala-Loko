//
//  PicturePoster.h
//  Here-I-Am
//
//  Created by Michael Rockhold on 3/19/10.
//  Copyright 2010 The Rockhold Company. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@protocol PicturePostInfo < NSObject >

@property (nonatomic, readonly, retain) NSData* pictureData;
@property (nonatomic, readonly, retain) NSString* filename;
@property (nonatomic, readonly, retain) NSString* contentType;

@end

@protocol PicturePosterOwner;

@interface PicturePoster : NSObject
{
	id<PicturePosterOwner> m_owner;
}

+(NSString*)generateBoundaryString;

@property (nonatomic, retain, readonly) id<PicturePosterOwner> owner;

-(id)initWithOwner:(id<PicturePosterOwner>)owner;
-(void)start;

@end

@protocol PicturePosterOwner < NSObject >

-(void)picturePoster:(PicturePoster*)pp sendDidFail:(NSError*)error;
-(void)picturePoster:(PicturePoster*)pp sendDidEnd:(NSString*)mediaURL;

-(id<PicturePostInfo>)picturePostInfo;
-(NSArray*)picturePostInfoArray;

-(NSString*)comment;
-(CLLocationCoordinate2D)currentCoordinate;
-(UINavigationController*)navigationController;

@end
