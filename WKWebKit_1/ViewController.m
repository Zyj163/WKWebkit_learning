//
//  ViewController.m
//  WKWebKit_1
//
//  Created by zhangyongjun on 16/5/20.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import "ViewController.h"
#import "Menu.h"
#import "SubTableViewController.h"
@import WebKit;

@interface ViewController () <WKNavigationDelegate, WKScriptMessageHandler, WKUIDelegate>

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *backBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *forwardBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *reloadBtn;

@property (strong, nonatomic) NSMutableArray *menuItems;

@property (strong, nonatomic) WKWebView *webView;

@end

@implementation ViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.menuItems = [NSMutableArray array];
        //如果WKWebView需要执行JS脚本,创建WebView对象时就得将JS脚本注入到WebView中
        WKWebViewConfiguration *config = [[WKWebViewConfiguration alloc]init];
        
        //隐藏菜单栏
        [config.userContentController addUserScript:[self javasciptObj:@"hideNavi"]];
        
        //获取菜单栏(JS代码，向app发消息或调取app方法，即这段代码是js文件中的，或者是注入到js文件中的)
        WKUserScript *s = [self javasciptObj:@"fetchMenus"];
        [config.userContentController addUserScript:s];
        
        //注册messageHandlers回调(JS向app发消息) webkit.messageHandlers[didFetchMenus].postMessage(items)
        [config.userContentController addScriptMessageHandler:self name:@"didFetchMenus"];
        
        //添加cookie(也可以通过之前保存的config进行设置)
        WKUserScript *cookieScript = [[WKUserScript alloc]
                                      initWithSource: @"document.cookie = 'TeskCookieKey1=TeskCookieValue1';document.cookie = 'TeskCookieKey2=TeskCookieValue2';"
                                      injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
        [config.userContentController addUserScript:cookieScript];
        
        WKWebView *webView = [[WKWebView alloc]initWithFrame:CGRectZero configuration:config];
        self.webView = webView;
        
        webView.navigationDelegate = self;
        webView.UIDelegate = self;
        webView.allowsBackForwardNavigationGestures = YES;
    }
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view insertSubview:self.webView belowSubview:self.progressView];
    self.webView.frame = self.view.bounds;
//    NSURL *url = [NSURL URLWithString:@"http://www.it007.com"];
    NSURL *url = [NSURL URLWithString:@"https://www.baidu.com"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    //添加cookie
    [request addValue:@"TeskCookieKey1=TeskCookieValue1;TeskCookieKey2=TeskCookieValue2;" forHTTPHeaderField:@"Cookie"];
    
    [self.webView loadRequest:request];
    
    //app调JS方法
//    NSString *meta = @"document.getElement.innerHTML";
//    [self.webView evaluateJavaScript:meta completionHandler:^(id _Nullable returnObj, NSError * _Nullable error) {
//        NSLog(@"返回值:%@,错误:%@",returnObj, error);
//    }];
    
    //KVO
    [self.webView addObserver:self forKeyPath:@"loading" options:0x01 context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:0x01 context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:0x01 context:nil];
}

- (WKUserScript *)javasciptObj:(NSString *)filename {
    NSString *file = [[NSBundle mainBundle] pathForResource:filename ofType:@"js"];
    if (file) {
        NSString *js = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
        if (js) {
            WKUserScript *scriptObj = [[WKUserScript alloc]initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];
            return scriptObj;
        }
    }
    return nil;
}

- (IBAction)backAction:(UIBarButtonItem *)sender {
    NSArray *backList = self.webView.backForwardList.backList;
    
    NSLog(@"backList=====%@",backList);
    
    [self.webView goBack];
}
- (IBAction)forwardAction:(UIBarButtonItem *)sender {
    NSArray *forwardList = self.webView.backForwardList.forwardList;
    
    NSLog(@"forwardList=====%@",forwardList);
    
    [self.webView goForward];
}
- (IBAction)stopAction:(UIBarButtonItem *)sender {
    [self.webView stopLoading];
}
- (IBAction)refresh:(UIBarButtonItem *)sender {
    [self.webView reload];
}
- (IBAction)showSub:(UIBarButtonItem *)sender {
    SubTableViewController *subvc = [SubTableViewController new];
    subvc.menus = self.menuItems;
    subvc.selectHandler = ^(Menu *menu) {
        NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:menu.url]];
        [self.webView loadRequest:request];
    };
    [self presentViewController:subvc animated:YES completion:nil];
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"loading"]) {
        self.forwardBtn.enabled = self.webView.canGoForward;
        self.backBtn.enabled = self.webView.canGoBack;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = self.webView.isLoading;
    }else if ([keyPath isEqualToString:@"title"]) {
        self.title = self.webView.title;
    }else if ([keyPath isEqualToString:@"estimatedProgress"]) {
        self.progressView.hidden = self.webView.estimatedProgress == 1.;
        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
    }
}

