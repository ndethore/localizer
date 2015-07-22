
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
#import "NSString+Utility.h"

@interface BrowseViewController () <ProjectScannerDelegate, ProjectPatcherDelegate>

@property (nonatomic, strong) ProjectScanner      *scanner;
@property (nonatomic, strong) ProjectPatcher      *patcher;

@property (nonatomic, strong) NSMutableArray			*dataSource;
@property (nonatomic, strong) NSMutableDictionary	*fileIndex;
@property (nonatomic, strong) NSMutableDictionary	*stringsIndex;

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
	
	_dataSource = [[NSMutableArray alloc] init];
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

#pragma mark Search

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

#pragma mark Remove

- (IBAction)removeButtonSelected:(id)sender {
	
	NSIndexSet *selectedRows = [self.tableView selectedRowIndexes];
	
	// Remove the selected items from the file index
	NSArray *selectedEntries = [self.dataSource objectsAtIndexes:selectedRows];
	for (NSDictionary *entry in selectedEntries) {
		
		NSString *path = [entry objectForKey:kTableColumnFile];
		NSString *string = [entry objectForKey:kTableColumnString];
		
		NSMutableArray *strings = [self.fileIndex objectForKey:path];
		NSInteger index = [strings indexOfObjectIdenticalTo:string];
		[strings removeObjectAtIndex:index];
		NSLog(@"Removed \"%@\" from strings list for file: %@", string, path);
		
//		[self.stringsIndex removeObjectForKey:string];
	}
	
	// Remove the entries from the datasource
	[self.dataSource removeObjectsAtIndexes:selectedRows];
	
	[self.tableView deselectAll:self];
	[self.tableView reloadData];
}

#pragma mark Replace

- (IBAction)replaceButtonSelected:(id)sender {
	
	// Generate the key dictionary
	
	NSMutableDictionary *keyDictionary = [[NSMutableDictionary alloc] init];
	
	for (NSDictionary *entry in self.dataSource) {
		
		NSString *string = [entry objectForKey:kTableColumnString];
		NSString *key = [entry objectForKey:kTableColumnKey];
		
		[keyDictionary setValue:key forKey:string];
	}
	
	NSLog(@"Replacing with file index:%@", self.fileIndex);
	[self.patcher patchFiles:self.fileIndex withKeys:keyDictionary];
	
}

- (IBAction)generateStringsButtonSelected:(id)sender {
	[self createStringsFile];
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
	NSLog(@"File index:%@", self.fileIndex);
	
	self.stringsIndex = [self stringsIndexFromFileIndex:results];
	[self setupDataSourceWithFileIndex:results];
	
	[self updateUI];
	[self setUIEnabled:YES];
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

#pragma mark - <NSTableViewDelegate>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.dataSource count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	
	NSString *text;
	
	NSDictionary *entry = self.dataSource[rowIndex];
	NSString *columnIndentifier = [tableColumn identifier];
	
	if ([columnIndentifier isEqualToString:kTableColumnString]) text = [entry objectForKey:kTableColumnString];
	else if ([columnIndentifier isEqualToString:kTableColumnFile]) {
		
		NSURL *url = [NSURL URLWithString:[entry objectForKey:kTableColumnFile]];
		text = [url lastPathComponent];
	}
	else if ([columnIndentifier isEqualToString:kTableColumnKey]) text = [entry objectForKey:kTableColumnKey];
	
	return text;
}


- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	
	NSString *columnIndentifier = [aTableColumn identifier];
	
	if ([columnIndentifier isEqualToString:kTableColumnKey]) {
		
		NSMutableDictionary *entry = self.dataSource[rowIndex];
		[entry setObject:anObject forKey:kTableColumnKey];
		
	}
}

#pragma mark - Private

- (void)updateUI {
	
	[self.statusLabel setHidden:NO];
	[self.statusLabel setStringValue:[NSString stringWithFormat:@"%ld strings found.", self.dataSource.count]];

	[self.tableView reloadData];
}

- (void)reset {
	
	self.stringsIndex = nil;
	[self.dataSource removeAllObjects];
	
}

- (void)setupDataSourceWithFileIndex:(NSDictionary *)fileIndex {
	
	for (NSString *filePath in fileIndex.allKeys) {
		
		for (NSString *string in [fileIndex objectForKey:filePath]) {

			NSMutableDictionary *entry = [@{kTableColumnString:string,
													  kTableColumnFile:filePath,
													  kTableColumnKey:@""} mutableCopy];
			
			[self.dataSource addObject:entry];

			
		}
	}
	
}

- (NSMutableDictionary *)stringsIndexFromFileIndex:(NSDictionary *)fileIndex {
	
	NSMutableDictionary *index = [[NSMutableDictionary alloc] init];
	
	for (NSString *filePath in fileIndex.allKeys) {
		
		for (NSString *string in [fileIndex objectForKey:filePath]) {
			
			NSMutableArray *referenceFilePaths = [NSMutableArray arrayWithObject:filePath];
			[index setObject:referenceFilePaths forKey:string];
		}
	}
	return index;
}

// TODO: move following to a separate object

- (BOOL)createStringsFile {
	
	NSString *stringsFilePath = [NSString stringWithFormat:@"%@/Localizable.strings", [self.pathTextField stringValue]];
	NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:stringsFilePath];
	if (!handle) {
		[[NSFileManager defaultManager] createFileAtPath:stringsFilePath contents:nil attributes:nil];
		handle = [NSFileHandle fileHandleForWritingAtPath:stringsFilePath];
	}
	if (!handle) return NO;
	
	NSMutableString *content = [[NSMutableString alloc] init];
	for (NSDictionary *entry in self.dataSource) {
		
		NSString *string = [entry objectForKey:kTableColumnString];
		NSString *key = [entry objectForKey:kTableColumnKey];
		
		[content appendFormat:@"\"%@\" = \"%@\";\n", key, [string unwrappedContent]];
	}
	
	[handle seekToEndOfFile];
	[handle writeData:[content dataUsingEncoding:NSUTF8StringEncoding]];
	[handle closeFile];
	
	return YES;
}

@end
