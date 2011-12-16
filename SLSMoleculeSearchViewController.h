//
//  SLSMoleculeSearchViewController.h
//  Molecules
//
//  Created by Brad Larson on 7/22/2008.
//  Copyright 2008 SonoPlot, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLSMoleculeTableViewController.h"
#import "SLSMoleculeDownloadViewController.h"

@interface SLSMoleculeSearchViewController : UITableViewController <MoleculeDownloadDelegate, UISearchBarDelegate>
{
	id<MoleculeDownloadDelegate> delegate;
	NSMutableArray *searchResultPDBCodes, *searchResultTitles;
	NSMutableDictionary *dictionaryToAssociatePDBCodesAndTitles;
	NSMutableData *downloadedFileContents;
	NSXMLParser *searchResultsParser;
	NSMutableString *currentXMLElementString;
	NSURLConnection *pdbCodeRetrievalConnection, *titleRetrievalConnection;
	BOOL searchCancelled;
}

@property (readwrite, assign) id<MoleculeDownloadDelegate> delegate;

- (void)processSearchResults;
- (BOOL)finishParsingXML;
- (void)finishLoadingTitles;

@end
