//#include <RemoteLog.h>
#include <time.h>
#include "Tweak.h"

BOOL kTweakEnabled;
BOOL kUseEntireWeatherView;
BOOL kUseWeatherEffectsOnly;
BOOL kEnableStatusBarTemperature;
NSString *kTemperatureUnit;

%group TimeStatusBar

%hook _UIStatusBarStringView 

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = %orig)) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTemperatureWithNotification:) name:@"wgSetTemperatureNotification" object:nil];
	}
	return self;
}

- (void)didMoveToWindow {
	%orig;
	
	if ([[self _viewControllerForAncestor] isKindOfClass:%c(SBMainDisplaySceneLayoutViewController)] && kEnableStatusBarTemperature) {
		// Set the status string view for the status bar in apps
		[[WeatherGroundServer sharedServer] setStatusStringView:self];
	}
}

%new
- (void)setTemperatureWithNotification:(NSNotification *)notification {
	if ([notification.name isEqualToString:@"wgSetTemperatureNotification"]) {
		NSMutableAttributedString *temperatureAttrString = [[[WeatherGroundServer sharedServer] temperatureInfo:kTemperatureUnit] objectForKey:@"weatherString"];
		[self changeLabelTextWithAttributedString:temperatureAttrString];

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
			[formatter setLocale:[NSLocale currentLocale]];
    		[formatter setTimeStyle:NSDateFormatterShortStyle];
			
			NSRange amRange = [[formatter stringFromDate:[NSDate now]] rangeOfString:[formatter AMSymbol]];
			NSRange pmRange = [[formatter stringFromDate:[NSDate now]] rangeOfString:[formatter PMSymbol]];
			
			BOOL is24h = (amRange.location == NSNotFound && pmRange.location == NSNotFound);
			
			[formatter setDateFormat:is24h ? @"HH:mm" : @"hh:mm"];

			NSString *currentStatusTime = [formatter stringFromDate:[NSDate now]];

			self.attributedText = nil;
			[self changeLabelText:currentStatusTime];
		});
	}
}

%new 
- (void)changeLabelTextWithAttributedString:(NSMutableAttributedString *)text {
	CATransition *animation = [CATransition animation];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.type = kCATransitionPush;
	animation.subtype = kCATransitionFromTop;
	animation.duration = 0.3;
	[self.layer addAnimation:animation forKey:@"kCATransitionPush"];

	self.attributedText = text;
}

%new 
- (void)changeLabelText:(NSString *)text {
	CATransition *animation = [CATransition animation];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.type = kCATransitionPush;
	animation.subtype = kCATransitionFromTop;
	animation.duration = 0.3;
	[self.layer addAnimation:animation forKey:@"kCATransitionPush"];

	self.text = text;
}

%end

%hook _UIStatusBarForegroundView

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	%orig;
	CGPoint location = [[[event allTouches] anyObject] locationInView:self];
	if (location.x <= 105.0) {
		if (kEnableStatusBarTemperature) {
			// Handled in SpringBoard
			[[NSNotificationCenter defaultCenter] postNotificationName:@"wgSetTemperatureNotification" object:nil userInfo:nil];
		}
	}
}

%end

%hook UIStatusBarManager
// handled in applications
-(void)handleTapAction:(UIStatusBarTapAction *)tapAction {
	%orig;
	if (tapAction.type == 0 && tapAction.xPosition <= 105.0) {
		if (kEnableStatusBarTemperature) {
			MRYIPCCenter *center = [MRYIPCCenter centerNamed:@"com.tr1fecta.WeatherGroundServer"];
			[center callExternalVoidMethod:@selector(setStatusBarTextToWeatherInfo:) withArguments:@{@"unit": kTemperatureUnit}];
		}
	}
}
%end

%end // End of TimeStatusBar

%hook SBFWallpaperView

-(void)didMoveToWindow {
	%orig;

	if (kUseEntireWeatherView) {
		if ([((UIImageView *)self.contentView) respondsToSelector:@selector(setImage:)]) {
			((UIImageView *)self.contentView).image = [[WeatherGroundServer sharedServer] sharedImage];	
		}
	}	
}

%end

%hook LockScreenVC

-(void)viewDidLoad {
	%orig;

	// Setup the dynamic views and effect layers
	[[WeatherGroundServer sharedServer] updateModel];
	[[WeatherGroundServer sharedServer] setupDynamicWeatherBackgrounds];
	[[WeatherGroundServer sharedServer] setupWeatherEffectLayers];
	
}

