//
//  TaskListViewController.h
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 3/31/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskListViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>{
    
    IBOutlet UIBarButtonItem *btnSignIn, *btnAddTask;
    
    IBOutlet UITableView *tblTaskList;
}

@end

