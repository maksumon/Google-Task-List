//
//  UpdateTaskViewController.h
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 4/1/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>

@interface UpdateTaskViewController : UIViewController <CLLocationManagerDelegate>{
    
    IBOutlet UITextField *txtTitle;
    IBOutlet UITextView *txtDescription;
}

@property (nonatomic, retain) NSString *taskId;
@property (nonatomic, retain) NSString *taskTitle;
@property (nonatomic, retain) NSString *taskDescription;

@property (assign) BOOL isUpdate;

@end
