#import "WeatherGroundServer.h"

@implementation WeatherGroundServer {
    MRYIPCCenter* _center;
}

+ (instancetype)sharedServer {
    static dispatch_once_t onceToken = 0;
    __strong static WeatherGroundServer *sharedServer = nil;
    dispatch_once(&onceToken, ^{
        sharedServer = [[self alloc] init];
    });
    return sharedServer;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _center = [MRYIPCCenter centerNamed:@"com.tr1fecta.WeatherGroundServer"];
        [_center addTarget:self action:@selector(temperatureInfo:)];
        [self updateModel];
    }
    return self;
}

- (void)setupDynamicWeatherBackgrounds {

}

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

- (void)updateCityForCity:(City *)city {
    city = self.myCity;
}

- (NSDictionary *)temperatureInfo:(NSString *)unit {
    [self updateModel];

	int temperature = 0;

    if (self.todayUpdateModel != nil && self.todayUpdateModel.forecastModel.currentConditions != nil) {
        if ([unit isEqualToString:@"celsius"]) {
            temperature = (int)self.todayUpdateModel.forecastModel.currentConditions.temperature.celsius;
        }
        else if ([unit isEqualToString:@"fahrenheit"]) {
            temperature = (int)self.todayUpdateModel.forecastModel.currentConditions.temperature.fahrenheit;
        }
        else if ([unit isEqualToString:@"kelvin"])  {
            temperature = (int)self.todayUpdateModel.forecastModel.currentConditions.temperature.kelvin;
        }
    }

    int conditionCode = [self currentConditionCode];
    NSMutableAttributedString *weatherString = [self stringForWeatherImage:[self getImageForCondition:conditionCode style:1] withPrefix:[NSString stringWithFormat:@"%d°", temperature]]; 
    NSDictionary *infoDict = @{@"weatherString": weatherString};
    return infoDict;
}

- (int)currentConditionCode {
    if (self.todayUpdateModel != nil && self.todayUpdateModel.forecastModel.currentConditions != nil) {
        int conditionCode = (int)self.todayUpdateModel.forecastModel.currentConditions.conditionCode;
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