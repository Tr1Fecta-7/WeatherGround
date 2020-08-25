#import "WeatherGroundManager.h"
//#import <RemoteLog.h>

@implementation WeatherGroundManager

- (BOOL)boolForKey:(NSString *)key {
    id object = [self.preferencesDictionary objectForKey:key];
    return object ? [object boolValue] : NO;
}

- (int)intForKey:(NSString *)key {
    id object = [self.preferencesDictionary objectForKey:key];
    return object ? [object intValue] : 0;
}

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken = 0;
    __strong static WeatherGroundManager *sharedManager = nil;
    dispatch_once(&onceToken, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _preferencesDictionary =  [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.tr1fecta.wgprefs.plist"];

        // Convert to minutes from seconds
        double interval = (double)[self intForKey:@"kAutoUpdateInterval"] * 60;
        if (interval > 0) {
            _autoUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(updateModel) userInfo:nil repeats:YES];
        }
        
    }
    return self;
}

// In Apps
- (void)setStatusBarTextToWeatherInfo:(NSDictionary *)infoDict {
    if (self.statusStringView != nil) {
        NSMutableAttributedString *temperatureAttrString = [[self temperatureInfo:infoDict[@"unit"]] objectForKey:@"weatherString"];
        self.statusStringView.attributedText = temperatureAttrString;
        [self changeLabelTextWithAttributedString:temperatureAttrString];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.timeZone = [NSTimeZone localTimeZone];
			formatter.dateFormat = @"HH:mm";
			NSString *currentStatusTime = [formatter stringFromDate:[NSDate now]];

			self.statusStringView.attributedText = nil;
			[self changeLabelText:currentStatusTime];
		});
    }
}

- (void)changeLabelTextWithAttributedString:(NSMutableAttributedString *)text {
	CATransition *animation = [CATransition animation];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.type = kCATransitionPush;
	animation.subtype = kCATransitionFromTop;
	animation.duration = 0.3;
	[self.statusStringView.layer addAnimation:animation forKey:@"kCATransitionPush"];

	self.statusStringView.attributedText = text;
}

- (void)changeLabelText:(NSString *)text {
	CATransition *animation = [CATransition animation];
	animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	animation.type = kCATransitionPush;
	animation.subtype = kCATransitionFromTop;
	animation.duration = 0.3;
	[self.statusStringView.layer addAnimation:animation forKey:@"kCATransitionPush"];

	self.statusStringView.text = text;
}

