//
//  NSString+Utility.h
//  Localizer
//
//  Created by Nicolas on 7/17/15.
//  Copyright (c) 2015 LYCL inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Utility)

- (BOOL)isLocalizedString;

- (NSArray *)localizedStringsArray;
- (NSArray *)objectiveCStringsArray;
- (NSArray *)stringsMatchingPattern:(NSString *)pattern;

- (NSString *)localizedKey;
- (NSString *)localizedValue;

- (NSString *)unwrappedContent;
- (NSString *)wrappedContent;

- (NSString *)escapedString;
@end
