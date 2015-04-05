//
//  TaskListViewController.m
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 3/31/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import "TaskListViewController.h"
#import "UpdateTaskViewController.h"

#import "GTMOAuth2ViewControllerTouch.h"

#import "AFNetworkReachabilityManager.h"
#import "AFHTTPRequestOperationManager.h"

#import "TaskCell.h"
#import "Utilities.h"
#import "DejalActivityView.h"

// Constants that ought to be defined by the API
NSString *const kTaskStatusCompleted = @"completed";
NSString *const kTaskStatusNeedsAction = @"needsAction";

// Keychain item name for saving the user's authentication information
NSString *const kMyClientID = @"510126163880-b6t7pmo6fr6nk48r00g7kj3qsb87h5n5.apps.googleusercontent.com";
NSString *const kMyClientSecret = @"JlH6MUJD0wxWa-rlnfrVCWgP";
NSString *const kKeychainItemName = @"Tasks List: Google Tasks";

@interface TaskListViewController () {
    
    AFNetworkReachabilityManager *reachabilityManager;

    NSMutableArray *tasks;
    
    NSInteger taskIndex;
    
    BOOL isUpdate, isError;

    NSString *errorTaskId;
}

@property (nonatomic, retain) GTMOAuth2Authentication *auth;
@property (nonatomic, assign) BOOL isReachable;

@end

@implementation TaskListViewController

#pragma mark - Custom Actions

- (NSString *)signedInUsername {
    // Get the email address of the signed-in user
    BOOL isSignedIn = self.auth.canAuthorize;
    if (isSignedIn) {
        return self.auth.userEmail;
    } else {
        return nil;
    }
}

- (BOOL)isSignedIn {
    NSString *name = [self signedInUsername];
    return (name != nil);
}

