#include <RemoteLog.h>
#include "Tweak.h"

UIImage *newImage;

%hook SBFWallpaperView

-(void)didMoveToWindow {
	%orig;
	((UIImageView *)self.contentView).image = newImage;	
}

%end

%hook SBFStaticWallpaperView 

%property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
%property (nonatomic, strong) City *myCity; 

- (void)didMoveToWindow {
	%orig;
	if (self.bgView == nil) {
		if ([[[%c(WeatherPreferences) userDefaultsPersistence] objectForKey:@"Cities"] count] > 0) {
			id prefsCityDict = [[%c(WeatherPreferences) userDefaultsPersistence] objectForKey:@"Cities"][0];
			if (prefsCityDict != nil) {
				self.myCity = [[%c(WeatherPreferences) sharedPreferences] cityFromPreferencesDictionary:prefsCityDict];
				[[%c(TWCCityUpdater) sharedCityUpdater] updateWeatherForCity:self.myCity];
			}
		}
		
		if (self.myCity != nil) {
			self.bgView = [[%c(WUIDynamicWeatherBackground) alloc] initWithFrame:self.frame];
			self.bgView.city = self.myCity;
			self.bgView.condition.city = self.myCity;
			[self addSubview:self.bgView];

			UIGraphicsBeginImageContextWithOptions(self.bgView.bounds.size, NO, UIScreen.mainScreen.scale);
			[self.bgView drawViewHierarchyInRect:self.bgView.bounds afterScreenUpdates:YES];
			newImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

		}
	}
	[[%c(TWCCityUpdater) sharedCityUpdater] updateWeatherForCity:self.myCity];
}


%end


%ctor {
	NSBundle *wBundle = [NSBundle bundleWithPath:@"/System/Library/PrivateFrameworks/WeatherUI.framework"];
	if (!wBundle.loaded) {
		[wBundle load];
	}
}