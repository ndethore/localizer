//
//  BrowseViewController.m
//  Localizer
//
//  Created by Nicolas on 7/9/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import "BrowseViewController.h"
#import "ProjectScanner.h"
#import "ProjectPatcher.h"
#import "FilterViewController.h"

@interface BrowseViewController () <ProjectScannerDelegate, ProjectPatcherDelegate, FilterViewControllerDelegate>

@property (nonatomic, strong) ProjectScanner      *scanner;
@property (nonatomic, strong) ProjectPatcher      *patcher;
@property (nonatomic, strong) NSDictionary        *fileIndex;
@property (nonatomic, strong) NSDictionary        *stringsIndex;
@property (nonatomic, strong) NSMutableDictionary *keysDictionary;

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
static NSString *const kTableColumnString      = @"String";
static NSString *const kTableColumnFile        = @"File";
static NSString *const kTableColumnKey         = @"Key";


@implementation BrowseViewController

- (void)viewDidLoad {
	
	[super viewDidLoad];
	[self initialize];
}

- (void)initialize {
	
	_keysDictionary = [[NSMutableDictionary alloc] init];
	self.scanner = [[ProjectScanner alloc] init];
	self.patcher = [[ProjectPatcher alloc] init];
	
	[self.scanner setDelegate:self];
	[self.patcher setDelegate:self];
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
		[self showAlertWithStyle:NSWarningAlertStyle
								 title:NSLocalizedString(@"MissingPathErrorTitle", @"")
							 subtitle:NSLocalizedString(@"ProjectFolderPathErrorMessage", @"")];
		
		return;
	}

	// Check the path exists
	BOOL pathExists = [[NSFileManager defaultManager] fileExistsAtPath:projectPath];
	if (!pathExists) {
		[self showAlertWithStyle:NSWarningAlertStyle
								 title:NSLocalizedString(@"InvalidPathErrorTitle", @"")
							 subtitle:NSLocalizedString(@"ProjectFolderPathErrorMessage", @"")];
		
		return;
	}

	[self scanPath];
}

- (IBAction)replaceButtonSelected:(id)sender {
	
	[self.patcher patchStrings:self.stringsIndex withKeys:self.keysDictionary];
	
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
	
	[self reset];
	[self.scanner start];
}

#pragma mark - ProjectScannerDelegate

- (void)scannerDidStartScanning:(ProjectScanner *)scanner {
	[self setUIEnabled:NO];
}

- (void)scanner:(ProjectScanner *)scanner didFindStringToLocalize:(NSString *)string {
	NSLog(@"Found %@", string);
	
}

- (void)scanner:(ProjectScanner *)scanner didFinishScanning:(NSDictionary *)results {
	
	self.fileIndex = results;
	self.stringsIndex = [self stringsIndexFromFileIndex:results];
	
	[self performSegueWithIdentifier:kFilterSegueIndentifier sender:self];
}

#pragma mark - ProjectScannerDelegate

- (void)patcherDidStartPatching:(ProjectPatcher *)patcher {
	NSLog(@"Patching started.");
}

- (void)patcher:(ProjectPatcher *)patcher didPatchString:(NSString *)string {
	
}

- (void)patcherDidFinishPatching:(ProjectPatcher *)patcher {
	NSLog(@"Patching completed.");
}

#pragma mark - FilterViewControllerDelegate

- (void)didCancelFiltering {
	

	[self updateUI];
	[self setUIEnabled:YES];
}

- (void)didFinishFiltering:(NSDictionary *)results {
	
	self.stringsIndex = results;

	[self updateUI];
	[self setUIEnabled:YES];
}

#pragma mark - <NSTableViewDelegate>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.keysDictionary.allKeys count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	
	NSString *text;
	
	if (self.stringsIndex.count > 0
		 && self.keysDictionary.count > 0) {

		NSString *columnIndentifier = [tableColumn identifier];
		if ([columnIndentifier isEqualToString:kTableColumnString]) text = [self.keysDictionary.allKeys objectAtIndex:rowIndex];
		else if ([columnIndentifier isEqualToString:kTableColumnKey]) text = [self.keysDictionary.allValues objectAtIndex:rowIndex];
		else if ([columnIndentifier isEqualToString:kTableColumnFile]) {
			
			
			NSArray *paths = [self.stringsIndex.allValues objectAtIndex:rowIndex];
			NSMutableString *pathsList = [[NSMutableString alloc] init];
			
			for (NSString *path in paths) {
				NSURL *url = [NSURL URLWithString:path];
				[pathsList appendFormat:@"%@;", [url lastPathComponent]];
			}
			
			text = pathsList;
		}
	}
	
	return text;
}


- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
	NSString *columnIndentifier = [aTableColumn identifier];
	
	if ([columnIndentifier isEqualToString:kTableColumnKey]) {
		NSString *string = [self.keysDictionary.allKeys objectAtIndex:rowIndex];
		[self.keysDictionary setObject:anObject forKey:string];
	}
}

#pragma mark - Navigation

- (void)prepareForSegue:(nonnull NSStoryboardSegue *)segue sender:(nullable id)sender {
	
	if ([segue.identifier isEqualToString:kFilterSegueIndentifier]) {
		
		FilterViewController *filterVC = [segue destinationController];
		[filterVC setDelegate:self];
		[filterVC setDataSource:[self.stringsIndex mutableCopy]];
	}
}

#pragma mark - Private

- (void)updateUI {

	[self updateKeyDictionary];
	[self.statusLabel setHidden:NO];
	[self.statusLabel setStringValue:[NSString stringWithFormat:@"%ld strings found.", self.stringsIndex.count]];
}

- (void)updateKeyDictionary {
	
	for (NSString *string in self.stringsIndex.allKeys) {
		
		if (![self.keysDictionary.allKeys containsObject:string]) {
			[self.keysDictionary setObject:@"" forKey:string];
		}
	}
	
	[self.tableView reloadData];
}

- (void)reset {
	
	[self.keysDictionary removeAllObjects];
	self.fileIndex = nil;
	self.stringsIndex = nil;
}

- (NSDictionary *)stringsIndexFromFileIndex:(NSDictionary *)fileIndex {
	
	NSMutableDictionary *index = [[NSMutableDictionary alloc] init];
	
	for (NSString *filePath in fileIndex.allKeys) {
		
		for (NSString *string in [fileIndex objectForKey:filePath]) {
			
			if (![index.allKeys containsObject:string]) {
				// "New" string, let's add it to the clean index along with file it belongs to.
				NSMutableArray *referenceFilePaths = [NSMutableArray arrayWithObject:filePath];
				[index setObject:referenceFilePaths forKey:string];
				
			}
			else {
				// Existing string, let's only add the file to which it belongs to.
				NSMutableArray *referenceFilePaths = [index objectForKey:string];
				if (![referenceFilePaths containsObject:filePath]) {
					[referenceFilePaths addObject:filePath];
				}
				[index setObject:referenceFilePaths forKey:string];
			}
		}
	}
	return index;
}


@end
