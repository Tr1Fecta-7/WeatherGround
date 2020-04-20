#import "Tweak.h"

@interface WeatherGroundServer : NSObject

@property (nonatomic, strong) WUIDynamicWeatherBackground *lockScreenBgView;
@property (nonatomic, strong) WUIDynamicWeatherBackground *homeScreenBgView;
@property (nonatomic, strong) WATodayAutoupdatingLocationModel *todayUpdateModel;
@property (nonatomic, strong) City *myCity; 

+ (instancetype)sharedServer;
- (void)updateModel;
- (void)updateCityForCity:(City *)city;
- (NSDictionary *)temperatureInfo:(NSString *)unit;
- (int)currentConditionCode;
- (UIImage *)getImageForCondition:(NSInteger)conditionCode style:(int)style;
- (NSMutableAttributedString *)stringForWeatherImage:(UIImage *)weatherImg withPrefix:(NSString *)prefixString;
@end
