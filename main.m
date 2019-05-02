//
//  main.m
//  HereIAm
//
//  Created by Michael Rockhold on 1/17/10.
//  Copyright The Rockhold Company 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[])
{    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, nil);
    [pool release];
    return retVal;
}

/*
#if 0
 
To do: 
- preserve state on quit and restore to what was left off
- activate location mgr with explicit user tap on location reticle in toolbar; when to stop loc mgr?
- clear post-status indicator when image or comment changes
DONE- tag post with something other than #HereIAm (#=HereIAm=?)
DONE- don't display location activity spinner while typing in comment text box
 
+ V2 features:
- post to Flickr?
- post to Facebook?
- show location of friends if they are nearby?
- repeated periodic updates?
 - attach a photograph to the map image?

#endif
*/