- (void)updateUI{

    if ([self isSignedIn]) {
        
        [btnSignIn setTitle:@"Sign Out"];
        [btnAddTask setEnabled:YES];
        
        [DejalBezelActivityView activityViewForView:self.view withLabel:@"Please Wait"];
        
        NSArray *tempTasks = [[Utilities fetchTaskByTaskListId:[[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"]] copy];
        
        for (NSDictionary *task in tempTasks) {
            if (![[(NSManagedObject *)task valueForKey:@"synced"] boolValue]) {
                
                [self performSelectorOnMainThread:@selector(addGoogleTaskListWithObject:) withObject:task waitUntilDone:YES];
            }
        }
        
        [self getGoogleTaskList];
        
    } else {
        [btnSignIn setTitle:@"Sign In"];
        [btnAddTask setEnabled:NO];
        
        tasks = [[Utilities fetchTaskByTaskListId:[[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"]] mutableCopy];
        
        [tblTaskList reloadData];
    }
}

- (void)viewController:(GTMOAuth2ViewControllerTouch *)viewController
      finishedWithAuth:(GTMOAuth2Authentication *)auth
                 error:(NSError *)error {
    if (error != nil) {
        // Authentication failed
        NSLog(@"Authentication Failed");
    } else {
        // Authentication succeeded
        self.auth = auth;
        
        [[NSUserDefaults standardUserDefaults] setObject:auth.accessToken forKey:@"accessToken"];
        [[NSUserDefaults standardUserDefaults] setObject:auth.refreshToken forKey:@"refreshToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self updateUI];
}

#pragma mark - RESTful API

- (void)addGoogleTaskListWithObject:(NSDictionary *)object{

    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/tasks/v1/lists/%@/tasks?access_token=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"],[[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"]];
    
    NSDictionary *parameters = @{@"title":[object valueForKey:@"title"],
                                 @"notes":[object valueForKey:@"notes"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    [manager POST:urlString
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             NSLog(@"Task: %@", responseObject);
             
             NSMutableDictionary *task = [[[NSMutableDictionary alloc] initWithDictionary:responseObject] mutableCopy];
             
             [task setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
             [task setValue:[[NSUserDefaults standardUserDefaults] valueForKey:@"taskListId"] forKey:@"listId"];
             
             if ([Utilities updateTaskWithObject:task withListId:[[NSUserDefaults standardUserDefaults] valueForKey:@"taskListId"]]) {
                 NSLog(@"Task Updated");
             }
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Error: %@", error);
             
             [DejalBezelActivityView removeViewAnimated:YES];
             
             [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
         }
     ];
}

- (void)getGoogleTaskList{
    
    NSDictionary *parameters = @{@"access_token":[[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    [manager GET:@"https://www.googleapis.com/tasks/v1/users/@me/lists"
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             NSLog(@"TaskList: %@", responseObject);
             
             [[NSUserDefaults standardUserDefaults] setObject:[[[responseObject objectForKey:@"items"] objectAtIndex:0] objectForKey:@"id"] forKey:@"taskListId"];
             [[NSUserDefaults standardUserDefaults] synchronize];
             
             [self setTitle:[[[responseObject objectForKey:@"items"] objectAtIndex:0] objectForKey:@"title"]];
             
             [self getGoogleTaskWithTaskListId:[[[responseObject objectForKey:@"items"] objectAtIndex:0] objectForKey:@"id"]];
             
             [tblTaskList reloadData];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Error: %@", error);
             
             [DejalBezelActivityView removeViewAnimated:YES];
             
             [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
         }
     ];
}

- (void)getGoogleTaskWithTaskListId:(NSString *)listId{
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/tasks/v1/lists/%@/tasks", listId];
    
    NSDictionary *parameters = @{@"access_token":[[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    [manager GET:urlString
      parameters:parameters
         success:^(AFHTTPRequestOperation *operation, id responseObject) {
             
             NSLog(@"Tasks: %@", responseObject);
             
             for (NSMutableDictionary *item in [[responseObject objectForKey:@"items"] mutableCopy]) {
                 
                 if (![Utilities isTaskExistsWithTaskId:[item objectForKey:@"id"]]) {

                     NSMutableDictionary *tempTask = [[[NSMutableDictionary alloc] initWithDictionary:item] mutableCopy];
                     
                     [tempTask setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
                     [tempTask setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"] forKey:@"listId"];
                     
                     if ([Utilities saveTaskWithObject:tempTask]) {
                         NSLog(@"Task Saved");
                     }
                 }
             }
             
             tasks = [[Utilities fetchTaskByTaskListId:[[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"]] mutableCopy];
             
             [tblTaskList reloadData];
             
             [DejalBezelActivityView removeViewAnimated:YES];
             
         } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
             
             NSLog(@"Error: %@", error);
             
             [DejalBezelActivityView removeViewAnimated:YES];
             
             [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
         }
     ];
}

#pragma mark - IBActions

- (IBAction)onSignInClicked:(id)sender {
    
    if (![[btnSignIn title] isEqualToString:@"Sign Out"]) {
        // Sign in
        GTMOAuth2ViewControllerTouch *viewController;
        viewController = [[GTMOAuth2ViewControllerTouch alloc] initWithScope:kGTLAuthScopeTasks
                                                                    clientID:kMyClientID
                                                                clientSecret:kMyClientSecret
                                                            keychainItemName:kKeychainItemName
                                                                    delegate:self
                                                            finishedSelector:@selector(viewController:finishedWithAuth:error:)];
        
        [[self navigationController] pushViewController:viewController animated:YES];
    } else {
        // Sign out
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];

        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"accessToken"];
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"refreshToken"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        self.auth = nil;
        
        [self updateUI];
    }
}

-(void)onTaskDeleteClicked:(id)sender
{
    UIButton *senderButton = (UIButton *)sender;
    
    for(NSManagedObject *task in tasks) {
        
        if([[task valueForKey:@"id"] isEqualToString:[[tasks objectAtIndex:senderButton.tag] valueForKey:@"id"]] && self.isReachable) {
        
            if ([self isSignedIn]) {
                
                [DejalBezelActivityView activityViewForView:self.view withLabel:@"Please Wait"];
                
                NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/tasks/v1/lists/%@/tasks/%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"], [task valueForKey:@"id"]];
                
                NSDictionary *parameters = @{@"access_token":[[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"]};
                
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                manager.requestSerializer = [AFJSONRequestSerializer serializer];
                manager.responseSerializer = [AFJSONResponseSerializer serializer];
                manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
                manager.securityPolicy.allowInvalidCertificates = YES;
                
                [manager DELETE:urlString
                     parameters:parameters
                        success:^(AFHTTPRequestOperation *operation, id responseObject) {
                            
                            NSLog(@"Deleted");
                            
                            if ([Utilities deleteTaskWithObject:task]) {
                                
                                [tasks removeObject:task];
                                
                                [tblTaskList reloadData];
                                
                                [DejalBezelActivityView removeViewAnimated:YES];
                            }
                            
                        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                            
                            NSLog(@"Error: %@", error);
                            
                            isError = YES;
                            
                            errorTaskId = [[tasks objectAtIndex:senderButton.tag] valueForKey:@"id"];
                            
                            [DejalBezelActivityView removeViewAnimated:YES];
                        }
                 ];
            } else {
                
                [Utilities showAlertViewWithTitle:@"Alert" andMessage:@"You need to sign in first"];
            }
        }
    }
}

#pragma mark - UITableView DataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    
    return [tasks count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    TaskCell *cell = (TaskCell *)[tableView dequeueReusableCellWithIdentifier:@"TaskCell"];
    
    NSManagedObject *task = (NSManagedObject *)[tasks objectAtIndex:indexPath.row];
    
    if ([[task valueForKey:@"synced"] boolValue] && self.isReachable && [self isSignedIn]) {
        [[cell contentView] setBackgroundColor:[UIColor greenColor]];
    } else if(isError && [[task valueForKey:@"id"] isEqualToString:errorTaskId]){
        [[cell contentView] setBackgroundColor:[UIColor redColor]];
    }else {
        [[cell contentView] setBackgroundColor:[UIColor orangeColor]];
    }
    
    if ([[task valueForKey:@"title"] length] > 0) {
        [[cell lblTitle] setText:[task valueForKey:@"title"]];
    } else {
        [[cell lblTitle] setText:@"No Title"];
    }
    
    [[cell btnDelete] setTag:indexPath.row];
    [[cell btnDelete] addTarget:self action:@selector(onTaskDeleteClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - UITableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    isUpdate = YES;
    taskIndex = indexPath.row;
    
    [self performSegueWithIdentifier:@"segueUpdateTask" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if([[segue identifier] isEqualToString:@"segueUpdateTask"] && isUpdate) {
        
        UpdateTaskViewController *viewController = (UpdateTaskViewController *) [segue destinationViewController];
        viewController.isUpdate = isUpdate;
        viewController.taskId = [[tasks objectAtIndex:taskIndex] valueForKey:@"id"];
        viewController.taskTitle = [[tasks objectAtIndex:taskIndex] valueForKey:@"title"];
        
        if ([[tasks objectAtIndex:taskIndex] valueForKey:@"notes"]) {
            viewController.taskDescription = [[tasks objectAtIndex:taskIndex] valueForKey:@"notes"];
        }
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    reachabilityManager = [AFNetworkReachabilityManager sharedManager];
    __unsafe_unretained typeof(self) weakSelf = self;
    [reachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"Reachability: %@", AFStringFromNetworkReachabilityStatus(status));
        
        // Check the reachability status and show an alert if the internet connection is not available
        switch (status) {
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"The reachability status is Unknown");
                weakSelf.isReachable = NO;
                break;

            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"The reachability status is not reachable");
                weakSelf.isReachable = NO;
                break;
            
            case AFNetworkReachabilityStatusReachableViaWWAN:
            case AFNetworkReachabilityStatusReachableViaWiFi:{
                
                NSLog(@"The reachability status is reachable");
                weakSelf.isReachable = YES;
                
                // Get the saved authentication, if any, from the keychain.
                GTMOAuth2Authentication *auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                                                      clientID:kMyClientID
                                                                                                  clientSecret:kMyClientSecret];
                
                if (auth.canAuthorize) {
                    weakSelf.auth = auth;
                }
                
                break;
            }
                
            default:
                break;
        }
        
        [weakSelf updateUI];
    }];
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
    
    [reachabilityManager startMonitoring];
}

- (void)viewDidDisappear:(BOOL)animated {
    
    [super viewDidDisappear:YES];
    
    [reachabilityManager stopMonitoring];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
