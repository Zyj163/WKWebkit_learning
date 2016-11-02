//
//  fetchMenus.js
//  WKWebKit_1
//  从页面中的导航条菜单中抓取菜单条
//  Created by zhangyongjun on 16/5/20.
//  Copyright © 2016年 张永俊. All rights reserved.
//

var menusDiv = document.querySelector('div.nv_i');
var menus = menusDiv.querySelectorAll('li');
//函数，解析menus数组中的每个菜单项
function parseMenus(){
    result = [];//定义一个数组
    for(var i=0; i<menus.length; i++){
        var menu = menus[i];//拿到一个菜单条
        var url = menu.querySelector('a').getAttribute('href');
        var title = menu.querySelector('a').textContent;
        result.push({url, title});
    }
    return result;
}
var items = parseMenus();

//将数据送入到webview中
webkit.messageHandlers.didFetchMenus.postMessage(items);






