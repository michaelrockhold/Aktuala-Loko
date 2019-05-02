//
//  CrosshairsView.m
//  LiveTransit-Seattle
//
//  Created by Michael Rockhold on 8/17/09.
//  Copyright 2009 The Rockhold Company. All rights reserved.
//

#import "CrosshairsView.h"

@implementation CrosshairsView

- (void)drawRect:(CGRect)rect
{
	CGRect f = rect; //self.frame;
	float circleDiameter = f.size.width * 0.3;
	CGRect circleRect = CGRectMake(f.origin.x + f.size.width/2 - circleDiameter/2, f.origin.y + f.size.height/2 - circleDiameter/2, circleDiameter, circleDiameter);	
	
	CGContextRef myContext = UIGraphicsGetCurrentContext();
	CGContextSaveGState(myContext);
	CGContextClearRect(myContext, rect);
	
	CGContextAddEllipseInRect(myContext, circleRect);
	
	CGPoint point[2];
	//North
	point[0] = CGPointMake(circleRect.origin.x + circleRect.size.width/2,	circleRect.origin.y-8);
	point[1] = CGPointMake(point[0].x,										point[0].y+circleDiameter/2);
	CGContextAddLines (myContext, point, 2);
	
	//South
	point[0] = CGPointMake(point[0].x,										circleRect.origin.y+circleDiameter+8);
	point[1] = CGPointMake(point[0].x,										point[0].y-circleDiameter/2);
	CGContextAddLines (myContext, point, 2);
	
	//West
	point[0] = CGPointMake(circleRect.origin.x-8,				circleRect.origin.y + circleDiameter/2);
	point[1] = CGPointMake(point[0].x+circleDiameter/2,			point[0].y);
	CGContextAddLines (myContext, point, 2);
	
	//East
	point[0] = CGPointMake(circleRect.origin.x+circleDiameter/2+8, point[0].y);
	point[1] = CGPointMake(point[0].x+circleDiameter/2,			 point[0].y);
	CGContextAddLines (myContext, point, 2);

	CGContextSetLineWidth(myContext, 3);
	CGContextSetGrayStrokeColor(myContext, 0, 0.2);
	CGContextDrawPath(myContext, kCGPathStroke);
	CGContextRestoreGState(myContext);
}

@end
