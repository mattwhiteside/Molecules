//
//  SLSMoleculeDownloadViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/2/2008.
//
//  This controller manages the pop-up modal view for downloading new molecules from the Protein Data Bank

#import "SLSMoleculeDownloadViewController.h"


@implementation SLSMoleculeDownloadViewController

- (id)initWithPDBCode:(NSString *)pdbCode andTitle:(NSString *)title;
{
	if (self = [super initWithNibName:@"SLSMoleculeDownloadView" bundle:nil]) 
	{
		// Initialization code
		downloadedFileContents = nil;
		downloadCancelled = NO;
		
		codeForCurrentlyDownloadingProtein = [pdbCode copy];
		titleForCurrentlyDownloadingProtein = [title copy];
		self.title = codeForCurrentlyDownloadingProtein;
				
	}
	return self;
}


- (void)dealloc;
{
	[self cancelDownload];
	[codeForCurrentlyDownloadingProtein release];
	[titleForCurrentlyDownloadingProtein release];
	[pdbDownloadButton release];
	[super dealloc];

}
/*
 Implement loadView if you want to create a view hierarchy programmatically
- (void)loadView {
}
 */

- (void)viewDidLoad 
{
	[self.view addSubview:pdbDownloadDisplayView];
	[indefiniteDownloadIndicator stopAnimating];
	indefiniteDownloadIndicator.hidden = YES;
		
	[pdbDownloadDisplayView setBackgroundColor:[UIColor groupTableViewBackgroundColor]];
	
	moleculeTitleText.text = titleForCurrentlyDownloadingProtein;
	
	// Set up the green download button
	pdbDownloadButton = [[UIButton alloc] initWithFrame:CGRectMake(36, 212, 247, 37)];
	
	pdbDownloadButton.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
	pdbDownloadButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
	
	[pdbDownloadButton setTitle:@"Download molecule" forState:UIControlStateNormal];	
	[pdbDownloadButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[pdbDownloadButton setFont:[UIFont boldSystemFontOfSize:14.0]];
	
	UIImage *newImage = [[UIImage imageNamed:@"greenButton.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	[pdbDownloadButton setBackgroundImage:newImage forState:UIControlStateNormal];
		
	[pdbDownloadButton addTarget:self action:@selector(downloadNewProtein) forControlEvents:UIControlEventTouchDown];
	
    // in case the parent view draws with a custom color or gradient, use a transparent color
	pdbDownloadButton.backgroundColor = [UIColor clearColor];
	[pdbDownloadDisplayView addSubview:pdbDownloadButton];
	
//	pdbInformationWebView. = codeForCurrentlyDownloadingProtein;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}

#pragma mark -
#pragma mark View control methods

- (IBAction)showWebPageForMolecule;
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:self.view cache:YES];
	
	[pdbDownloadDisplayView removeFromSuperview];
	[self.view addSubview:pdbInformationWebView];
	pdbCodeSearchWebView.delegate = self;
	
	UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStylePlain target:self action:@selector(returnToDetailView)];
	self.navigationItem.rightBarButtonItem = cancelButtonItem;
	[cancelButtonItem release];
	
	[UIView commitAnimations];
	
	// Only send the user to the Protein Data Bank page if it hasn't already been loaded
	if ([pdbCodeSearchWebView request] == nil)
	{
		NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.rcsb.org/pdb/explore/explore.do?structureId=%@", codeForCurrentlyDownloadingProtein]]
												  cachePolicy:NSURLRequestUseProtocolCachePolicy
											  timeoutInterval:60.0];
		[pdbCodeSearchWebView loadRequest:theRequest];
	}
}

- (IBAction)returnToDetailView;
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1];
	[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:self.view cache:YES];
	
	self.navigationItem.rightBarButtonItem = nil;
	
	[pdbInformationWebView removeFromSuperview];
	[self.view addSubview:pdbDownloadDisplayView];
	
	[UIView commitAnimations];
}

