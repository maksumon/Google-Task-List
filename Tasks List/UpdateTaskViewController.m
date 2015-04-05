//
//  UpdateTaskViewController.m
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 4/1/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import "UpdateTaskViewController.h"

#import "AFNetworkReachabilityManager.h"
#import "AFHTTPRequestOperationManager.h"

#import "Utilities.h"
#import "DejalActivityView.h"

@interface UpdateTaskViewController () {
    
    CLLocationManager *locationManager;
    
    NSDictionary *locationDictionary;
}

@end

@implementation UpdateTaskViewController

#pragma mark - Custom Action

-(void)viewTapped:(UITapGestureRecognizer *)recognizer
{
    [txtTitle resignFirstResponder];
    [txtDescription resignFirstResponder];
}

- (void)updateGoogleTaskListWithObject:(NSDictionary *)object{
    
    NSString *urlString = [NSString stringWithFormat:@"https://www.googleapis.com/tasks/v1/lists/%@/tasks/%@?access_token=%@", [[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"],self.taskId,[[NSUserDefaults standardUserDefaults] valueForKey:@"accessToken"]];
    
    NSDictionary *parameters = @{@"title":[object valueForKey:@"title"],
                                 @"notes":[object valueForKey:@"notes"]};
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer = [AFJSONResponseSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"application/json"];
    manager.securityPolicy.allowInvalidCertificates = YES;
    
    [manager PATCH:urlString
       parameters:parameters
          success:^(AFHTTPRequestOperation *operation, id responseObject) {
              
              NSLog(@"Task: %@", responseObject);
              
              NSMutableDictionary *task = [[[NSMutableDictionary alloc] initWithDictionary:responseObject] mutableCopy];
              
              [task setValue:[NSNumber numberWithBool:YES] forKey:@"synced"];
              [task setValue:[[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"] forKey:@"listId"];
              
              [DejalBezelActivityView removeViewAnimated:YES];
              
              if ([Utilities updateTaskWithObject:task byTaskId:self.taskId]) {
                  [Utilities showAlertViewWithTitle:@"Success" andMessage:@"Task Updated Successfully"];
              } else{
                  [Utilities showAlertViewWithTitle:@"Error" andMessage:@"Task Update Unsuccessful"];
              }
          } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
              
              NSLog(@"Error: %@", error);
              
              [DejalBezelActivityView removeViewAnimated:YES];
              
              [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
          }
     ];
}

#pragma mark - IBAction

-(IBAction)onSaveClicked:(id)sender{
 
    [txtTitle resignFirstResponder];
    [txtDescription resignFirstResponder];
    
    if ([[txtTitle text] length] > 0 && [[txtDescription text] length] > 0) {
        if (self.isUpdate) {
            
            [DejalBezelActivityView activityViewForView:self.view withLabel:@"Please Wait"];
            
            NSDictionary *task = @{@"notes": txtDescription.text,
                                   @"title": txtTitle.text};
            [self performSelectorOnMainThread:@selector(updateGoogleTaskListWithObject:) withObject:task waitUntilDone:YES];
        } else {
            
            NSDictionary *task = @{@"synced": [NSNumber numberWithBool:NO],
                                   @"notes": txtDescription.text,
                                   @"id": @"",
                                   @"listId": [[NSUserDefaults standardUserDefaults] objectForKey:@"taskListId"],
                                   @"title": txtTitle.text};
            
            if ([Utilities saveTaskWithObject:task]) {
                
                [txtTitle setText:@""];
                [txtDescription setText:@""];
                
                [Utilities showAlertViewWithTitle:@"Success" andMessage:@"Task Saved Successfully"];
            } else{
                
                [Utilities showAlertViewWithTitle:@"Error" andMessage:@"Task Save Unsuccessful"];
            }
        }
    } else {
        
        [Utilities showAlertViewWithTitle:@"Alert" andMessage:@"Title or Description should've text"];
    }
}

#pragma mark - CLLocationManager Delegate

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
    
    NSLog(@"Error: %@",error.description);
    
    [Utilities showAlertViewWithTitle:@"Error" andMessage:[error localizedDescription]];
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
    CLLocation *tempLocation = [locations lastObject];
    
    [txtDescription setText:[NSString stringWithFormat:@"Latitude: %f, Longitude: %f", tempLocation.coordinate.latitude, tempLocation.coordinate.longitude]];
    
    [locationManager stopUpdatingLocation];
}

- (void)viewDidLoad {

    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [[txtDescription layer] setBorderWidth:0.5];
    [[txtDescription layer] setBorderColor:[[UIColor lightGrayColor] CGColor]];
    [[txtDescription layer] setCornerRadius:5.0];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(viewTapped:)];
    [self.view addGestureRecognizer:tapGesture];
    
    if (self.isUpdate) {
        [txtTitle setText:self.taskTitle];
        [txtDescription setText:self.taskDescription];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    
    [super viewDidAppear:YES];
    
    if (!self.isUpdate) {
        
        locationManager = [[CLLocationManager alloc] init];
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        
        if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
            [locationManager requestWhenInUseAuthorization];
        
        [locationManager startUpdatingLocation];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
