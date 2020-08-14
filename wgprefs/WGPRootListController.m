#include "WGPRootListController.h"
#include <spawn.h>

@implementation WGPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Apply" style:UIBarButtonItemStylePlain target:self action:@selector(respring)];
	self.navigationItem.rightBarButtonItem = applyButton;
}

- (void)respring {
	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Apply Settings"
								   message:@"Are you sure you want to respring?"
								   preferredStyle:UIAlertControllerStyleAlert];
	 
	UIAlertAction* respringAction = [UIAlertAction actionWithTitle:@"Respring" style:UIAlertActionStyleDestructive
	   handler:^(UIAlertAction * action) {
		pid_t pid;
		int status;

		const char *args[] = {"sbreload", NULL, NULL, NULL};
		posix_spawn(&pid, "usr/bin/sbreload", NULL, NULL, (char *const *)args, NULL);
		waitpid(pid, &status, WEXITED);
	}];
	UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
	handler:^(UIAlertAction * action) {}];
	 
	[alert addAction:respringAction];
	[alert addAction:cancelAction];
	
	[self presentViewController:alert animated:YES completion:nil];
}

- (id)readPreferenceValue:(PSSpecifier*)specifier {
	id result;
	
	NSDictionary *weatherGroundSettingsDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tr1fecta.wgprefs.plist"];
		
	if (!weatherGroundSettingsDict[specifier.properties[@"key"]]) {
		// Preference doesn't have a value (unset), so fetch the default.
		result = specifier.properties[@"default"];
	}
	else {
		// Fetch the preference value
		result = weatherGroundSettingsDict[specifier.properties[@"key"]];
	}
	return result;
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	NSString *nsPreferencesPath = @"/var/mobile/Library/Preferences/com.tr1fecta.wgprefs.plist";
	
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:nsPreferencesPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:nsPreferencesPath atomically:YES];

	/*// Send Notification (via Darwin) if one is specified for the preference value.
	// This will notify the Tweak (.xm) that the preference value changed.
	CFStringRef toPost = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
	if (toPost) {
		CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
	}*/
}

@end
