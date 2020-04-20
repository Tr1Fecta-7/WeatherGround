#import "WeatherHeaders.h"

@interface SBIcon : NSObject
@end

@interface SBLeafIcon : SBIcon
@property (nonatomic,copy,readonly) NSString *applicationBundleID;
@end

@interface SBApplicationIcon : SBLeafIcon
@end

@interface SBIconView : UIView
@property (nonatomic,retain) SBIcon *icon; 
@property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayUpdateModel;
@property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
@property (nonatomic, strong) City *myCity;

- (void)setupNewIconView;
- (void)setupModelAndUpdate;
- (void)setupDynamicWeatherBackgroundView;
- (void)setupWeatherGradientLayer;
- (void)setupWeatherIconImageView;
@end


@interface SBIconImageView : UIView 
@property (nonatomic,readonly) SBIcon * icon;
@property (assign,nonatomic) SBIconView * iconView; 

// %new
@property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayUpdateModel;
@property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
@property (nonatomic, strong) City *myCity; 
@property (nonatomic, strong) UIImageView *weatherIconImageView;


- (id)initWithFrame:(CGRect)arg1;
- (void)updateImageAnimated:(BOOL)arg1;
- (void)prepareForReuse;

- (void)setupNewWeatherIconView;
- (void)setupModelAndUpdate;
- (void)setupDynamicWeatherBackgroundView;
- (void)setupWeatherGradientLayer;
- (void)setupWeatherIconImageView;
@end