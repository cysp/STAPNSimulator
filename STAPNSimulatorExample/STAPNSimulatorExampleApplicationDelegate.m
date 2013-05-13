//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STAPNSimulatorExampleApplicationDelegate.h"

#import "STAPNSimulatorExampleViewController.h"


@interface STAPNSimulatorExampleApplicationDelegate () <STAPNSimulatorExampleDelegate>
@end

@implementation STAPNSimulatorExampleApplicationDelegate {
@private
	STAPNSimulatorExampleViewController *_viewController;
}

- (void)setWindow:(UIWindow *)window {
	_window = window;
	[_window makeKeyAndVisible];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UIWindow *window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    window.backgroundColor = [UIColor blackColor];
	self.window = window;

	_viewController = [STAPNSimulatorExampleViewController viewControllerWithDelegate:self];
	[_viewController setEnabledNotificationTypes:[application enabledRemoteNotificationTypes]];

	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_viewController];
	window.rootViewController = navController;

	[application registerForRemoteNotificationTypes:UIRemoteNotificationTypeBadge|UIRemoteNotificationTypeAlert];

    return YES;
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[_viewController setEnabledNotificationTypes:application.enabledRemoteNotificationTypes];
}
- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
	[_viewController setEnabledNotificationTypes:UIRemoteNotificationTypeNone];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	[_viewController didReceiveNotification:userInfo];
}


#pragma mark - STAPNSimulatorExampleDelegate

- (void)apnsimulatorExample:(STAPNSimulatorExampleViewController *)viewController registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes {
	[[UIApplication sharedApplication] registerForRemoteNotificationTypes:remoteNotificationTypes];
}

@end
