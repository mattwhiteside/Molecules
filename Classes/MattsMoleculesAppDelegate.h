//
//  MattsMoleculesAppDelegate.h
//  MattsMolecules
//
//  Created by Matt Whiteside on 11/2/08.
//  Copyright nanoMaterials Discovery Corp 2008. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface MattsMoleculesAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

