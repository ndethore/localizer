//
//  BrowseViewController.m
//  Localizer
//
//  Created by Nicolas on 7/9/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import "BrowseViewController.h"
#import "ProjectScanner.h"
#import "FilterViewController.h"

@interface BrowseViewController () <ProjectScannerDelegate, FilterViewControllerDelegate>

@property (nonatomic, strong) ProjectScanner *scanner;
@property (nonatomic, strong) NSMutableArray *lines;
@property (nonatomic, strong) NSMutableArray *strings;

@property (assign) IBOutlet NSTextField         *pathTextField;
@property (assign) IBOutlet NSButton            *browseButton;
@property (assign) IBOutlet NSTableView			*tableView;
@property (assign) IBOutlet NSTextField			*statusLabel;
@property (assign) IBOutlet NSButton            *searchButton;
@property (assign) IBOutlet NSProgressIndicator *processIndicator;

- (IBAction)browseButtonSelected:(id)sender;
- (IBAction)searchButtonSelected:(id)sender;

@end

static NSString *const kFilterSegueIndentifier = @"showFilterViewController";
static NSString *const kTableColumnString = @"String";
static NSString *const kTableColumnKey = @"Key";


@implementation BrowseViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	_lines = [[NSMutableArray alloc] init];
	_strings = [[NSMutableArray alloc] init];
	self.scanner = [[ProjectScanner alloc] init];
	[self.scanner setDelegate:self];
}

#pragma mark - Actions

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
	self.lines = [results mutableCopy];
	[self setUIEnabled:YES];
	
	[self performSegueWithIdentifier:kFilterSegueIndentifier sender:self];
}

#pragma mark - FilterViewControllerDelegate

- (void)didCancelFiltering {
	NSLog(@"Did cancel filtering !");
	
	[self extractStrings];
}

- (void)didFinishFilteringWithArray:(NSArray*)array {
	NSLog(@"Did finish filtering !");
	
	self.lines = [array mutableCopy];
	[self extractStrings];
}

#pragma mark - <NSTableViewDelegate>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.strings count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	
	NSString *text;
	
	NSString *columnIndentifier = [tableColumn identifier];
	if ([columnIndentifier isEqualToString:kTableColumnString]) text = [self.strings objectAtIndex:rowIndex];
	
	return text;
}


#pragma mark - Navigation

- (void)prepareForSegue:(nonnull NSStoryboardSegue *)segue sender:(nullable id)sender {
	
	if ([segue.identifier isEqualToString:kFilterSegueIndentifier]) {
		
		FilterViewController *filterVC = [segue destinationController];
		[filterVC setDelegate:self];
		[filterVC setDataSource:self.lines];
	}
}

#pragma mark - Result Processing

- (void)extractStrings {
	
	for (NSString *line in self.lines) {
		
		NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\"[^\"]+\"" options:0 error:nil];
		NSArray *matches = [regex matchesInString:line options:0 range:NSMakeRange(0, line.length)];

		for (NSTextCheckingResult *result in matches) {
		
			NSString *string = [line substringWithRange:result.range];
			
			if (![self.strings containsObject:string]) {
				[self.strings addObject:string];
			}
		}
	}
	
	[self.statusLabel setHidden:NO];
	[self.statusLabel setStringValue:[NSString stringWithFormat:@"%ld strings found.", self.strings.count]];
	[self.tableView reloadData];
}

@end
