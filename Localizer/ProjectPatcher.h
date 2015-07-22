//
//  ProjectPatcher.h
//  Localizer
//
//  Created by Nicolas on 7/15/15.
//  Copyright (c) 2015 LYCL inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ProjectPatcher;

@protocol ProjectPatcherDelegate <NSObject>

@optional
- (void)patcherDidStartPatching:(ProjectPatcher *)patcher;
- (void)patcher:(ProjectPatcher *)patcher didPatchString:(NSString *)string;
- (void)patcherDidFinishPatching:(ProjectPatcher *)patcher;

@end


@interface ProjectPatcher : NSObject

@property (assign) id <ProjectPatcherDelegate> delegate;

- (void)patchFiles:(NSDictionary *)fileIndex withKeys:(NSDictionary *)keysDictionary;

@end
