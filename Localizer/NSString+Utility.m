//
//  NSString+Utility.m
//  Localizer
//
//  Created by Nicolas on 7/17/15.
//  Copyright (c) 2015 LYCL inc. All rights reserved.
//

#import "NSString+Utility.h"

@implementation NSString (Utility)

static NSString *const kLocalizedStringKey = @"key";
static NSString *const kLocalizedStringValue = @"value";

#pragma mark - Public

- (BOOL)isLocalizedString {
	
	return [self containsString:@"NSLocalizedString"];
}

- (NSArray *)localizedStringsArray {

	return [self stringsMatchingPattern:@"NSLocalizedString.*?\\)"];
}

- (NSArray *)objectiveCStringsArray {
	
	return [self stringsMatchingPattern:@"@\"[^\"]+\""];
}

- (NSArray *)stringsMatchingPattern:(NSString *)pattern {
	
	NSMutableArray *strings = [[NSMutableArray alloc] init];
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
	NSArray *matches = [regex matchesInString:self options:0 range:NSMakeRange(0, self.length)];
	
	for (NSTextCheckingResult *result in matches) {
		[strings addObject:[self substringWithRange:result.range]];
	}
	
	return strings;
}

- (NSString *)localizedKey {
	
	NSDictionary *dictionary = [self localizedKeyAndValueDictionary];
	
	return [dictionary valueForKey:kLocalizedStringKey];
}

- (NSString *)localizedValue {

	NSDictionary *dictionary = [self localizedKeyAndValueDictionary];
	
	return [dictionary valueForKey:kLocalizedStringValue];
	
}

- (NSDictionary *)localizedKeyAndValueDictionary {

	NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\(.*?\\)" options:0 error:nil];
	NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
	
	NSString *expression = [self substringWithRange:result.range];
	expression = [expression substringWithRange:NSMakeRange(1, expression.length - 2)];
	
	NSArray *components = [expression componentsSeparatedByString:@","];

	if (components.count >= 1) {
		
		NSString *localizedKey = [components objectAtIndex:0];
		NSString *defaultValue = [components objectAtIndex:0];
		
//		localizedKey = [localizedKey stringByReplacingOccurrencesOfString:@"@\"" withString:@""];
//		localizedKey = [localizedKey stringByReplacingOccurrencesOfString:@"\"" withString:@""];
		
		if (components.count == 5) {
			defaultValue = [components objectAtIndex:3];
		}
		
		[dictionary setObject:localizedKey forKey:kLocalizedStringKey];
		[dictionary setObject:defaultValue forKey:kLocalizedStringValue];
	}
	
	return dictionary;
}

- (NSString *)unwrappedContent {
	
	NSString *content;
	
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"[^\"@]*[^\"@]" options:0 error:nil];
	NSTextCheckingResult *result = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
	
	content = [self substringWithRange:result.range];
	
	return content;
}

- (NSString *)wrappedContent {
	
	return [NSString stringWithFormat:@"@\"%@\"", self];
	
}

- (NSString *)escapedString {

	NSMutableString *escapedString = [self mutableCopy];
	
//	[escapedString replaceOccurrencesOfString:@" " withString:@"\\ " options:0 range:NSMakeRange(0, escapedString.length)];
//	[escapedString replaceOccurrencesOfString:@"\"" withString:@"\\\"" options:0 range:NSMakeRange(0, escapedString.length)];
	[escapedString replaceOccurrencesOfString:@"[" withString:@"\\[" options:0 range:NSMakeRange(0, escapedString.length)];
	[escapedString replaceOccurrencesOfString:@"]" withString:@"\\]" options:0 range:NSMakeRange(0, escapedString.length)];

	return escapedString;
}

@end
