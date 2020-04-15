#include <RemoteLog.h>
#include "Tweak.h"

UIImage *newImage;
CALayer *LSLayer;

BOOL kUseEntireWeatherView;
BOOL kUseWeatherEffectsOnly;

%hook SBFWallpaperView

-(void)didMoveToWindow {
	%orig;
	if (kUseEntireWeatherView) {
		((UIImageView *)self.contentView).image = newImage;	
	}
	else if (kUseWeatherEffectsOnly) {
		[self.contentView.layer addSublayer:LSLayer];
	}
}

%end

%hook SBFStaticWallpaperView 

%property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
%property (nonatomic, strong) City *myCity; 

- (void)didMoveToWindow {
	%orig;
	if (self.bgView == nil) {
		// If you want to get the weather from the user defaults (might not always have correct info sadly)
		/*if ([[[%c(WeatherPreferences) userDefaultsPersistence] objectForKey:@"Cities"] count] > 0) {
			id prefsCityDict = [[%c(WeatherPreferences) userDefaultsPersistence] objectForKey:@"Cities"][0];
			if (prefsCityDict != nil) {
				self.myCity = [[%c(WeatherPreferences) sharedPreferences] cityFromPreferencesDictionary:prefsCityDict];
				
				[[%c(TWCCityUpdater) sharedCityUpdater] updateWeatherForCity:self.myCity];
			}
		}*/

		WeatherPreferences *wPrefs = [%c(WeatherPreferences) sharedPreferences];
		WATodayAutoupdatingLocationModel *todayUpdateModel = [%c(WATodayAutoupdatingLocationModel) autoupdatingLocationModelWithPreferences:wPrefs effectiveBundleIdentifier:@"com.apple.weather"];
		[todayUpdateModel setLocationServicesActive:YES];
		[todayUpdateModel setIsLocationTrackingEnabled:YES];

		[todayUpdateModel executeModelUpdateWithCompletion:^(BOOL arg1, NSError *arg2) {
			if (todayUpdateModel.forecastModel.city) {
				self.myCity = todayUpdateModel.forecastModel.city;
				[todayUpdateModel setIsLocationTrackingEnabled:NO];
			}
		}];

		if (self.myCity != nil) {
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
				CALayer *nLayer = self.bgView.condition.layer;
				nLayer.bounds = UIScreen.mainScreen.nativeBounds;
				nLayer.allowsGroupOpacity = YES;
				nLayer.position = CGPointMake(0, UIScreen.mainScreen.bounds.size.height);
				nLayer.geometryFlipped = YES;
				[self.layer addSublayer:nLayer];
				LSLayer = [[CALayer alloc] initWithLayer:nLayer];
			}
		}
	}
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
		//RLog(@"entire: %d, effect: %d", kUseEntireWeatherView, kUseWeatherEffectsOnly);
	}
}