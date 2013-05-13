//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import <UIKit/UIKit.h>


@class STAPNSimulatorExampleViewController;


@protocol STAPNSimulatorExampleDelegate <NSObject>
- (void)apnsimulatorExample:(STAPNSimulatorExampleViewController *)viewController registerForRemoteNotificationTypes:(UIRemoteNotificationType)remoteNotificationTypes;
@end

@interface STAPNSimulatorExampleViewController : UIViewController
+ (instancetype)viewControllerWithDelegate:(id<STAPNSimulatorExampleDelegate>)delegate;
@property (nonatomic,assign) UIRemoteNotificationType enabledNotificationTypes;
- (void)didReceiveNotification:(NSDictionary *)userInfo;
@end
