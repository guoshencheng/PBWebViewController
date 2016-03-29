//
//  PBWebViewController.h
//  Pinbrowser
//
//  Created by Mikael Konutgan on 11/02/2013.
//  Copyright (c) 2013 Mikael Konutgan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@protocol WebViewProvider <NSObject>

@property (strong, nonatomic) NSURLRequest *request;
@property (strong, nonatomic) NSURL *url;

- (void)setDelegateViews:(id)delegateView;
- (void)setScalesPagesToFit:(BOOL)setPages;
- (void)loadRequest:(NSURLRequest *)request;
- (void)loadRequestFromString:(NSString *)urlNameAsString;
- (void)stopLoad;
- (void)loadHTML:(NSString *)string baseURL:(NSURL *)baseURL;
- (void)evaluateJavaScript:(NSString *)javaScriptString completionHandler: (void (^)(id, NSError *)) completionHandler;

@end

@interface UIWebView (PBWebViewController) <WebViewProvider>

/*
 * Shorthand for setting UIWebViewDelegate to a class.
 */
- (void) setDelegateViews: (id <UIWebViewDelegate>) delegateView;

@end

@interface WKWebView (PBWebViewController) <WebViewProvider>

/*
 * Shorthand for setting WKUIDelegate and WKNavigationDelegate to the same class.
 */
- (void) setDelegateViews: (id <WKNavigationDelegate, WKUIDelegate>) delegateView;

@end

/**
 * The `PBWebViewController` class is a view controller that displays the contents of a URL
 * along tith a navigation toolbar with buttons to stop/refresh the loading of the page
 * as well as buttons to go back, forward and to share the URL using a `UIActivityViewController`.
 */
@interface PBWebViewController : UIViewController <UIWebViewDelegate, WKUIDelegate>

/**
 * The URL that will be loaded by the web view controller.
 * If there is one present when the web view appears, it will be automatically loaded, by calling `load`,
 * Otherwise, you can set a `URL` after the web view has already been loaded and then manually call `load`.
 */
@property (strong, nonatomic) NSURL *URL;

/**
 * A Boolean indicating whether the web view controller’s toolbar,
 * which displays a stop/refresh, back, forward and share button, is shown.
 * The default value of this property is `YES`.
 */
@property (assign, nonatomic) BOOL showsNavigationToolbar;

/**
 * Loads the given `URL`.
 * This is called automatically when the when the web view appears if a `URL` exists,
 * otehrwise it can be called manually.
 */
- (void)load;

/**
 * Clears the contents of the web view.
 */
- (void)clear;

- (void)setNavigationButtonImage:(UIImage *)image forState:(UIControlState)state;

@end
