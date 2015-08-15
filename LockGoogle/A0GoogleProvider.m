// A0GoogleProvider.m
//
// Copyright (c) 2015 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "A0GoogleProvider.h"
#import <Google/SignIn.h>
#import <Lock/A0Errors.h>

@interface A0GoogleProvider () <GIDSignInDelegate, GIDSignInUIDelegate>
@property (strong, nonatomic) GIDSignIn *authentication;
@property (copy, nonatomic) A0GoogleAuthentication onAuthentication;
@end

@implementation A0GoogleProvider

- (instancetype)initWithClientId:(NSString *)clientId scopes:(NSArray *)scopes {
    GIDSignIn *authentication = [GIDSignIn sharedInstance];
    return [self initWithAuthentication:authentication clientId:clientId scopes:scopes];
}

- (instancetype)initWithAuthentication:(GIDSignIn *)authentication clientId:(NSString *)clientId scopes:(NSArray *)scopes {
    self = [super init];
    if (self) {
        authentication.clientID = clientId;
        authentication.scopes = scopes;
        authentication.delegate = self;
        authentication.uiDelegate = self;
        authentication.allowsSignInWithWebView = YES;
        _authentication = authentication;
        _onAuthentication = ^(NSError *error, NSString *token) {};
    }
    return self;
}

- (void)authenticateWithScopes:(nullable NSArray *)scopes callback:(A0GoogleAuthentication __nonnull)callback {
    if (scopes.count > 0) {
        self.authentication.scopes = scopes;
    }
    self.onAuthentication = callback;
    [self.authentication signIn];
}

- (void)cancelAuthentication {
    self.onAuthentication([A0Errors googleplusCancelled], nil);
    self.onAuthentication = ^(NSError *error, NSString *token) {};
}

- (BOOL)handleURL:(NSURL * __nonnull)url sourceApplication:(NSString * __nonnull)sourceApplication {
    return [self.authentication handleURL:url sourceApplication:sourceApplication annotation:nil];
}

- (void)clearSession {
    [self.authentication signOut];
}

#pragma mark - GPPSignInDelegate

- (void)signIn:(GIDSignIn *)signIn didSignInForUser:(GIDGoogleUser *)user withError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            self.onAuthentication(error, nil);
        } else {
            self.onAuthentication(nil, user.authentication.accessToken);
        }
        self.onAuthentication = ^(NSError *error, NSString *token) {};
    });
}

#pragma mark - GIDSignInUIDelegate

- (void)signIn:(GIDSignIn *)signIn presentViewController:(UIViewController *)viewController {
    [[self presenterViewController] presentViewController:viewController animated:YES completion:nil];
}

- (void)signIn:(GIDSignIn *)signIn dismissViewController:(UIViewController *)viewController {
    [viewController.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma Utility methods

- (UIViewController *)presenterViewController {
    UIViewController* viewController = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findBestViewController:viewController];
}

- (UIViewController*) findBestViewController:(UIViewController*)controller {
    if (controller.presentedViewController) {
        return [self findBestViewController:controller.presentedViewController];
    } else if ([controller isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController* splitViewController = (UISplitViewController*) controller;
        if (splitViewController.viewControllers.count > 0) {
            return [self findBestViewController:splitViewController.viewControllers.lastObject];
        } else {
            return controller;
        }
    } else if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController* navigationController = (UINavigationController*) controller;
        if (navigationController.viewControllers.count > 0) {
            return [self findBestViewController:navigationController.topViewController];
        } else {
            return controller;
        }
    } else if ([controller isKindOfClass:[UITabBarController class]]) {
        UITabBarController* tabBarController = (UITabBarController*) controller;
        if (tabBarController.viewControllers.count > 0) {
            return [self findBestViewController:tabBarController.selectedViewController];
        } else {
            return controller;
        }
    } else {
        return controller;
    }
}

@end
