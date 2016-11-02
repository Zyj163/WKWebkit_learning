//
//  SubTableViewController.h
//  WKWebKit_1
//
//  Created by zhangyongjun on 16/5/20.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SubTableViewController : UITableViewController

@property (copy, nonatomic) NSArray *menus;

@property (strong, nonatomic) void(^selectHandler)(id menu);

@end
