//
//  ProjectScanner.h
//  Localizer
//
//  Created by Nicolas on 7/10/15.
//  Copyright © 2015 LYCL inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProjectScanner;

@protocol ProjectScannerDelegate <NSObject>

@optional
- (void)scannerDidStartScanning:(ProjectScanner *)scanner;
- (void)scanner:(ProjectScanner *)scanner didFindStringToLocalize:(NSString *)string;
- (void)scanner:(ProjectScanner *)scanner didFinishScanning:(NSDictionary*)results;

@end

@interface ProjectScanner : NSObject

@property (assign) id <ProjectScannerDelegate> delegate;
@property (nonatomic, strong) NSString *projectPath;

- (void)start;
- (void)stop;

@end