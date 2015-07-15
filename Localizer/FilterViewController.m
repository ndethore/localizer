//
//  FilterViewController.m
//  Localizer
//
//  Created by Nicolas on 7/12/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import "FilterViewController.h"

@interface FilterViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet NSTableView *tableView;
@property (assign) IBOutlet NSTextField *selectedItems;

@end

@implementation FilterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - <NSTableViewDelegate>

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [self.dataSource count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)rowIndex {
	
	NSString *text = [self.dataSource.allKeys objectAtIndex:rowIndex];
	
	return text;
}

#pragma mark - Action

- (IBAction)nextButtonSelected:(id)sender {
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(didFinishFiltering:)]) {
		[self.delegate didFinishFiltering:self.dataSource];
	}
	[self dismissController:self];
}

- (IBAction)cancelButtonSelected:(id)sender {
	if (self.delegate && [self.delegate respondsToSelector:@selector(didCancelFiltering)]) {
		[self.delegate didCancelFiltering];
	}
	[self dismissController:self];
}

- (IBAction)removeButtonSelected:(id)sender {
	
	NSIndexSet *selectedRows = [self.tableView selectedRowIndexes];

	NSArray *keys = [self.dataSource.allKeys objectsAtIndexes:selectedRows];
	[self.dataSource removeObjectsForKeys:keys];
	
	[self.tableView reloadData];
}


@end
