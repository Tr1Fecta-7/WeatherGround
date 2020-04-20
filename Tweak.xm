#include <RemoteLog.h>
#include <time.h>
#include "Tweak.h"

UIImage *newImage;
CALayer *LSLayer;

BOOL kTweakEnabled;
BOOL kUseEntireWeatherView;
BOOL kUseWeatherEffectsOnly;
BOOL kEnableStatusBarTemperature;
NSString *kTemperatureUnit;

//BOOL kLockscreenEnabled;
//BOOL kHomescreenEnabled;

%hook SBIconImageView

%property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = %orig)) {
	}
	return self;
}

- (void)didMoveToWindow {
	%orig;

	if ([((SBLeafIcon *)self.icon).applicationBundleID isEqualToString:@"com.apple.weather"]) {
		/*RLog(@"make weather icon");
		UIImage *image = [WeatherImageLoader conditionImageWithConditionIndex:30 style:0];
		UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
		imgView.backgroundColor = UIColor.clearColor;
		imgView.frame = self.frame;
		[self addSubview:imgView];*/
		RLog(@"name: %@", ((SBLeafIcon *)self.icon).applicationBundleID);
	}
}


%end

%hook SBFWallpaperView

-(void)didMoveToWindow {
	%orig;

	if (kUseEntireWeatherView) {
		if ([((UIImageView *)self.contentView) respondsToSelector:@selector(setImage:)]) {
			((UIImageView *)self.contentView).image = newImage;	
		}
	}	
	else if (kUseWeatherEffectsOnly) {
		[self.contentView.layer addSublayer:LSLayer];
	}
}

%end

%group TimeStatusBar

%hook _UIStatusBarStringView 

- (instancetype)initWithFrame:(CGRect)frame {
	if ((self = %orig)) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(setTemperatureWithNotification:) name:@"wgSetTemperatureNotification" object:nil];
	}
	return self;
}

%new
- (void)setTemperatureWithNotification:(NSNotification *)notification {
	if ([notification.name isEqualToString:@"wgSetTemperatureNotification"]) {
		NSMutableAttributedString *temperatureAttrString = [[[WeatherGroundServer sharedServer] temperatureInfo:kTemperatureUnit] objectForKey:@"weatherString"];
		[self changeLabelTextWithAttributedString:temperatureAttrString];
			
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			// Get current local time
			time_t curtime;
			struct tm *timeInfo;
			time(&curtime);
			timeInfo = localtime(&curtime);

			char currentTime[8];
			// Get the hour and minute out of our timeInfo struct
			strftime(currentTime, 8, "%H:%M", timeInfo);
				[self changeLabelText:[[NSString alloc] initWithUTF8String:currentTime]];
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

%end // End of TimeStatusBar

%hook _UIStatusBarForegroundView

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
	%orig;
	CGPoint location = [[[event allTouches] anyObject] locationInView:self];
	if (location.x <= 105.0) {
		if (kEnableStatusBarTemperature) {
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
			[[NSNotificationCenter defaultCenter] postNotificationName:@"wgSetTemperatureNotification" object:nil userInfo:nil];
		}
		
	}
}
%end

%hook SBFStaticWallpaperView 

%property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 

- (instancetype)initWithFrame:(CGRect)arg1 configuration:(id)arg2 variant:(long long)arg3 cacheGroup:(id)arg4 delegate:(id)arg5 options:(unsigned long long)arg6 {
	if ((self = %orig)) {
		
	}
	return self;
}

- (void)didMoveToWindow {
	%orig;

	RLog(@"did move to window");

	if (self.bgView == nil) {

		self.bgView = [[%c(WUIDynamicWeatherBackground) alloc] initWithFrame:self.frame];
		self.bgView.city = [[WeatherGroundServer sharedServer] myCity];
		self.bgView.condition.city = [[WeatherGroundServer sharedServer] myCity];

		if (kUseEntireWeatherView) {
			[self addSubview:self.bgView];
			UIGraphicsBeginImageContextWithOptions(self.bgView.bounds.size, NO, UIScreen.mainScreen.scale);
			[self.bgView drawViewHierarchyInRect:self.bgView.bounds afterScreenUpdates:YES];
			newImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();
		}
		else if (kUseWeatherEffectsOnly) {
			CALayer *nLayer = [self weatherEffectsLayer];
			[self.layer addSublayer:nLayer];
			LSLayer = [[CALayer alloc] initWithLayer:nLayer];
		}
	}
}

%new
- (CALayer *)weatherEffectsLayer {
	CALayer *nLayer = self.bgView.condition.layer;
	nLayer.bounds = UIScreen.mainScreen.nativeBounds;
	nLayer.allowsGroupOpacity = YES;
	nLayer.position = CGPointMake(0, UIScreen.mainScreen.bounds.size.height);
	nLayer.geometryFlipped = YES;

	return nLayer;
}
%end


%ctor {
	NSBundle *wUIBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/WeatherUI.framework"];
	NSBundle *wBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/Weather.framework"];
	if (!wUIBundle.loaded) {
		[wUIBundle load];
	}
	if (!wBundle.loaded) {
		[wBundle load];
	}

	NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tr1fecta.wgprefs.plist"];
	//RLog(@"plist %@", plistDict);
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
			%init;

			[WeatherGroundServer sharedServer];
			
		}
		
	}
}