#pragma mark - WKUserScriptMessageHandler(JS发消息给app的回调,通过消息的内容决定要做的事情)
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    if ([message.name isEqualToString:@"didFetchMenus"]) {
        //获取菜单栏中信息
        [self.menuItems removeAllObjects];
        NSArray <NSDictionary *> *resultArr = message.body;
        for (NSDictionary *dic in resultArr) {
            Menu *menu = [Menu new];
            menu.title = dic[@"title"];
            menu.url = dic[@"url"];
            [self.menuItems addObject:menu];
            NSLog(@"%@",menu);
        }
    }
}

#pragma mark - WKNavigationDelegate
//当webview执行相关动作时回调, 主要在此处理了跨域请求问题，根据WebView对于即将跳转的HTTP请求头信息和相关信息来决定是否跳转
// 类似 UIWebView 的 -webView: shouldStartLoadWithRequest: navigationType:
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    //如果请求的动作是跨域的
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        NSLog(@"请求的动作是跨域的,%@",navigationAction);
        [webView loadRequest:navigationAction.request];
        decisionHandler(WKNavigationActionPolicyCancel);
    }else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}

//类似UIWebView的 -webViewDidStartLoad:
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"didStartProvisionalNavigation, %@,%@", webView, navigation);
}

//接收到服务器跳转请求之后调用
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation
{
    NSLog(@"didReceiveServerRedirectForProvisionalNavigation");
}

//这个代理方法表示当客户端收到服务器的响应头，根据response相关信息，可以决定这次跳转是否可以继续进行
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler
{
    NSLog(@"decidePolicyForNavigationResponse : %@", navigationResponse);
    decisionHandler(WKNavigationResponsePolicyAllow);
}

//内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation
{
    NSLog(@"didCommitNavigation");
}

- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler
{
    completionHandler(0, nil);
    NSLog(@"didReceiveAuthenticationChallenge");
}

// 类似 UIWebView 的 －webViewDidFinishLoad:
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
//    NSLog(@"didFinishNavigation");
//    NSString *meta = @"document.documentElement.innerHTML";
//    [self.webView evaluateJavaScript:meta completionHandler:^(id _Nullable returnObj, NSError * _Nullable error) {
//        NSLog(@"网页源码:%@,错误:%@",returnObj, error);
//    }];
    
//    NSString *js = @"$('#index-kw').val('123')";
//    [webView evaluateJavaScript:js completionHandler:^(id _Nullable returnObj, NSError * _Nullable error) {
//        NSLog(@"返回值:%@,错误:%@",returnObj, error);
//    }];
    
//    NSString *js = @"var input = document.getElementById('index-kw'); input.value = '122'";
//    [webView evaluateJavaScript:js completionHandler:^(id _Nullable returnObj, NSError * _Nullable error) {
//        NSLog(@"返回值:%@,错误:%@",returnObj, error);
//    }];
}

// 类似 UIWebView 的- webView:didFailLoadWithError:
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"didFailNavigation : %@", error);
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    NSLog(@"didFailProvisionalNavigation");
}

- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView
{
    NSLog(@"webViewWebContentProcessDidTerminate");
}

#pragma mark - WKUIDelegate
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(nonnull WKWebViewConfiguration *)configuration forNavigationAction:(nonnull WKNavigationAction *)navigationAction windowFeatures:(nonnull WKWindowFeatures *)windowFeatures
{
    //接口的作用是打开新窗口委托
    return nil;
}

//弹出警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler
{
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler();
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:^{}];
}


//弹出确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(BOOL))completionHandler
{
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:message
                                                                             message:nil
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定"
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *action) {
                                                          completionHandler(YES);
                                                      }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消"
                                                        style:UIAlertActionStyleCancel
                                                      handler:^(UIAlertAction *action){
                                                          completionHandler(NO);
                                                      }]];
    
    [self presentViewController:alertController animated:YES completion:^{}];
}

//弹出输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(nonnull NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(NSString * _Nullable))completionHandler
{
    // js 里面的alert实现，如果不实现，网页的alert函数无效
    completionHandler(@"Client Not handler");
}

- (void)webViewDidClose:(WKWebView *)webView
{
    NSLog(@"webViewDidClose");
}

- (BOOL)webView:(WKWebView *)webView shouldStartLoadWithRequest:(nonnull NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

@end