- (IBAction)cancelDownload;
{
	downloadCancelled = YES;
	
	UIImage *newImage = [[UIImage imageNamed:@"greenButton.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	[pdbDownloadButton setBackgroundImage:newImage forState:UIControlStateNormal];
	[pdbDownloadButton removeTarget:self action:@selector(cancelDownload) forControlEvents:UIControlEventTouchDown];	
	[pdbDownloadButton addTarget:self action:@selector(downloadNewProtein) forControlEvents:UIControlEventTouchDown];
	[pdbDownloadButton setTitle:@"Download molecule" forState:UIControlStateNormal];	
	
	//[self.delegate moleculeDownloadController:self didAddMolecule:nil withCode:nil];
}

#pragma mark -
#pragma mark Protein downloading

- (IBAction)downloadNewProtein;
{
	// Check if you already have a protein by that name
	// TODO: Put this check in the init method to grey out download button
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
		
	if ([[NSFileManager defaultManager] fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.pdb.gz", codeForCurrentlyDownloadingProtein]]])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"File already exists" message:@"The molecule with this PDB code has already been downloaded"
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
		return;
	}
	
	if (![self downloadPDBFile])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection failed" message:@"Could not connect to the Protein Data Bank"
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];
		return;
	}
}

- (BOOL)downloadPDBFile;
{
	// Switch the mode of the download button to cancel
	UIImage *newImage = [[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:12.0 topCapHeight:0.0];
	[pdbDownloadButton setBackgroundImage:newImage forState:UIControlStateNormal];
	[pdbDownloadButton removeTarget:self action:@selector(downloadNewProtein) forControlEvents:UIControlEventTouchDown];	
	[pdbDownloadButton addTarget:self action:@selector(cancelDownload) forControlEvents:UIControlEventTouchDown];
	[pdbDownloadButton setTitle:@"Cancel download" forState:UIControlStateNormal];	
	
	downloadStatusBar.progress = 0.0;
	[self enableControls:NO];
	[indefiniteDownloadIndicator startAnimating];
	downloadStatusText.hidden = NO;
	downloadStatusText.text = @"Connecting...";
		
//	NSString *locationOfRemotePDBFile = [NSString stringWithFormat:@"http://www.sunsetlakesoftware.com/sites/default/files/%@.pdb.gz", pdbCode];
	NSString *locationOfRemotePDBFile = [NSString stringWithFormat:@"http://www.rcsb.org/pdb/files/%@.pdb.gz", codeForCurrentlyDownloadingProtein];

	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:locationOfRemotePDBFile]
											  cachePolicy:NSURLRequestUseProtocolCachePolicy
										  timeoutInterval:60.0];
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (theConnection) 
	{
		// Create the NSMutableData that will hold
		// the received data
		// receivedData is declared as a method instance elsewhere
		downloadedFileContents = [[NSMutableData data] retain];
	} 
	else 
	{
		// inform the user that the download could not be made
		return NO;
	}
	return YES;
}

- (void)enableControls:(BOOL)controlsAreEnabled;
{
	pdbInformationDisplayButton.enabled = controlsAreEnabled;
//	pdbDownloadButton.enabled = controlsAreEnabled;	
}

- (void)downloadCompleted;
{
	[downloadedFileContents release];
	downloadedFileContents = nil;
	downloadStatusBar.hidden = YES;
	[indefiniteDownloadIndicator stopAnimating];
	downloadStatusText.hidden = YES;

	[self enableControls:YES];
}



#pragma mark -
#pragma mark URL connection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Connection failed" message:@"Could not connect to the Protein Data Bank"
												   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
	[alert show];
	[alert release];
	
	[self downloadCompleted];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	// Concatenate the new data with the existing data to build up the downloaded file
	// Update the status of the download
	
	if (downloadCancelled)
	{
		[connection cancel];
		[self downloadCompleted];
		downloadCancelled = NO;
		return;
	}
	[downloadedFileContents appendData:data];
	downloadStatusBar.progress = (double)[downloadedFileContents length] / (double)downloadFileSize;
	downloadStatusText.text = @"Downloading...";
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	downloadFileSize = [response expectedContentLength];

	// Stop the spinning wheel and start the status bar for download
	if ([response textEncodingName] != nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Could not find file" message:[NSString stringWithFormat:@"No protein with the code %@ exists in the data bank", codeForCurrentlyDownloadingProtein]
													   delegate:self cancelButtonTitle:@"OK" otherButtonTitles: nil];
		[alert show];
		[alert release];		
		[connection cancel];
		[self downloadCompleted];
		return;
	}
	
	if (downloadFileSize > 0)
	{
		downloadStatusBar.hidden = NO;
		[indefiniteDownloadIndicator stopAnimating];
	}
	downloadStatusText.text = @"Connected";

	// TODO: Deal with a 404 error by checking filetype header
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	downloadStatusText.text = @"Processing...";

	// Close off the file and write it to disk
	[self.delegate moleculeDownloadController:self didAddMolecule:downloadedFileContents withFilename:[NSString stringWithFormat:@"%@.pdb.gz", codeForCurrentlyDownloadingProtein]];

	[self downloadCompleted];	
}

#pragma mark -
#pragma mark Webview delegate methods

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	webLoadingLabel.hidden = NO;
	[webLoadingIndicator startAnimating];
	//	progView.hidden = NO;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	webLoadingLabel.hidden = YES;
	[webLoadingIndicator stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// TODO: Present error dialog to user explaining what's going on
	[webLoadingIndicator stopAnimating];
}

#pragma mark -
#pragma mark Accessors

@synthesize delegate;


@end
