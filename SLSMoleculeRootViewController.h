//
//  SLSMoleculeRootViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages a root view into which the 3D view and the molecule table selection views and animated for the neat flipping effect

#import <UIKit/UIKit.h>
#import <sqlite3.h>

@class SLSMoleculeGLViewController;
@class SLSMolecule;

@interface SLSMoleculeRootViewController : UIViewController
{
	SLSMoleculeGLViewController *glViewController;
	IBOutlet UINavigationController *tableNavigationController;
	IBOutlet UIToolbar *moleculeDownloadToolbar;
	SLSMolecule *bufferedMolecule, *previousMolecule;
	NSMutableArray *molecules;
	
	IBOutlet UIActivityIndicatorView *scanningActivityIndicator;
	IBOutlet UIProgressView *renderingProgressIndicator;
	IBOutlet UILabel *renderingActivityLabel;
	BOOL toggleViewDisabled;
	
	sqlite3 *database;
}

@property (nonatomic, retain) SLSMoleculeGLViewController *glViewController;
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, retain) NSMutableArray *molecules;

// Interface updates
- (void)showScanningIndicator:(NSNotification *)note;
- (void)updateScanningIndicator:(NSNotification *)note;
- (void)hideScanningIndicator:(NSNotification *)note;
- (void)showRenderingIndicator:(NSNotification *)note;
- (void)updateRenderingIndicator:(NSNotification *)note;
- (void)hideRenderingIndicator:(NSNotification *)note;
- (void)toggleView;

// Passthroughs for managing molecules
- (void)loadInitialMolecule;
- (void)selectedMoleculeDidChange:(NSInteger)newMoleculeIndex;

@end

