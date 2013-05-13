//  Copyright (c) 2013 Scott Talbot. All rights reserved.

#import "STAPNSimulatorExampleViewController.h"


@interface STAPNSimulatorNotificationCell : UITableViewCell
- (void)setNotificationText:(NSString *)text;
+ (CGFloat)heightForWidth:(CGFloat)width withNotificationText:(NSString *)text;
@end
@implementation STAPNSimulatorNotificationCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier])) {
		UIView * const contentView = self.contentView;
		UILabel * const textLabel = self.textLabel;
		textLabel.numberOfLines = 0;
		textLabel.font = [UIFont systemFontOfSize:12];
		textLabel.frame = CGRectInset(contentView.bounds, 10, 10);
		textLabel.autoresizingMask = UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleHeight;
	}
	return self;
}
- (void)setNotificationText:(NSString *)text {
	self.textLabel.text = text;
}
- (void)prepareForReuse {
	[super prepareForReuse];
	self.textLabel.text = nil;
}
+ (CGFloat)heightForWidth:(CGFloat)width withNotificationText:(NSString *)text {
	UIFont *font = [UIFont systemFontOfSize:12];
	CGSize textSize = [text sizeWithFont:font constrainedToSize:(CGSize){ .width = width - 20, .height = INFINITY }  lineBreakMode:NSLineBreakByWordWrapping];
	return textSize.height + 20;
}
@end

@interface STAPNSimulatorExampleViewController () <UITableViewDataSource,UITableViewDelegate>
@property (nonatomic,weak,readonly) id<STAPNSimulatorExampleDelegate> delegate;
@property (nonatomic,weak) IBOutlet UISwitch *badgeSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *alertSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *soundSwitch;
@property (nonatomic,weak) IBOutlet UISwitch *contentavailableSwitch;
@property (nonatomic,weak) IBOutlet UITableView *tableView;
@end

@implementation STAPNSimulatorExampleViewController {
@private
	NSMutableArray *_notifications;
}

+ (instancetype)viewControllerWithDelegate:(id<STAPNSimulatorExampleDelegate>)delegate {
	return [[self alloc] initWithNibName:nil bundle:nil delegate:delegate];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	return [self initWithNibName:nibNameOrNil bundle:nibBundleOrNil delegate:nil];
}
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil delegate:(id<STAPNSimulatorExampleDelegate>)delegate {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
		_delegate = delegate;

		self.title = @"APNSimulator";

		_notifications = [[NSMutableArray alloc] init];
    }
    return self;
}


- (void)viewDidLoad {
	[super viewDidLoad];

	UIRemoteNotificationType const enabledNotificationTypes = self.enabledNotificationTypes;

	UISwitch * const badgeSwitch = self.badgeSwitch;
	UISwitch * const alertSwitch = self.alertSwitch;
	UISwitch * const soundSwitch = self.soundSwitch;
	UISwitch * const contentavailableSwitch = self.contentavailableSwitch;

	[badgeSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeBadge];
	[alertSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeAlert];
	[soundSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeSound];
	[contentavailableSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeNewsstandContentAvailability];

	[badgeSwitch addTarget:self action:@selector(switchValueChanged) forControlEvents:UIControlEventValueChanged];
	[alertSwitch addTarget:self action:@selector(switchValueChanged) forControlEvents:UIControlEventValueChanged];
	[soundSwitch addTarget:self action:@selector(switchValueChanged) forControlEvents:UIControlEventValueChanged];
	[contentavailableSwitch addTarget:self action:@selector(switchValueChanged) forControlEvents:UIControlEventValueChanged];

	UITableView * const tableView = self.tableView;
	tableView.dataSource = self;
	tableView.delegate = self;

	[tableView registerClass:[STAPNSimulatorNotificationCell class] forCellReuseIdentifier:@"c"];
}


- (void)switchValueChanged {
	id<STAPNSimulatorExampleDelegate> const delegate = self.delegate;
	UISwitch * const badgeSwitch = self.badgeSwitch;
	UISwitch * const alertSwitch = self.alertSwitch;
	UISwitch * const soundSwitch = self.soundSwitch;
	UISwitch * const contentavailableSwitch = self.contentavailableSwitch;

	UIRemoteNotificationType notificationTypes = UIRemoteNotificationTypeNone;
	if ([badgeSwitch isOn]) {
		notificationTypes |= UIRemoteNotificationTypeBadge;
	}
	if ([alertSwitch isOn]) {
		notificationTypes |= UIRemoteNotificationTypeAlert;
	}
	if ([soundSwitch isOn]) {
		notificationTypes |= UIRemoteNotificationTypeSound;
	}
	if ([contentavailableSwitch isOn]) {
		notificationTypes |= UIRemoteNotificationTypeNewsstandContentAvailability;
	}
	[delegate apnsimulatorExample:self registerForRemoteNotificationTypes:notificationTypes];
}

- (void)setEnabledNotificationTypes:(UIRemoteNotificationType)enabledNotificationTypes {
	UISwitch * const badgeSwitch = self.badgeSwitch;
	UISwitch * const alertSwitch = self.alertSwitch;
	UISwitch * const soundSwitch = self.soundSwitch;
	UISwitch * const contentavailableSwitch = self.contentavailableSwitch;

	_enabledNotificationTypes = enabledNotificationTypes;

	[badgeSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeBadge animated:YES];
	[alertSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeAlert animated:YES];
	[soundSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeSound animated:YES];
	[contentavailableSwitch setOn:enabledNotificationTypes & UIRemoteNotificationTypeNewsstandContentAvailability animated:YES];
}


- (void)didReceiveNotification:(NSDictionary *)userInfo {
	UITableView * const tableView = self.tableView;

	[_notifications insertObject:[userInfo copy] atIndex:0];
	[tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
}


#pragma mark - UITableViewDataSource/UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (NSInteger)[_notifications count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary * const notification = [_notifications objectAtIndex:(NSUInteger)indexPath.row];
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:notification options:NSJSONWritingPrettyPrinted error:nil];
	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	return [STAPNSimulatorNotificationCell heightForWidth:tableView.bounds.size.width withNotificationText:jsonString];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSDictionary * const notification = [_notifications objectAtIndex:(NSUInteger)indexPath.row];
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:notification options:NSJSONWritingPrettyPrinted error:nil];
	NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];

	STAPNSimulatorNotificationCell *cell = [tableView dequeueReusableCellWithIdentifier:@"c" forIndexPath:indexPath];
	[cell setNotificationText:jsonString];

	return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	return 0.00001f;
}

@end
