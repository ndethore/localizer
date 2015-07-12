//
//  ProjectScanner.m
//  Localizer
//
//  Created by Nicolas on 7/10/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import "ProjectScanner.h"

@interface ProjectScanner() {
	
	NSMutableArray *_results;

	NSOperationQueue *_queue;

}
@end

@implementation ProjectScanner

- (instancetype)init {
	if (self = [super init]) {
		
		// Setup the results array
		_results = [[NSMutableArray alloc] init];
		
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
	
	NSArray *filePaths;
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(scannerDidStartScanning:)]) {
		[self.delegate scannerDidStartScanning:self];
	}
	
	NSLog(@"Searching for .m files...");
	filePaths = [self getProjectImplementationFilesPaths];
	NSLog(@"%ld .m files found.", filePaths.count);
	NSLog(@"%@", filePaths);
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_t group = dispatch_group_create();

	[filePaths enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
	
		dispatch_group_async(group, queue, ^{
		
			NSString *path = (NSString *)obj;
			
			NSArray *strings = [weakSelf stringsInFile:path];

			for (NSString *string in strings) {
				
				if (string) {
					if (![string containsString:@"#define"] &&
						 ![string containsString:@"NSLog"] &&
						 ![string containsString:@"DLog"] &&
						 ![string containsString:@"SLog"] &&
						 ![string containsString:@"Image"] &&
						 ![string containsString:@"image"] &&
						 ![string containsString:@"initWithNibName"] &&
						 ![string containsString:@"const"] &&
						 ![string containsString:@"orKey"] &&
						 ![string containsString:@"@\"\""] &&
						 ![string containsString:@"@\"%@\""] &&
						 ![string containsString:@"@\"%@\""] &&
						 ![string containsString:@"Dictionary"] &&
						 ![string containsString:@"Date"] &&
						 ![string containsString:@"\":@\""] &&
						 ![string containsString:@"path"] &&
						 ![string containsString:@"@\"0\""] &&
						 ![string containsString:@"Log"] &&
						 ![string containsString:@"log"]) {
						
						[_results addObject:string];
						NSLog(@"Added \"%@\"", string);
					}
				}
			}
			
		});
		
	}];
	dispatch_group_notify(group, queue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			
			[_results sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
			
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

-(NSArray *)stringsInFile:(NSString *)filePath {
	
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
