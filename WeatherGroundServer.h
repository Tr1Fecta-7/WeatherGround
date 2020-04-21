#import "Tweak.h"

@interface WeatherGroundServer : NSObject

@property (nonatomic, strong) WUIDynamicWeatherBackground *lockScreenBgView;
@property (nonatomic, strong) WUIDynamicWeatherBackground *homeScreenBgView;
@property (nonatomic, strong) WUIDynamicWeatherBackground *sharedBgView;

@property (nonatomic, strong) UIImage *sharedImage;
@property (nonatomic, strong) NSDictionary *preferencesDictionary; 

@property (nonatomic, strong) WATodayAutoupdatingLocationModel *todayUpdateModel;
@property (nonatomic, strong) City *myCity; 
@property (nonatomic, strong) NSTimer *autoUpdateTimer;

@property (nonatomic, strong) _UIStatusBarStringView *statusStringView; // In Apps

+ (instancetype)sharedServer;


- (void)setStatusBarTextToWeatherInfo:(NSDictionary *)infoDict;
- (void)changeLabelTextWithAttributedString:(NSMutableAttributedString *)text;
- (void)updateModel;

- (void)setupDynamicWeatherBackgrounds;
- (void)setupWeatherEffectLayers;

- (BOOL)boolForKey:(NSString *)key;
- (int)intForKey:(NSString *)key;

- (CALayer *)weatherEffectsLayerForWeatherView:(WUIDynamicWeatherBackground *)weatherView;
- (void)updateCityForCity:(City *)city;
- (NSDictionary *)temperatureInfo:(NSString *)unit;
- (int)currentConditionCode;
- (UIImage *)getImageForCondition:(NSInteger)conditionCode style:(int)style;
- (NSMutableAttributedString *)stringForWeatherImage:(UIImage *)weatherImg withPrefix:(NSString *)prefixString;
@end
