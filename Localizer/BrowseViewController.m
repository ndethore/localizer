//
//  BrowseViewController.m
//  Localizer
//
//  Created by Nicolas on 7/9/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import "BrowseViewController.h"
#import "ProjectScanner.h"

@interface BrowseViewController () <ProjectScannerDelegate>

@property (nonatomic, strong) ProjectScanner *scanner;
@property (nonatomic, strong) NSMutableArray *results;

@property (assign) IBOutlet NSTextField         *pathTextField;
@property (assign) IBOutlet NSButton            *browseButton;
@property (assign) IBOutlet NSButton            *searchButton;
@property (assign) IBOutlet NSProgressIndicator *processIndicator;

- (IBAction)browseButtonSelected:(id)sender;
- (IBAction)searchButtonSelected:(id)sender;

@end

@implementation BrowseViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	_results = [[NSMutableArray alloc] init];
	self.scanner = [[ProjectScanner alloc] init];
	[self.scanner setDelegate:self];
}

- (IBAction)browseButtonSelected:(id)sender {
	// Show an open panel
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	
	BOOL okButtonPressed = ([openPanel runModal] == NSModalResponseOK);
	if (okButtonPressed) {
		// Update the path text field
		NSString *path = [[openPanel directoryURL] path];
		[self.pathTextField setStringValue:path];
	}
	
	
}

- (IBAction)searchButtonSelected:(NSButton *)sender {

	NSString *projectPath = [self.pathTextField stringValue];
	
	// Check if user has selected or entered a path
	BOOL isPathEmpty = [projectPath isEqualToString:@""];
	if (isPathEmpty) {
		[self showAlertWithStyle:NSWarningAlertStyle title:NSLocalizedString(@"MissingPathErrorTitle", @"") subtitle:NSLocalizedString(@"ProjectFolderPathErrorMessage", @"")];
		
		return;
	}

	// Check the path exists
	BOOL pathExists = [[NSFileManager defaultManager] fileExistsAtPath:projectPath];
	if (!pathExists) {
		[self showAlertWithStyle:NSWarningAlertStyle title:NSLocalizedString(@"InvalidPathErrorTitle", @"") subtitle:NSLocalizedString(@"ProjectFolderPathErrorMessage", @"")];
		
		return;
	}

	[self scanPath];
}

#pragma mark - Helpers

- (void)showAlertWithStyle:(NSAlertStyle)style title:(NSString *)title subtitle:(NSString *)subtitle {
	NSAlert *alert = [[NSAlert alloc] init];
	alert.alertStyle = style;
	[alert setMessageText:title];
	[alert setInformativeText:subtitle];
	[alert runModal];
}

- (void)setUIEnabled:(BOOL)state {
	// Individual
	if (state) {
		[_searchButton setTitle:NSLocalizedString(@"Search", @"")];
		[_searchButton setKeyEquivalent:@"\r"];
		[_processIndicator stopAnimation:self];
	} else {
		[self.searchButton setKeyEquivalent:@""];
		[_processIndicator startAnimation:self];
	}
	
	[_searchButton setEnabled:state];
	[_processIndicator setHidden:state];
	[_browseButton setEnabled:state];
	[_pathTextField setEnabled:state];
}

#pragma mark - Search

- (void)scanPath {
	
	self.scanner.projectPath = [self.pathTextField stringValue];
	
	[self.scanner start];
}

#pragma mark - ProjectScannerDelegate

- (void)scannerDidStartScanning:(ProjectScanner *)scanner {
	[self setUIEnabled:NO];
}

- (void)scanner:(ProjectScanner *)scanner didFindStringToLocalize:(NSString *)string {
	NSLog(@"Found %@", string);
	
}

- (void)scanner:(ProjectScanner *)scanner didFinishScanning:(NSArray *)results {
	
	NSLog(@"%ld strings found", results.count);
	[self setUIEnabled:YES];
}


@end
