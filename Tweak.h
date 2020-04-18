#include <Weather/City.h>
#include <Weather/TWCCityUpdater.h>
#include <Weather/WeatherPreferences.h>
#include <SpringBoardFoundation/SBFStaticWallpaperView.h>
#include <SpringBoard/SBCoverSheetPanelBackgroundContainerView.h>
#include <SpringBoard/SBWallpaperEffectView.h>


@interface WUIWeatherCondition : NSObject <CALayerDelegate>
@property (assign,nonatomic) City *city;
@property (nonatomic,readonly) CALayer *layer;
@end

@interface WUIGradientLayer : CAGradientLayer {
	BOOL _allowsActions;
}
@property (assign,nonatomic) BOOL allowsActions;
-(id)actionForKey:(id)arg1 ;
-(BOOL)allowsActions;
-(void)setAllowsActions:(BOOL)arg1 ;
@end

@interface WACurrentForecast
@property (assign,nonatomic) long long conditionCode;
@end

@interface WAForecastModel : NSObject
@property (nonatomic,retain) City * city;
@property (nonatomic,retain) WACurrentForecast * currentConditions;
@end

@interface WATodayModel
+(id)autoupdatingLocationModelWithPreferences:(id)arg1 effectiveBundleIdentifier:(id)arg2 ;
-(BOOL)executeModelUpdateWithCompletion:(/*^block*/id)arg1 ;
@property (nonatomic,retain) WAForecastModel * forecastModel;
-(id)location;
@end


@interface WATodayAutoupdatingLocationModel : WATodayModel
-(WAForecastModel *)forecastModel;
-(void)setIsLocationTrackingEnabled:(BOOL)arg1;
-(void)setLocationServicesActive:(BOOL)arg1;
@end

  
@interface WFTemperature : NSObject 
@property (assign,nonatomic) CGFloat celsius; 
@property (assign,nonatomic) CGFloat fahrenheit; 
@property (assign,nonatomic) CGFloat kelvin; 
-(CGFloat)temperatureForUnit:(int)arg1 ;
@end


@interface WUIDynamicWeatherBackground : UIView 
@property (nonatomic,retain) WUIWeatherCondition *condition; 
@property (nonatomic,retain) WUIGradientLayer *gradientLayer; 

- (id)initWithFrame:(CGRect)arg1 ;
- (void)setCity:(id)arg1 ;
@end


@interface SBFStaticWallpaperView (WG)
@property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
@property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayUpdateModel;
@property (nonatomic, strong) City *myCity; 

- (void)updateModel;
- (CALayer *)weatherEffectsLayer;

@end

@interface UIView (Private)
- (id)_viewControllerForAncestor;
@end

@interface _UIStatusBarForegroundView : UIView 
@property (strong, nonatomic) NSString *temperature;
- (void)postNeedTemperatureNotification;
@end

@interface _UIStatusBarStringView : UILabel
@property (nonatomic,copy) NSString * originalText;   
- (void)changeLabelText:(NSString *)text;
- (void)setTemperatureWithNotification:(NSNotification *)notification;
@end

@interface SBFWallpaperView (Private)
@property (nonatomic,retain) UIView * contentView;     
@end


@interface WAGreetingView : UIView {
    UIImageView * _conditionImageView;
    NSMutableArray * _constraints;
    bool  _isViewCreated;
    UIColor * _labelColor;
    UILabel * _natualLanguageDescriptionLabel;
    UILabel * _temperatureLabel;
    WATodayAutoupdatingLocationModel * _todayModel;
}

@property (nonatomic, retain) UIImageView *conditionImageView;
@property (nonatomic, retain) NSMutableArray *constraints;
@property (nonatomic) bool isViewCreated;
@property (nonatomic, retain) UIColor *labelColor;
@property (nonatomic, retain) UILabel *natualLanguageDescriptionLabel;
@property (nonatomic, retain) UILabel *temperatureLabel;
@property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayModel;

- (id)_conditionsImage;
- (id)_temperature;
- (id)conditionImageView;
- (id)constraints;
- (void)createViews;
- (void)dealloc;
- (id)init;
- (id)initWithColor:(id)arg1;
- (bool)isViewCreated;
- (id)labelColor;
- (id)natualLanguageDescriptionLabel;
- (void)setConditionImageView:(UIImageView *)arg1;
- (void)setConstraints:(NSMutableArray *)arg1;
- (void)setIsViewCreated:(bool)arg1;
- (void)setLabelColor:(UIColor *)arg1;
- (void)setNatualLanguageDescriptionLabel:(UILabel *)arg1;
- (void)setTemperatureLabel:(UILabel *)arg1;
- (void)setTodayModel:(WATodayAutoupdatingLocationModel *)arg1;
- (void)setupConstraints;
- (void)startService;
- (id)temperatureLabel;
- (id)todayModel;
- (void)updateConstraints;
- (void)updateLabelColors;
- (void)updateView;

@end