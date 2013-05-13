//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STAPNSimulator.h"

#import <objc/runtime.h>


static uint8_t STAPNSimulatorDeviceTokenBytes[32] = { 0 };

static void const * const STAPNSimulatorApplication_apnsimulator = &STAPNSimulatorApplication_apnsimulator;


static id (*UIApplication_init)(id self, SEL _cmd) = NULL;
static id STAPNSimulatorApplication_init(UIApplication *self, SEL _cmd) {
	if ((self = UIApplication_init(self, _cmd))) {
		STAPNSimulator *apnsimulator = [[STAPNSimulator alloc] initWithApplication:self];
		objc_setAssociatedObject(self, STAPNSimulatorApplication_apnsimulator, apnsimulator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
	}
	return self;
}


static id (*UIApplication_registerForRemoteNotificationTypes)(id self, SEL _cmd, UIRemoteNotificationType types) = NULL;
static id STAPNSimulatorApplication_registerForRemoteNotificationTypes(id self, SEL _cmd, UIRemoteNotificationType types) {
	STAPNSimulator * const apnsimulator = objc_getAssociatedObject(self, STAPNSimulatorApplication_apnsimulator);
	id<UIApplicationDelegate> const delegate = [self delegate];
	[apnsimulator setEnabledRemoteNotificationTypes:types];
	if ([delegate respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)]) {
		NSData * const deviceToken = [[NSData alloc] initWithBytesNoCopy:STAPNSimulatorDeviceTokenBytes length:sizeof(STAPNSimulatorDeviceTokenBytes) freeWhenDone:NO];
		dispatch_async(dispatch_get_main_queue(), ^{
			[delegate application:self didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
		});
	}
	return nil;
}


static UIRemoteNotificationType (*UIApplication_enabledRemoteNotificationTypes)(id self, SEL _cmd) = NULL;
static UIRemoteNotificationType STAPNSimulatorApplication_enabledRemoteNotificationTypes(UIApplication *self, SEL _cmd) {
	STAPNSimulator * const apnsimulator = objc_getAssociatedObject(self, STAPNSimulatorApplication_apnsimulator);
	return [apnsimulator enabledRemoteNotificationTypes];
}


BOOL STAPNSimulatorInject(void) {
	NSLog(@"STAPNSimulator: injecting");

	Class UIApplicationClass = [UIApplication class];

	Method applicationInitMethod = class_getInstanceMethod(UIApplicationClass, @selector(init));
	UIApplication_init = (__typeof__(UIApplication_init))method_setImplementation(applicationInitMethod, (IMP)STAPNSimulatorApplication_init);

	Method applicationRegisterForRemoteNotificationTypesMethod = class_getInstanceMethod(UIApplicationClass, @selector(registerForRemoteNotificationTypes:));
	UIApplication_registerForRemoteNotificationTypes = (__typeof__(UIApplication_registerForRemoteNotificationTypes))method_setImplementation(applicationRegisterForRemoteNotificationTypesMethod, (IMP)STAPNSimulatorApplication_registerForRemoteNotificationTypes);

	Method applicationEnabledRemoteNotificationTypesMethod = class_getInstanceMethod(UIApplicationClass, @selector(enabledRemoteNotificationTypes));
	UIApplication_enabledRemoteNotificationTypes = (__typeof__(UIApplication_enabledRemoteNotificationTypes))method_setImplementation(applicationEnabledRemoteNotificationTypesMethod, (IMP)STAPNSimulatorApplication_enabledRemoteNotificationTypes);

	return YES;
}
