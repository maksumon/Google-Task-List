//
//  Utilities.h
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 4/2/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#define NULL_TO_NIL(obj) ({ __typeof__ (obj) __obj = (obj); __obj == [NSNull null] ? nil : obj; })
#define IS_OS_8_OR_LATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0)

// Authorization scope
// Manage your tasks
static NSString * const kGTLAuthScopeTasks = @"https://www.googleapis.com/auth/tasks";
// View your tasks
static NSString * const kGTLAuthScopeTasksReadonly = @"https://www.googleapis.com/auth/tasks.readonly";

@interface Utilities : NSObject

+(void)showAlertViewWithTitle:(NSString *)title andMessage:(NSString *)message;

+(NSManagedObjectContext *)managedObjectContext;

// Check Entities
+(BOOL)isTaskExistsWithTaskId:(NSString *)taskId;

// Save Entities
+(BOOL)saveTaskWithObject:(NSDictionary *)results;

// Update Entities
+(BOOL)updateTaskWithObject:(NSDictionary *)taskDictionary withListId:(NSString *)listId;
+(BOOL)updateTaskWithObject:(NSDictionary *)taskDictionary byTaskId:(NSString *)taskId;

// Delete Entities
+(BOOL)deleteTaskWithObject:(NSManagedObject *)task;

// Search Entities
+(NSArray *)fetchTaskByTaskListId:(NSString *)taskId;

@end
