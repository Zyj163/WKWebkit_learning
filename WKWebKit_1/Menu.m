//
//  Menu.m
//  WKWebKit_1
//
//  Created by zhangyongjun on 16/5/20.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import "Menu.h"

@implementation Menu

- (NSString *)description
{
    return [NSString stringWithFormat:@"title:%@, url:%@",self.title, self.url];
}

@end
