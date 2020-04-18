#include <RemoteLog.h>
#include <time.h>
#include "Tweak.h"

UIImage *newImage;
CALayer *LSLayer;

BOOL kUseEntireWeatherView;
BOOL kUseWeatherEffectsOnly;
BOOL kEnableStatusBarTemperature;
NSString *kTemperatureUnit;

//BOOL kLockscreenEnabled;
//BOOL kHomescreenEnabled;

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
		NSDictionary *tempDict  = notification.userInfo;
		
		if (tempDict != nil) {
			id celsiusObj = [tempDict objectForKey:@"currentTemperature"];
			NSString *temperature = celsiusObj ? [NSString stringWithFormat:@"%@°", [celsiusObj stringValue]] : @"ERROR";

			[self changeLabelText:temperature];
			
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
		[[NSNotificationCenter defaultCenter] postNotificationName:@"wgNeedTemperatureNotification" object:nil];
	}
}

%end

%hook SBFStaticWallpaperView 

%property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
%property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayUpdateModel;
%property (nonatomic, strong) City *myCity; 

- (instancetype)initWithFrame:(CGRect)arg1 configuration:(id)arg2 variant:(long long)arg3 cacheGroup:(id)arg4 delegate:(id)arg5 options:(unsigned long long)arg6 {
	if ((self = %orig)) {
		if (kEnableStatusBarTemperature) {
			[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(getTemperatureAndPost) name:@"wgNeedTemperatureNotification" object:nil];
		}
		
	}
	return self;
}

- (void)didMoveToWindow {
	%orig;
	if (self.bgView == nil) {
		[self updateModel];
		
		if (self.myCity != nil && self.todayUpdateModel != nil) {
			self.bgView = [[%c(WUIDynamicWeatherBackground) alloc] initWithFrame:self.frame];
			self.bgView.city = self.myCity;
			self.bgView.condition.city = self.myCity;

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
}

%new
- (void)updateModel {
	WeatherPreferences *wPrefs = [%c(WeatherPreferences) sharedPreferences];
	self.todayUpdateModel = [%c(WATodayAutoupdatingLocationModel) autoupdatingLocationModelWithPreferences:wPrefs effectiveBundleIdentifier:@"com.apple.weather"];
	[self.todayUpdateModel setLocationServicesActive:YES];
	[self.todayUpdateModel setIsLocationTrackingEnabled:YES];

	[self.todayUpdateModel executeModelUpdateWithCompletion:^(BOOL arg1, NSError *arg2) {
		if (self.todayUpdateModel.forecastModel.city) {
			self.myCity = self.todayUpdateModel.forecastModel.city;
			[self.todayUpdateModel setIsLocationTrackingEnabled:NO];
		}
	}];
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

%new 
- (void)getTemperatureAndPost {
	[self updateModel];
	int temperature;

	if ([kTemperatureUnit isEqualToString:@"celsius"]) {
		temperature = (int)self.myCity.temperature.celsius;
	}
	else if ([kTemperatureUnit isEqualToString:@"fahrenheit"]) {
		temperature = (int)self.myCity.temperature.fahrenheit;
	}
	else if ([kTemperatureUnit isEqualToString:@"kelvin"])  {
		temperature = (int)self.myCity.temperature.kelvin;
	}
	else {
		temperature = 0;
	}

	NSDictionary *userInfoDict = @{@"currentTemperature": @(temperature)};
	[[NSNotificationCenter defaultCenter] postNotificationName:@"wgSetTemperatureNotification" object:nil userInfo:userInfoDict];
}

%end


%ctor {
	NSBundle *wBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/WeatherUI.framework"];
	if (!wBundle.loaded) {
		[wBundle load];
	}

	NSDictionary *plistDict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tr1fecta.wgprefs.plist"];
	//RLog(@"plist %@", plistDict);
	if (plistDict != nil) {
		kUseEntireWeatherView = [plistDict objectForKey:@"kUseEntireWeatherView"] ? [[plistDict objectForKey:@"kUseEntireWeatherView"] boolValue] : NO;
		kUseWeatherEffectsOnly = [plistDict objectForKey:@"kUseWeatherEffectsOnly"] ? [[plistDict objectForKey:@"kUseWeatherEffectsOnly"] boolValue] : NO;
		kEnableStatusBarTemperature = [plistDict objectForKey:@"kEnableStatusBarTemperature"] ? [[plistDict objectForKey:@"kEnableStatusBarTemperature"] boolValue] : NO;
		kTemperatureUnit = [plistDict objectForKey:@"kTemperatureUnit"] ? [[plistDict objectForKey:@"kTemperatureUnit"] stringValue] : @"celsius";

		if (kEnableStatusBarTemperature) {
			%init(TimeStatusBar);
		}
		%init;
	}
}