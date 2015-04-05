//
//  TaskCell.h
//  Tasks List
//
//  Created by Mohammad Ashraful Kabir on 4/1/15.
//  Copyright (c) 2015 Mohammad Ashraful Kabir. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskCell : UITableViewCell

@property (nonatomic,retain) IBOutlet UILabel *lblTitle;
@property (nonatomic,retain) IBOutlet UIButton *btnDelete;

@end
