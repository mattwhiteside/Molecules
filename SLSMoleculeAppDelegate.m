//
//  SLSMoleculesAppDelegate.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 5/18/2008.
//
//  This is the base application delegate, used for handling launch, termination, and memory-related delegate methods

#import "SLSMoleculeAppDelegate.h"
#import "SLSMoleculeRootViewController.h"
#import "SLSMolecule.h"

#import "VCTitleCase.h"

#define MOLECULES_DATABASE_VERSION 1

@implementation SLSMoleculeAppDelegate

@synthesize window;
@synthesize rootViewController;

#pragma mark -
#pragma mark Initialization / teardown

- (void)applicationDidFinishLaunching:(UIApplication *)application 
{	
	[self performSelectorInBackground:@selector(loadInitialMoleculesFromDisk) withObject:nil];
	
	[window addSubview:[rootViewController view]];
	[window makeKeyAndVisible];
}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	[self disconnectFromDatabase];
}

- (void)dealloc 
{
	[rootViewController release];
	[molecules release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Database access

- (BOOL)createEditableCopyOfDatabaseIfNeeded; 
{
    // See if the database already exists
    BOOL success;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"molecules.sql"];
    success = [fileManager fileExistsAtPath:writableDBPath];
    if (success) return NO;
	
    // The database does not exist, so copy a blank starter database to the Documents directory
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"molecules.sql"];
    success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
        NSAssert1(0, @"Failed to create writable database file with message '%@'.", [error localizedDescription]);
    }
	return YES;
}

- (void)connectToDatabase;
{
	molecules = [[NSMutableArray alloc] init];
	
	// The database is stored in the application bundle. 
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:@"molecules.sql"];
    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) 
	{
    } 
	else 
	{
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(database);
        NSAssert1(0, @"Failed to open database with message '%s'.", sqlite3_errmsg(database));
        // Additional error handling, as appropriate...
    }
	
}

- (void)disconnectFromDatabase;
{
// TODO: Maybe write out all database entries to disk
	//	[books makeObjectsPerformSelector:@selector(dehydrate)];
	[SLSMolecule finalizeStatements];
    // Close the database.
    if (sqlite3_close(database) != SQLITE_OK) 
	{
        NSAssert1(0, @"Error: failed to close database with message '%s'.", sqlite3_errmsg(database));
    }
}

- (void)loadInitialMoleculesFromDisk;
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	rootViewController.molecules = nil;

	
	if ([self createEditableCopyOfDatabaseIfNeeded])
	{
		// The database needed to be recreated, so scan and copy over the default files
		[self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];
		
		[self connectToDatabase];
		// Before anything else, move included PDB files to /Documents if the program hasn't been run before
		// User might have intentionally deleted files, so don't recopy the files in that case
		NSError *error = nil;
		// Grab the /Documents directory path
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		// Iterate through all files sitting in the application's Resources directory
		// TODO: Can you fast enumerate this?
		NSDirectoryEnumerator *direnum = [fileManager enumeratorAtPath:[[NSBundle mainBundle] resourcePath]];
		NSString *pname;
		while (pname = [direnum nextObject])
		{
			if ([[pname pathExtension] isEqualToString:@"gz"])
			{
				NSString *preloadedPDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:pname];
				NSString *installedPDBPath = [documentsDirectory stringByAppendingPathComponent:pname];
				if (![fileManager fileExistsAtPath:installedPDBPath])
				{
					// Move included PDB files to /Documents
					[[NSFileManager defaultManager]	copyItemAtPath:preloadedPDBPath toPath:installedPDBPath error:&error];
					if (error != nil)
					{
//						NSLog(@"Failed to copy over PDB files with error: '%@'.", [error localizedDescription]);
						// TODO: Report the file copying problem to the user or do something about it
					}
				}
				
			}
		}
		
		[self loadMissingMoleculesIntoDatabase];
		
		[[NSUserDefaults standardUserDefaults] synchronize];		
		[self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:NO];
	}
	else
	{
		// The MySQL database has been created, so load molecules from the database
		[self connectToDatabase];
		// TODO: Check to make sure that the proper version of the database is installed
		[self loadAllMoleculesFromDatabase];
		[self loadMissingMoleculesIntoDatabase];		
	}
	
	rootViewController.database = database;
	rootViewController.molecules = molecules;
	
	[rootViewController loadInitialMolecule];
	[pool release];
}

- (void)loadAllMoleculesFromDatabase;
{
	const char *sql = "SELECT * FROM molecules";
	sqlite3_stmt *moleculeLoadingStatement;

	if (sqlite3_prepare_v2(database, sql, -1, &moleculeLoadingStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(moleculeLoadingStatement) == SQLITE_ROW) 
		{
			SLSMolecule *newMolecule = [[SLSMolecule alloc] initWithSQLStatement:moleculeLoadingStatement database:database];
			if (newMolecule != nil)
				[molecules addObject:newMolecule];
				
			[newMolecule release];
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(moleculeLoadingStatement);	
}

- (void)loadMissingMoleculesIntoDatabase;
{
	// First, load all molecule names from the database
	NSMutableDictionary *moleculeFilenameLookupTable = [[NSMutableDictionary alloc] init];
	
	const char *sql = "SELECT * FROM molecules";
	sqlite3_stmt *moleculeLoadingStatement;
	
	if (sqlite3_prepare_v2(database, sql, -1, &moleculeLoadingStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(moleculeLoadingStatement) == SQLITE_ROW) 
		{
			char *stringResult = (char *)sqlite3_column_text(moleculeLoadingStatement, 1);
			NSString *sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
			NSString *filename = [sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"];
			[moleculeFilenameLookupTable setValue:[NSNumber numberWithBool:YES] forKey:filename];
		}
	}
	sqlite3_finalize(moleculeLoadingStatement);	
	
	// Now, check all the files on disk to see if any are missing from the database
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
	
	NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager]
									  enumeratorAtPath:documentsDirectory];
	NSString *pname;
	while (pname = [direnum nextObject])
	{
		if ( ([moleculeFilenameLookupTable valueForKey:pname] == nil) && ([[pname pathExtension] isEqualToString:@"gz"]) )
		{
			// Parse the PDB file into the database
			SLSMolecule *newMolecule = [[SLSMolecule alloc] initWithFilename:pname database:database];
			if (newMolecule != nil)
				[molecules addObject:newMolecule];
			[newMolecule release];			
		}
	}
	
	[moleculeFilenameLookupTable release];
}

#pragma mark -
#pragma mark Status update methods

- (void)showStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileLoadingStarted" object:nil];
}

- (void)updateStatusIndicator;
{
	
}

- (void)hideStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileLoadingEnded" object:nil];
}

#pragma mark -
#pragma mark Flow control

- (void)applicationWillResignActive:(UIApplication *)application 
{
}


- (void)applicationDidBecomeActive:(UIApplication *)application 
{
}

@end
