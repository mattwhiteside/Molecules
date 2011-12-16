//
//  MattsMoleculesAppDelegate.m
//  MattsMolecules
//
//  Created by Matt Whiteside on 11/2/08.
//  Copyright nanoMaterials Discovery Corp 2008. All rights reserved.
//

#import "MattsMoleculesAppDelegate.h"
#import "EAGLView.h"

@implementation MattsMoleculesAppDelegate

@synthesize window;
@synthesize glView;

- (void)applicationDidFinishLaunching:(UIApplication *)application {
    
	glView.animationInterval = 1.0 / 60.0;
	[glView startAnimation];
}


- (void)applicationWillResignActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 5.0;
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
	glView.animationInterval = 1.0 / 60.0;
}


- (void)dealloc {
	[window release];
	[glView release];
	[super dealloc];
}

@end
