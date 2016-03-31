//
//  PBWebViewController.m
//  Pinbrowser
//
//  Created by Mikael Konutgan on 11/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import "PBWebViewController.h"
#import "PBNavigationBar.h"
#import <objc/runtime.h>

#pragma mark - UIWebView+PBWebViewController

@implementation UIView (PBWebViewController)
@dynamic url;

- (void)loadRequest:(NSURLRequest *)request {
    if (NSClassFromString(@"WKWebView")) {
        [(WKWebView *)self loadRequest:request];
    } else {
        [(UIWebView *)self loadRequest:request];
    }
}

- (void)setDelegateViews:(id)delegateView {
    if (NSClassFromString(@"WKWebView")) {
        [(WKWebView *)self setNavigationDelegate:delegateView];
        [(WKWebView *)self setUIDelegate:delegateView];
    } else {
        [(UIWebView *)self setDelegate:delegateView];
    }
}

- (void)loadRequestFromString: (NSString *) urlNameAsString {
    if (NSClassFromString(@"WKWebView")) {
        [(WKWebView *)self loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString:urlNameAsString]]];
    } else {
        [(UIWebView *)self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:urlNameAsString]]];
    }
}

- (NSURLRequest *)request {
    if (NSClassFromString(@"WKWebView")) {
        return objc_getAssociatedObject(self, @selector(request));
    } else {
        return ((UIWebView *)self).request;
    }
}

- (void)setRequest:(NSURLRequest *)request {
    if (NSClassFromString(@"WKWebView")) {
        objc_setAssociatedObject(self, @selector(request), request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (void)altLoadRequest:(NSURLRequest *)request {
    [self setRequest:request];
    [self altLoadRequest:request];
}

- (void)stopLoad {
    if (NSClassFromString(@"WKWebView")) {
        [(WKWebView *)self stopLoading];
    } else {
        [(UIWebView *)self stopLoading];
    }
}

- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL {
    if (NSClassFromString(@"WKWebView")) {
        [(WKWebView *)self loadHTMLString:string baseURL:baseURL];
    } else {
        [(UIWebView *)self loadHTMLString:string baseURL:baseURL];
    }
}

- (NSURL *)url {
    return [[self request] URL];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler: (void (^)(id, NSError *)) completionHandler {
    if (NSClassFromString(@"WKWebView")) {
        [(WKWebView *)self evaluateJavaScript:javaScriptString completionHandler:completionHandler];
    } else {
        NSString *string = [(UIWebView *)self stringByEvaluatingJavaScriptFromString: javaScriptString];
        if (completionHandler) {
            completionHandler(string, nil);
        }
    }
}

- (void)setScalesPagesToFit:(BOOL)setPages {
    if (NSClassFromString(@"WKWebView")) {
        return;
    } else {
        ((UIWebView *)self).scalesPageToFit = setPages;
    }
}

+ (void)load {
    //exchange loadRequest and altLoadRequest
    if (NSClassFromString(@"WKWebView")) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            Class class = [self class];
            SEL originalSelector = @selector(loadRequest:);
            SEL swizzledSelector = @selector(altLoadRequest:);
            Method originalMethod = class_getInstanceMethod(class, originalSelector);
            Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
            BOOL didAddMethod = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
            if (didAddMethod) {
                class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
            } else {
                method_exchangeImplementations(originalMethod, swizzledMethod);
            }
        });
    }
}

@end

#pragma mark - PBWebViewController

@interface PBWebViewController () <UIPopoverControllerDelegate, PBNavigationBarDelegate>

@property (strong, nonatomic) UIView<WebViewProvider> *webView;
@property (strong, nonatomic) PBNavigationBar *navigationBar;
@property (strong, nonatomic) UIPopoverController *activitiyPopoverController;
@property (assign, nonatomic) BOOL toolbarPreviouslyHidden;

@end

@implementation PBWebViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _showsNavigationToolbar = YES;
}

- (void)load {
    NSURLRequest *request = [NSURLRequest requestWithURL:self.URL cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:60.0];
    [self.webView loadRequest:request];
    if (self.navigationController.toolbarHidden) {
        self.toolbarPreviouslyHidden = YES;
        if (self.showsNavigationToolbar) {
            [self.navigationController setToolbarHidden:NO animated:YES];
        }
    }
}

- (void)clear {
    [self.webView loadHTML:@"" baseURL:nil];
    self.title = @"";
}

- (void)setNavigationButtonImage:(UIImage *)image forState:(UIControlState)state {
    [self.navigationBar setLeftButtonImage:image forState:state];
}

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
//    self.navigationController.navigationBarHidden = YES;
    [self configureWebView];
    [self configureNavigationBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.webView setDelegateViews:self];
    if (self.URL) {
        [self load];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [[[WKWebView alloc] init] stopLoading];
    [super viewWillDisappear:animated];
    [self.webView stopLoad];
    [self.webView setDelegateViews:nil];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (self.toolbarPreviouslyHidden && self.showsNavigationToolbar) {
        [self.navigationController setToolbarHidden:YES animated:YES];
    }
}

- (void)configureWebView {
    if (NSClassFromString(@"WKWebView")) {
        self.webView = [[WKWebView alloc] initWithFrame: [[self view] bounds]];
    } else {
        self.webView = [[UIWebView alloc] initWithFrame: [[self view] bounds]];
    }
    [self.view addSubview:self.webView];
    self.webView.frame = CGRectMake(0, 60, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 60);
    [self.webView setScalesPagesToFit:YES];
}

- (void)configureNavigationBar {
    self.navigationBar = [PBNavigationBar create];
    self.navigationBar.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 60);
    [self.view addSubview:self.navigationBar];
    self.navigationBar.delegate = self;
}

- (void)setTitle:(NSString *)title {
    [super setTitle:title];
    self.navigationBar.title = title;
}

- (void)navigationBarDidClickLeftButton:(PBNavigationBar *)navigationBar {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Helpers

- (void)finishLoad {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
}

#pragma mark - Web view delegate

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self finishLoad];
    self.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.URL = self.webView.request.URL;
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self finishLoad];
}

- (void) webView: (WKWebView *) webView didStartProvisionalNavigation: (WKNavigation *) navigation {
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
}

- (void) webView: (WKWebView *) webView didFailNavigation: (WKNavigation *) navigation withError: (NSError *) error {
    [self finishLoad];
}

- (void) webView: (WKWebView *) webView didFinishNavigation: (WKNavigation *) navigation {
    [self finishLoad];
    self.URL = self.webView.request.URL;
}

#pragma mark - Popover controller delegate

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController {
    self.activitiyPopoverController = nil;
}

@end
