//  This Source Code Form is subject to the terms of the Mozilla Public
//  License, v. 2.0. If a copy of the MPL was not distributed with this
//  file, You can obtain one at http://mozilla.org/MPL/2.0/.
//
//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STAPNSimulator.h"
#import "STAPNSimulatorInjection.h"

#import <sys/socket.h>
#import <arpa/inet.h>


void __attribute__((constructor)) STAPNSimulatorLoad(void) {
	char *env = getenv("STAPNSIMULATOR");
	if (env && env[0] == '1') {
		STAPNSimulatorInject();
	}
}


static void STAPNSimulatorCFSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info);

static NSDictionary *NSDictionaryBySanitizingWithRemoteNotificationTypes(NSDictionary *dict, UIRemoteNotificationType remoteNotificationTypes);


@interface STAPNSimulator ()
@property (nonatomic,weak,readonly) UIApplication *application;
- (void)socketDidReceiveData:(NSData *)data;
@end

@implementation STAPNSimulator {
@private
	CFSocketRef _socket;
	CFRunLoopRef _runLoop;
	CFRunLoopSourceRef _socketRunLoopSource;
	NSNetService *_service;
}

- (id)init {
	return [self initWithApplication:nil];
}
- (id)initWithApplication:(UIApplication *)application {
	if ((self = [super init])) {
		_application = application;

		CFSocketContext ctx = {
			.version = 0,
			.info = (__bridge void *)self,
			.retain = NULL,
			.release = NULL,
			.copyDescription = CFCopyDescription,
		};

		{
			struct sockaddr_in6 addr = {
				.sin6_len = INET6_ADDRSTRLEN,
				.sin6_family = AF_INET6,
			};
			CFDataRef address = CFDataCreateWithBytesNoCopy(NULL, (void *)&addr, sizeof(addr), kCFAllocatorNull);
			CFSocketSignature signature = {
				.protocolFamily = PF_INET6,
				.socketType = SOCK_DGRAM,
				.protocol = IPPROTO_UDP,
				.address = address,
			};
			_socket = CFSocketCreateWithSocketSignature(NULL, &signature, kCFSocketDataCallBack, STAPNSimulatorCFSocketCallBack, &ctx);
			CFRelease(address);
		}

		int port = 0;
		{
			CFDataRef address = CFSocketCopyAddress(_socket);
			if (address) {
				struct sockaddr_in6 *addr = (void *)CFDataGetBytePtr(address);
				port = ntohs(addr->sin6_port);
				CFRelease(address);
			}
		}

		if (port) {
			CFRetain(_runLoop = CFRunLoopGetCurrent());
			_socketRunLoopSource = CFSocketCreateRunLoopSource(NULL, _socket, 0);
			CFRunLoopAddSource(_runLoop, _socketRunLoopSource, kCFRunLoopCommonModes);

			NSString * const bundleIdentifier = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleIdentifierKey];

			_service = [[NSNetService alloc] initWithDomain:@"" type:@"_apnsimulator._udp" name:bundleIdentifier port:port];
			[_service publishWithOptions:0];
		}
	}
	return self;
}

- (void)dealloc {
	[_service stop];
	if (_runLoop) {
		CFRunLoopRemoveSource(_runLoop, _socketRunLoopSource, kCFRunLoopDefaultMode);
		CFRelease(_runLoop);
	}
	if (_socket) {
		CFSocketInvalidate(_socket);
		CFRelease(_socket);
	}
}


- (void)socketDidReceiveData:(NSData *)data {
	UIApplication * const application = self.application;
	id<UIApplicationDelegate> const applicationDelegate = application.delegate;
	if (![applicationDelegate respondsToSelector:@selector(application:didReceiveRemoteNotification:)]) {
		return;
	}

	NSError *error = nil;
	id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
	if (!object) {
		return;
	}
	if (![object isKindOfClass:[NSDictionary class]]) {
		return;
	}

	NSDictionary *userInfo = (NSDictionary *)object;
	NSDictionary *sanitizedUserInfo = NSDictionaryBySanitizingWithRemoteNotificationTypes(userInfo, _enabledRemoteNotificationTypes);
	[applicationDelegate application:application didReceiveRemoteNotification:sanitizedUserInfo];
}

@end


static void STAPNSimulatorCFSocketCallBack(CFSocketRef s, CFSocketCallBackType type, CFDataRef address, const void *data, void *info) {
	STAPNSimulator *apnsimulator = (__bridge STAPNSimulator *)info;
	[apnsimulator socketDidReceiveData:(__bridge NSData *)data];
}


static NSDictionary *NSDictionaryBySanitizingWithRemoteNotificationTypes(NSDictionary *dict, UIRemoteNotificationType remoteNotificationTypes) {
	NSMutableDictionary *sanitizedAps = [dict[@"aps"] mutableCopy];
	if (!(remoteNotificationTypes & UIRemoteNotificationTypeBadge)) {
		[sanitizedAps removeObjectForKey:@"badge"];
	}
	if (!(remoteNotificationTypes & UIRemoteNotificationTypeAlert)) {
		[sanitizedAps removeObjectForKey:@"alert"];
	}
	if (!(remoteNotificationTypes & UIRemoteNotificationTypeSound)) {
		[sanitizedAps removeObjectForKey:@"sound"];
	}
	if (!(remoteNotificationTypes & UIRemoteNotificationTypeNewsstandContentAvailability)) {
		[sanitizedAps removeObjectForKey:@"content-available"];
	}

	NSMutableDictionary *sanitizedDict = [[NSMutableDictionary alloc] initWithDictionary:dict copyItems:YES];
	if (sanitizedAps) {
		sanitizedDict[@"aps"] = sanitizedAps;
	}

	return sanitizedDict;
}
