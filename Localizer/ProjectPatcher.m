//
//  ProjectPatcher.m
//  Localizer
//
//  Created by Nicolas on 7/15/15.
//  Copyright (c) 2015 LYCL inc. All rights reserved.
//

#import "ProjectPatcher.h"
#import "NSString+Utility.h"

@implementation ProjectPatcher

- (void)patchFiles:(NSDictionary *)fileIndex withKeys:(NSDictionary *)keysDictionary {
	
	__weak typeof(self) weakSelf = self;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_group_t group = dispatch_group_create();
	
	if (self.delegate && [self.delegate respondsToSelector:@selector(patcherDidStartPatching:)]) {
		[self.delegate patcherDidStartPatching:self];
	}
	
	[fileIndex.allKeys enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		
		dispatch_group_async(group, queue, ^{
			
			NSString *path = (NSString *)obj;
			
			for (NSString *string in [fileIndex objectForKey:path]) {
				
				NSString *key = [keysDictionary objectForKey:string];
				if (key.length == 0) key = string;
				else key = [key wrappedContent];
				
				NSString *localizedString = [self generateLocalizedStringWithKey:key];
				
				[weakSelf replaceString:string withString:localizedString inFileAtPath:path];
				
				if (self.delegate && [self.delegate respondsToSelector:@selector(patcher:didPatchString:)]) {
					[self.delegate patcher:self didPatchString:string];
				}
			}
		});
	}];
	
	dispatch_group_notify(group, queue, ^{
		dispatch_async(dispatch_get_main_queue(), ^{
			
			if (self.delegate && [self.delegate respondsToSelector:@selector(patcherDidFinishPatching:)]) {
				[self.delegate patcherDidFinishPatching:self];
			}
		});
	});
 
}


- (BOOL)replaceString:(NSString *)oldString withString:(NSString *)newString inFileAtPath:(NSString *)path {
	
	// Create a find task
	NSTask *task = [[NSTask alloc] init];
	[task setLaunchPath: @"/usr/bin/sed"];
	
	NSArray *argvals = [NSArray arrayWithObjects:@"-i", @"", [NSString stringWithFormat:@"s/%@/%@/", [oldString escapedString], [newString escapedString]], path, nil];
	[task setArguments: argvals];
	
	NSPipe *pipe = [NSPipe pipe];
	[task setStandardOutput: pipe];
	NSFileHandle *file = [pipe fileHandleForReading];
	
	// Run task
	[task launch];
	
	// Read the response
	NSData *data = [file readDataToEndOfFile];
	NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
	return !(string.length > 0);
}

- (NSString *)generateLocalizedStringWithKey:(NSString *)key andDefaultValue:(NSString *)value {
	
	return [NSString stringWithFormat:@"NSLocalizedStringWithDefaultValue(%@, nil, [NSBundle mainBundle], %@, nil)", key, value];
}

- (NSString *)generateLocalizedStringWithKey:(NSString *)key {

	return [NSString stringWithFormat:@"NSLocalizedString(%@, nil)", key];
}


@end
