//
//  Utilities.m
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 4/2/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import "Utilities.h"

@implementation Utilities

+(void)showAlertViewWithTitle:(NSString *)title andMessage:(NSString *)message{
    
    [[[UIAlertView alloc] initWithTitle:title
                                message:message
                               delegate:nil
                      cancelButtonTitle:@"OK"
                      otherButtonTitles:nil, nil] show];
}

+(NSManagedObjectContext *)managedObjectContext{
    
    NSManagedObjectContext *context = nil;
    id delegate = [[UIApplication sharedApplication] delegate];
    if ([delegate performSelector:@selector(managedObjectContext)]) {
        context = [delegate managedObjectContext];
    }
    return context;
}

// Check Entities
+(BOOL)isTaskExistsWithTaskId:(NSString *)taskId{
    
    BOOL success = NO;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"id = %@", taskId]];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    
    NSUInteger count = [[Utilities managedObjectContext] countForFetchRequest:request error:&error];
    if (count == NSNotFound){
        // some error occurred
        success = NO;
    } else if (count == 0){
        // no matching object
        success = NO;
    }else{
        // at least one matching object exists
        success = YES;
    }
    
    return success;
}

// Save Entities
+(BOOL)saveTaskWithObject:(NSDictionary *)results{
    
    BOOL success = NO;
    
    NSManagedObjectContext *context = [Utilities managedObjectContext];
    
    // Create a new managed object
    NSManagedObject *newTask = [NSEntityDescription insertNewObjectForEntityForName:@"Task"
                                                                    inManagedObjectContext:context];
    
    [newTask setValue:[results objectForKey:@"synced"] forKey:@"synced"];
    [newTask setValue:NULL_TO_NIL([results objectForKey:@"notes"]) forKey:@"notes"];
    [newTask setValue:NULL_TO_NIL([results objectForKey:@"id"]) forKey:@"id"];
    [newTask setValue:NULL_TO_NIL([results objectForKey:@"listId"]) forKey:@"listId"];
    [newTask setValue:NULL_TO_NIL([results objectForKey:@"title"]) forKey:@"title"];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        
        success = NO;
        
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
    } else {
        
        success = YES;
    }
    
    return success;
}

// Update Entities
+(BOOL)updateTaskWithObject:(NSDictionary *)taskDictionary withListId:(NSString *)listId{
    
    BOOL success = NO;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"id = %@", @""]];
    
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
        success = NO;
    } else {
        for (NSManagedObject *task in result) {
            [task setValue:[taskDictionary objectForKey:@"synced"] forKey:@"synced"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"notes"]) forKey:@"notes"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"id"]) forKey:@"id"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"listId"]) forKey:@"listId"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"title"]) forKey:@"title"];
            
            NSError *error = nil;
            // Save the object to persistent store
            if (![task.managedObjectContext save:&error]) {
                
                success = NO;
                
                NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
            } else {
                
                success = YES;
            }
        }
    }
    
    return success;
}

+(BOOL)updateTaskWithObject:(NSDictionary *)taskDictionary byTaskId:(NSString *)taskId{
    
    BOOL success = NO;
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"id = %@", taskId]];
    
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);

        success = NO;
    } else {
        for (NSManagedObject *task in result) {
            [task setValue:[taskDictionary objectForKey:@"synced"] forKey:@"synced"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"notes"]) forKey:@"notes"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"id"]) forKey:@"id"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"listId"]) forKey:@"listId"];
            [task setValue:NULL_TO_NIL([taskDictionary objectForKey:@"title"]) forKey:@"title"];
            
            NSError *error = nil;
            // Save the object to persistent store
            if (![task.managedObjectContext save:&error]) {
                
                success = NO;
                
                NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
                [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
            } else {
                
                success = YES;
            }
        }
    }
    
    return success;
}

// Delete Entities
+(BOOL)deleteTaskWithObject:(NSManagedObject *)task{
    
    BOOL success = NO;
    
    NSManagedObjectContext *context = [Utilities managedObjectContext];
    
    [context deleteObject:task];
    
    NSError *error = nil;
    // Save the object to persistent store
    if (![context save:&error]) {
        
        success = NO;
        
        NSLog(@"Can't Save! %@ %@", error, [error localizedDescription]);
        [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
    } else {
        
        success = YES;
    }
    
    return success;
}

// Search Entities
+(NSArray *)fetchTaskByTaskListId:(NSString *)taskListId{
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    [request setPredicate:[NSPredicate predicateWithFormat:@"listId = %@", taskListId]];
    
    NSError *error = nil;
    NSArray *result = [self.managedObjectContext executeFetchRequest:request error:&error];
    
    if (error) {
        NSLog(@"Unable to execute fetch request.");
        NSLog(@"%@, %@", error, error.localizedDescription);
        
    } else {
        NSLog(@"Result: %@", result);
    }
    
    return result;
}

@end
