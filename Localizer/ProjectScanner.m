//
//  ProjectScanner.m
//  Localizer
//
//  Created by Nicolas on 7/10/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import "ProjectScanner.h"

@interface ProjectScanner() {
	
	NSMutableDictionary *_results;

	NSOperationQueue *_queue;

}
@end

@implementation ProjectScanner

- (instancetype)init {
	if (self = [super init]) {
		
		// Setup the results array
		_results = [[NSMutableDictionary alloc] init];
		
		// Setup the queue
		_queue = [[NSOperationQueue alloc] init];
		
	}
	return self;
}

#pragma mark - Public

- (void)start {
 
	
	// Start the search
	NSInvocationOperation *searchOperation = [[NSInvocationOperation alloc] initWithTarget:self selector:@selector(runStringSearch:) object:self.projectPath];
	[_queue addOperation:searchOperation];
}

- (void)stop {
}

#pragma mark - Private

- (void)runStringSearch:(NSString *)searchPath {

	__weak typeof(self) weakSelf = self;
	
	[_results removeAllObjects];
	
	NSArray *filePaths;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidStartScanning:)]) {
		[self.delegate scannerDidStartScanning:self];
	}
	
	filePaths = [self getProjectImplementationFilesPaths];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_t group = dispatch_group_create();

	[filePaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
	
		dispatch_group_async(group, queue, ^{
		
			NSString *path = (NSString *)obj;
			
			NSArray *lines = [weakSelf linesContainingStringsInFileAtPath:path];
			NSMutableArray *relevantLines = [[NSMutableArray alloc] init];
			
			for (NSString *line in lines) {
				
				if (line) {
					// Warning : We might dismiss lines such as @"", @"Interesting Text!"....
					// Check if multiple strings in a single line.

					if (![line containsString:@"#define"] &&
						 ![line containsString:@"NSLog"] &&
						 ![line containsString:@"DLog"] &&
						 ![line containsString:@"SLog"] &&
						 ![line containsString:@"Image"] &&
						 ![line containsString:@"image"] &&
						 ![line containsString:@"initWithNibName"] &&
						 ![line containsString:@"const"] &&
						 ![line containsString:@"orKey"] &&
						 ![line containsString:@"@\"\""] &&
						 ![line containsString:@"@\"%@\""] &&
						 ![line containsString:@"@\"%@\""] &&
						 ![line containsString:@"Dictionary"] &&
						 ![line containsString:@"Date"] &&
						 ![line containsString:@"\":@\""] &&
						 ![line containsString:@"path"] &&
						 ![line containsString:@"@\"0\""] &&
						 ![line containsString:@"Log"] &&
						 ![line containsString:@"log"]) {
						
						NSLog(@"Added \"%@\"", line);
						
						[relevantLines addObject:line];
					}
				}
			}
			[_results setValue:relevantLines forKey:path];
		});
		
	}];
	dispatch_group_notify(group, queue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (self.delegate && [self.delegate respondsToSelector:@selector(scanner:didFinishScanning:)]) {
				[self.delegate scanner:self didFinishScanning:_results];
			}
		});
	});

}

- (NSArray *)getProjectImplementationFilesPaths {

	// Create a find task
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/bin/find"];

	NSArray *argvals = [NSArray arrayWithObjects:self.projectPath, @"-name", @"*.m", nil];
	[task setArguments: argvals];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	
	// Run task
	[task launch];
	
	// Read the response
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	
	// See if we can create a lines array
	NSArray *lines = [string componentsSeparatedByString:@"\n"];
	
	return lines;
}

-(NSArray *)linesContainingStringsInFileAtPath:(NSString *)filePath {
	
	NSMutableArray *strings = [[NSMutableArray alloc] init];

	NSString *fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	NSArray	*lines = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	for (NSString *line in lines) {
		
		if ([line rangeOfString:@"@\""].location != NSNotFound) {
			
			NSString *trimmedLine;
			trimmedLine = [[line mutableCopy] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
			trimmedLine = [[line mutableCopy] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			[strings addObject:trimmedLine];
		}
	}
	
	return strings;
}

@end
