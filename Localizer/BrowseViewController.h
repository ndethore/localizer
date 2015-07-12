//
//  BrowseViewController.h
//  Localizer
//
//  Created by Nicolas on 7/9/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol BrowseViewControllerDelegate <NSObject>

@optional
- (void)didTapSearchButton:(NSButton *)button withProjectPath:(NSString *)path;

@end

@interface BrowseViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

@property (assign) IBOutlet id <BrowseViewControllerDelegate> delegate;

@end
