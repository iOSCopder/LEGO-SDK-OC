//
//  LGONavigationController.m
//  LEGO-SDK-OC
//
//  Created by adi on 16/8/9.
//  Copyright © 2016年 UED Center. All rights reserved.
//

#import <WebKit/WebKit.h>
#import "LGOBuildFailed.h"
#import "LGOCore.h"
#import "LGONavigationController.h"
#import "UIViewController+LGOViewController.h"

@interface LGONavigationRequest : LGORequest

@property(nonatomic, copy) NSString *opt;               // push/pop.
@property(nonatomic, copy) NSString *path;              // an URLString.
@property(nonatomic, assign) BOOL animated;             // push or pop need animation. Defaults to true.
@property(nonatomic, copy) NSString *title;             // next title.
@property(nonatomic, assign) BOOL statusBarHidden;      // next title.
@property(nonatomic, assign) BOOL navigationBarHidden;  // next title.
@property(nonatomic, copy) NSDictionary *args;          // deliver context to next ViewController.

@end

@implementation LGONavigationRequest

@end

static NSDate *lastPush;

@interface LGONavigationOperation : LGORequestable

@property(nonatomic, retain) LGONavigationRequest *request;

@end

@implementation LGONavigationOperation

- (LGOResponse *)requestSynchronize {
    if ([self.request.opt isEqualToString:@"push"]) {
        [self push];
    } else if ([self.request.opt isEqualToString:@"pop"]) {
        [self pop];
    }
    return [LGOResponse new];
}

- (void)pop {
    UIViewController *requestVC = [self.request.context requestViewController];
    if (requestVC != nil && requestVC.navigationController) {
        [requestVC.navigationController popViewControllerAnimated:self.request.animated];
    }
}

- (void)push {
    if (lastPush != nil && lastPush.timeIntervalSinceNow > -1.0) {
        NSLog(@"两次 Push 的操作不能少于 1 秒");
        return;
    } else {
        lastPush = [NSDate new];
    }
    if (self.request.path.length > 0) {
        NSURL *relativeURL = nil;
        UIView *webView = self.request.context.requestWebView;
        if (webView != nil && [webView isKindOfClass:[UIWebView class]]) {
            relativeURL = ((UIWebView *)webView).request.URL;
        }
        if (webView != nil && [webView isKindOfClass:[WKWebView class]]) {
            relativeURL = ((WKWebView *)webView).URL;
        }
        NSURL *URL = [NSURL URLWithString:self.request.path relativeToURL:relativeURL];
        if (URL != nil) {
            [self pushWebView:URL];
        }
    }
}

- (void)pushWebView:(NSURL *)URL {
    UIViewController *nextViewController = [UIViewController new];
    [nextViewController lgo_openWebViewWithRequest:[[NSURLRequest alloc] initWithURL:URL] args:self.request.args];
    nextViewController.hidesBottomBarWhenPushed = YES;
    nextViewController.title = self.request.title;
    if ([nextViewController respondsToSelector:NSSelectorFromString(@"lgo_navigationBarHidden")]) {
        [nextViewController setValue:@(self.request.navigationBarHidden) forKey:@"lgo_navigationBarHidden"];
    }
    if ([nextViewController respondsToSelector:NSSelectorFromString(@"lgo_statusBarHidden")]) {
        [nextViewController setValue:@(self.request.statusBarHidden) forKey:@"lgo_statusBarHidden"];
    }
    UINavigationController *navigationController = [[self.request.context requestViewController] navigationController];
    if (navigationController == nil) {
        return;
    }
    [navigationController pushViewController:nextViewController animated:self.request.animated];
}

@end

@implementation LGONavigationController

- (LGORequestable *)buildWithRequest:(LGORequest *)request {
    if ([request isKindOfClass:[LGONavigationRequest class]]) {
        LGONavigationOperation *operation = [LGONavigationOperation new];
        operation.request = (LGONavigationRequest *)request;
        return operation;
    }
    return [[LGOBuildFailed alloc] initWithErrorString:@"RequestObject Downcast Failed"];
}

- (LGORequestable *)buildWithDictionary:(NSDictionary *)dictionary context:(LGORequestContext *)context {
    LGONavigationRequest *request = [LGONavigationRequest new];
    request.context = context;
    request.opt = [dictionary[@"opt"] isKindOfClass:[NSString class]] ? dictionary[@"opt"] : @"push";
    request.path = [dictionary[@"path"] isKindOfClass:[NSString class]] ? dictionary[@"path"] : @"";
    request.animated = [dictionary[@"animated"] isKindOfClass:[NSNumber class]]
                           ? ((NSNumber *)dictionary[@"animated"]).boolValue
                           : YES;
    request.title = [dictionary[@"title"] isKindOfClass:[NSString class]] ? dictionary[@"title"] : @"";
    request.statusBarHidden = [dictionary[@"statusBarHidden"] isKindOfClass:[NSNumber class]]
                                  ? [dictionary[@"statusBarHidden"] boolValue]
                                  : NO;
    request.navigationBarHidden = [dictionary[@"navigationBarHidden"] isKindOfClass:[NSNumber class]]
                                      ? [dictionary[@"navigationBarHidden"] boolValue]
                                      : NO;
    request.args = [dictionary[@"args"] isKindOfClass:[NSDictionary class]] ? dictionary[@"args"] : @{};
    return [self buildWithRequest:request];
}

@end