- (void)setupDynamicWeatherBackgrounds {
    SBWallpaperController *sharedInstance = [%c(SBWallpaperController) sharedInstance];
    // Always create this instance for the weather effects layer, but only add if enabled
    self.sharedBgView = [[%c(WUIDynamicWeatherBackground) alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.sharedBgView.city = [self myCity];
    self.sharedBgView.condition.city = [self myCity];
    if (sharedInstance.sharedWallpaperView != nil && [self boolForKey:@"kUseEntireWeatherView"] && [self boolForKey:@"kUseWeatherEffectsOnly"] == NO) {
        [sharedInstance.sharedWallpaperView addSubview:self.sharedBgView];

        // Take a screenshot of the current view, to use on SBFWallpaperView's contentView's image, otherwise the background when pulling up on Notification Center and Lockscreen will be see through
        UIGraphicsBeginImageContextWithOptions(self.sharedBgView.bounds.size, NO, UIScreen.mainScreen.scale);
		[self.sharedBgView drawViewHierarchyInRect:self.sharedBgView.bounds afterScreenUpdates:YES];
	    self.sharedImage = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
    }
   
    // Check if the user is using 2 different wallpapers
    if (sharedInstance.lockscreenWallpaperView != nil && sharedInstance.homescreenWallpaperView != nil && sharedInstance.sharedWallpaperView == nil) {
        if ([self boolForKey:@"kLockscreenEnabled"]) {
            self.lockScreenBgView = [[%c(WUIDynamicWeatherBackground) alloc] initWithFrame:UIScreen.mainScreen.bounds];
            self.lockScreenBgView.city = [self myCity];
            self.lockScreenBgView.condition.city = [self myCity];

            if ([self boolForKey:@"kUseEntireWeatherView"]) {
                [sharedInstance.lockscreenWallpaperView addSubview:self.lockScreenBgView];
            }
        }
        if ([self boolForKey:@"kHomescreenEnabled"]) {
            self.homeScreenBgView = [[%c(WUIDynamicWeatherBackground) alloc] initWithFrame:UIScreen.mainScreen.bounds];
            self.homeScreenBgView.city = [self myCity];
            self.homeScreenBgView.condition.city = [self myCity];
            
            if ([self boolForKey:@"kUseEntireWeatherView"]) {
                [sharedInstance.homescreenWallpaperView addSubview:self.homeScreenBgView];
            }
        }
    }
}

- (void)setupWeatherEffectLayers {
    if ([self boolForKey:@"kUseWeatherEffectsOnly"] && [self boolForKey:@"kUseEntireWeatherView"] == NO) {
        SBWallpaperController *sharedInstance = [%c(SBWallpaperController) sharedInstance];

        if (sharedInstance.sharedWallpaperView != nil && self.sharedBgView != nil) {
            CALayer *nLayer = [self weatherEffectsLayerForWeatherView:nil];
			[sharedInstance.sharedWallpaperView.layer addSublayer:nLayer];
        }
        else if (sharedInstance.lockscreenWallpaperView != nil && sharedInstance.homescreenWallpaperView != nil && self.lockScreenBgView != nil && self.homeScreenBgView != nil && sharedInstance.sharedWallpaperView == nil)  {
            if ([self boolForKey:@"kLockscreenEnabled"]) {
                CALayer *nLayer = [self weatherEffectsLayerForWeatherView:self.lockScreenBgView];
                [sharedInstance.lockscreenWallpaperView.layer addSublayer:nLayer];
            }
            if ([self boolForKey:@"kHomescreenEnabled"]) {
                CALayer *nLayer = [self weatherEffectsLayerForWeatherView:self.homeScreenBgView]; 
                [sharedInstance.homescreenWallpaperView.layer addSublayer:nLayer];
            }
        }
    }
}

- (CALayer *)weatherEffectsLayerForWeatherView:(WUIDynamicWeatherBackground *)weatherView {
	CALayer *nLayer = weatherView != nil ? weatherView.condition.layer : self.sharedBgView.condition.layer;
	nLayer.bounds = UIScreen.mainScreen.nativeBounds;
	nLayer.allowsGroupOpacity = YES;
	nLayer.position = CGPointMake(0, UIScreen.mainScreen.bounds.size.height);
	nLayer.geometryFlipped = YES;

	return nLayer;
}

- (void)updateModel {
     if (!self.widgetVC) {
        self.widgetVC = [[%c(WALockscreenWidgetViewController) alloc] init];

        if ([self.widgetVC respondsToSelector:@selector(_setupWeatherModel)]) {
            [self.widgetVC _setupWeatherModel];
            
        }
    }

    if (self.widgetVC) {
        if ([self.widgetVC respondsToSelector:@selector(todayModelWantsUpdate:)] && self.widgetVC.todayModel) {
            [self.widgetVC todayModelWantsUpdate:self.widgetVC.todayModel];
        }
        if ([self.widgetVC respondsToSelector:@selector(updateWeather)]) {
            [self.widgetVC updateWeather];
        }
        if ([self.widgetVC respondsToSelector:@selector(_updateTodayView)]) {
		    [self.widgetVC _updateTodayView];
        }
        if ([self.widgetVC respondsToSelector:@selector(_updateWithReason:)]) {
            [self.widgetVC _updateWithReason:nil];
        }
        
        /*if ([self.widgetVC respondsToSelector:@selector(_temperature)]) {
		    self.currentTemperature = [self.widgetVC _temperature];
	    }

        if ([self.widgetVC respondsToSelector:@selector(_locationName)]) {
		    self.myCity = [self.widgetVC _locationName];
	    }*/
    }


   if (self.widgetVC.todayModel.forecastModel.city) {
        self.myCity = self.widgetVC.todayModel.forecastModel.city;

        if (self.sharedBgView != nil) {
            [self.sharedBgView setCity:[self myCity] animate:YES];
            [self.sharedBgView.condition setCity:[self myCity] animationDuration:2];
            
            if ([self boolForKey:@"kUseWeatherEffectsOnly"]) {
                [self setupWeatherEffectLayers];
            }
        }
        if (self.lockScreenBgView != nil) {
            [self.lockScreenBgView setCity:[self myCity] animate:YES];
            [self.lockScreenBgView.condition setCity:[self myCity] animationDuration:2];

            if ([self boolForKey:@"kUseWeatherEffectsOnly"]) {
                [self setupWeatherEffectLayers];
            }
        }
        if (self.homeScreenBgView != nil) {
            [self.homeScreenBgView setCity:[self myCity] animate:YES];
            [self.homeScreenBgView.condition setCity:[self myCity] animationDuration:2];

            if ([self boolForKey:@"kUseWeatherEffectsOnly"]) {
                [self setupWeatherEffectLayers];
            }
        }
    }
}

- (void)pauseWG {
    if (self.sharedBgView != nil) {
        [self.sharedBgView.condition pause];
    }
    if (self.lockScreenBgView != nil) {
        [self.lockScreenBgView.condition pause];
    }
    if (self.homeScreenBgView != nil) {
        [self.homeScreenBgView.condition pause];
    }
}

- (void)resumeWG {
    if (self.sharedBgView != nil) {
        [self.sharedBgView.condition resume];
    }
    if (self.lockScreenBgView != nil) {
        [self.lockScreenBgView.condition resume];
        
    }
    if (self.homeScreenBgView != nil) {
        [self.homeScreenBgView.condition resume];
    }
}

- (void)updateCityForCity:(City *)city {
    city = self.myCity;
}

- (NSDictionary *)temperatureInfo:(NSString *)unit {
    [self updateModel];

	int temperature = 0;

    if (self.widgetVC != nil && self.widgetVC.todayModel.forecastModel.currentConditions != nil) {
        if ([unit isEqualToString:@"celsius"]) {
            temperature = (int)self.widgetVC.todayModel.forecastModel.currentConditions.temperature.celsius;
        }
        else if ([unit isEqualToString:@"fahrenheit"]) {
            temperature = (int)ceil(self.widgetVC.todayModel.forecastModel.currentConditions.temperature.fahrenheit);
        }
        else if ([unit isEqualToString:@"kelvin"])  {
            temperature = (int)ceil(self.widgetVC.todayModel.forecastModel.currentConditions.temperature.kelvin);
        }
    }

    int conditionCode = [self currentConditionCode];
    NSMutableAttributedString *weatherString = [self stringForWeatherImage:[self getImageForCondition:conditionCode style:1] withPrefix:[NSString stringWithFormat:@"%d°", temperature]]; 
    NSDictionary *infoDict = @{@"weatherString": weatherString};
    return infoDict;
}


- (int)currentConditionCode {
    if (self.widgetVC != nil && self.widgetVC.todayModel.forecastModel.currentConditions != nil) {
        int conditionCode = (int)self.widgetVC.todayModel.forecastModel.currentConditions.conditionCode;
	    return conditionCode;
    }
    return 0;
}

- (UIImage *)getImageForCondition:(NSInteger)conditionCode style:(int)style {
	UIImage *image = [WeatherImageLoader conditionImageWithConditionIndex:conditionCode style:style];
	return image;
}

- (NSMutableAttributedString *)stringForWeatherImage:(UIImage *)weatherImg withPrefix:(NSString *)prefixString{
    // Make a new Mutable Attributed String
	NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", prefixString]];
	// Make a new NSTextAttachment variable and set the image
	NSTextAttachment *imgAttachment = [[NSTextAttachment alloc] init];	
	imgAttachment.bounds = CGRectMake(0,-12,35,35);
	imgAttachment.image = weatherImg;
	// Make a new attributed string with the NSTextAttachment
	NSAttributedString *attrStringWithWeatherImage = [NSAttributedString attributedStringWithAttachment:imgAttachment];
	// Insert the attributed string containing our NSTextAttachment at the start of the string - example: {weatherIcon} 14°
	[attrString insertAttributedString:attrStringWithWeatherImage atIndex:0];

    return attrString;
}
@end