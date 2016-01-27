//
//  PBWebViewController.m
//  Pinbrowser
//
//  Created by Mikael Konutgan on 11/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import "PBWebViewController.h"
#import <objc/runtime.h>

#pragma mark - UIWebView+PBWebViewController

@implementation UIWebView (PBWebViewController)
@dynamic url;

- (void)setDelegateViews:(id <UIWebViewDelegate>) delegateView {
    [self setDelegate: delegateView];
}

- (void)loadRequestFromString: (NSString *) urlNameAsString {
    [self loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString: urlNameAsString]]];
}

- (void)stopLoad {
    [self stopLoading];
}

- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL {
    [self loadHTMLString:string baseURL:baseURL];
}

- (NSURL *)url {
    return [[self request] URL];
}

- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler: (void (^)(id, NSError *)) completionHandler {
    NSString *string = [self stringByEvaluatingJavaScriptFromString: javaScriptString];
    if (completionHandler) {
        completionHandler(string, nil);
    }
}

- (void)setScalesPagesToFit:(BOOL)setPages {
    self.scalesPageToFit = setPages;
}

@end

#pragma mark - WKWebView+PBWebViewController

@implementation WKWebView (PBWebViewController)
@dynamic url;

- (void)setDelegateViews:(id <WKNavigationDelegate, WKUIDelegate>) delegateView {
    [self setNavigationDelegate: delegateView];
    [self setUIDelegate: delegateView];
}

- (NSURLRequest *)request {
    return objc_getAssociatedObject(self, @selector(request));
}

- (void)setRequest:(NSURLRequest *)request {
    objc_setAssociatedObject(self, @selector(request), request, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)altLoadRequest:(NSURLRequest *)request {
    [self setRequest:request];
    [self altLoadRequest:request];
}

- (void)stopLoad {
    [self stopLoading];
}

- (void)loadRequestFromString:(NSString *)urlNameAsString {
    [self loadRequest: [NSURLRequest requestWithURL:[NSURL URLWithString: urlNameAsString]]];
}

- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL {
    [self loadHTMLString:string baseURL:baseURL];
}

- (void)setScalesPagesToFit:(BOOL)setPages {
    return; // not supported in WKWebView
}

+ (void)load {
    //exchange loadRequest and altLoadRequest
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

@end

#pragma mark - PBWebViewController

@interface PBWebViewController () <UIPopoverControllerDelegate>

@property (strong, nonatomic) UIView<WebViewProvider> *webView;

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

#pragma mark - View controller lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    if (NSClassFromString(@"WKWebView")) {
        self.webView = [[WKWebView alloc] initWithFrame: [[self view] bounds]];
    } else {
        self.webView = [[UIWebView alloc] initWithFrame: [[self view] bounds]];
    }
    [self.webView setScalesPagesToFit:YES];
    self.view = self.webView;
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