%end

%hook SpringBoard 

- (void)frontDisplayDidChange:(SBApplication *)application {
	%orig;

	if (kTweakEnabled) {
		// If the display changed to an app, pause the view and resume it when in SpringBoard
		if (application) {
			[[WeatherGroundServer sharedServer] pauseWG];
		} else {
			[[WeatherGroundServer sharedServer] resumeWG];
		}
	}
	
}

%end

 
static void updateWGState(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[[WeatherGroundServer sharedServer] updateModel];

	BOOL screenOn = [[[%c(SBLockScreenManager) sharedInstance] valueForKey:@"_isScreenOn"] boolValue];
    if (screenOn) {
		[[WeatherGroundServer sharedServer] resumeWG];
    } else {
        [[WeatherGroundServer sharedServer] pauseWG];
    }
}


%ctor {
	// Code stolen from https://www.reddit.com/r/jailbreak/comments/4yz5v5/questionremote_messages_not_enabling/d6rlh88/ 
	// make sure it doesn't load in unneeded processes, otherwise respring loops :/
	BOOL shouldLoad = NO;
    NSArray *args = [[NSClassFromString(@"NSProcessInfo") processInfo] arguments];
    NSUInteger count = args.count;
    if (count != 0) {
        NSString *executablePath = args[0];
        if (executablePath) {
            NSString *processName = [executablePath lastPathComponent];
            BOOL isSpringBoard = [processName isEqualToString:@"SpringBoard"];
            BOOL isApplication = [executablePath rangeOfString:@"/Application/"].location != NSNotFound || [executablePath rangeOfString:@"/Applications/"].location != NSNotFound;
            BOOL isFileProvider = [[processName lowercaseString] rangeOfString:@"fileprovider"].location != NSNotFound;
            BOOL skip = [processName isEqualToString:@"AdSheet"]
                    || [processName isEqualToString:@"CoreAuthUI"]
                    || [processName isEqualToString:@"InCallService"]
                    || [processName isEqualToString:@"MessagesNotificationViewService"]
                    || [executablePath rangeOfString:@".appex/"].location != NSNotFound;
            if (!isFileProvider && (isSpringBoard || isApplication) && !skip) {
                shouldLoad = YES;
            }
        }
    }

	if (shouldLoad) {
		NSBundle *wUIBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/WeatherUI.framework"];
		NSBundle *wBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Weather.framework"];
		if (!wUIBundle.loaded) {
			[wUIBundle load];
		}
		if (!wBundle.loaded) {
			[wBundle load];
		}

		NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tr1fecta.wgprefs.plist"];
		if (plistDict != nil) {
			kTweakEnabled = [plistDict objectForKey:@"kTweakEnabled"] ? [[plistDict objectForKey:@"kTweakEnabled"] boolValue] : NO;
			kUseEntireWeatherView = [plistDict objectForKey:@"kUseEntireWeatherView"] ? [[plistDict objectForKey:@"kUseEntireWeatherView"] boolValue] : NO;
			kUseWeatherEffectsOnly = [plistDict objectForKey:@"kUseWeatherEffectsOnly"] ? [[plistDict objectForKey:@"kUseWeatherEffectsOnly"] boolValue] : NO;

			kEnableStatusBarTemperature = [plistDict objectForKey:@"kEnableStatusBarTemperature"] ? [[plistDict objectForKey:@"kEnableStatusBarTemperature"] boolValue] : NO;
			kTemperatureUnit = [plistDict objectForKey:@"kTemperatureUnit"] ? [[plistDict objectForKey:@"kTemperatureUnit"] stringValue] : @"celsius";
			
			if (kTweakEnabled) {
				if (kEnableStatusBarTemperature) {
					%init(TimeStatusBar);
				}

				if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
					Class LockScreenVCClass;
					if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"13.0")) {
						LockScreenVCClass = %c(CSCoverSheetViewController);
					} else {
						LockScreenVCClass = %c(SBDashBoardViewController);
					}
					%init(LockScreenVC=LockScreenVCClass);
				
					[WeatherGroundServer sharedServer];
					CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, updateWGState, CFSTR("com.apple.springboard.screenchanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
				}
			}
		}
	}
}