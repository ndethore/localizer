//
//  FilterViewController.h
//  Localizer
//
//  Created by Nicolas on 7/12/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol FilterViewControllerDelegate <NSObject>

- (void)didCancelFiltering;
- (void)didFinishFilteringWithArray:(NSArray*)array;

@end

@interface FilterViewController : NSViewController

@property (assign) IBOutlet id <FilterViewControllerDelegate> delegate;
@property (nonatomic, strong) NSMutableArray *dataSource;

@end
