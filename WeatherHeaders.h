#include <Weather/City.h>
#include <Weather/TWCCityUpdater.h>
#include <Weather/WeatherPreferences.h>
#include <Weather/WeatherImageLoader.h>
#include <SpringBoardFoundation/SBFStaticWallpaperView.h>
#include <SpringBoard/SBCoverSheetPanelBackgroundContainerView.h>
#include <SpringBoard/SBWallpaperEffectView.h>
#include <SpringBoard/SBApplication.h>
#include <SpringBoard/SBLockScreenManager.h>



@interface WUIWeatherCondition : NSObject <CALayerDelegate>
@property (assign,nonatomic) City *city;
@property (nonatomic,readonly) CALayer *layer;
-(void)setCity:(id)arg1 animationDuration:(double)arg2 ;
-(void)setAlpha:(double)arg1 animationDuration:(double)arg2;
-(void)resume;
-(void)pause;
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
@property (nonatomic, retain) WFTemperature *temperature;
@end

@interface WAForecastModel : NSObject
@property (nonatomic,retain) City * city;
@property (nonatomic,retain) WACurrentForecast *currentConditions;
-(WFTemperature *)temperature;
@end

@interface WATodayModel
+(id)autoupdatingLocationModelWithPreferences:(id)arg1 effectiveBundleIdentifier:(id)arg2 ;
-(BOOL)executeModelUpdateWithCompletion:(/*^block*/id)arg1 ;
@property (nonatomic,retain) WAForecastModel * forecastModel;
-(id)location;
@end


@interface WATodayAutoupdatingLocationModel : WATodayModel
-(void)setIsLocationTrackingEnabled:(BOOL)arg1;
-(void)setLocationServicesActive:(BOOL)arg1;
@end

@interface UIStatusBarTapAction : NSObject

@property (nonatomic,readonly) long long type; 
@property (nonatomic,readonly) double xPosition; 
-(long long)type;
-(id)keyDescriptionForSetting:(unsigned long long)arg1 ;
-(long long)UIActionType;
-(double)xPosition;
-(id)initWithType:(long long)arg1 xPosition:(double)arg2 ;
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
-(void)setCity:(id)arg1 animate:(BOOL)arg2 ;
- (void)setCity:(id)arg1 ;
-(void)setCity:(id)arg1 animationDuration:(double)arg2 ;
-(CALayer *)rootLayer;
@end


@interface SBFStaticWallpaperView (WG)
@property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
@property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayUpdateModel;
@property (nonatomic, strong) City *myCity; 

- (void)updateModel;
- (CALayer *)weatherEffectsLayer;
- (int)currentConditionCode;
- (UIImage *)getImageForCondition:(NSInteger)conditionCode style:(int)style;

@end

@interface UIView (Private)
- (id)_viewControllerForAncestor;
@end

@interface _UIStatusBarForegroundView : UIView 
@property (strong, nonatomic) NSString *temperature;
@end

@interface _UIStatusBarStringView : UILabel
@property (nonatomic,copy) NSString * originalText;   
- (void)changeLabelText:(NSString *)text;
- (void)setTemperatureWithNotification:(NSNotification *)notification;
- (void)changeLabelTextWithAttributedString:(NSMutableAttributedString *)text;
@end

@interface _UIStatusBarDataStringEntry : NSObject  
@property (nonatomic,copy) NSString * stringValue;
@end

@interface _UIStatusBarData : NSObject
@property (nonatomic,copy) _UIStatusBarDataStringEntry * timeEntry;  
@end

@interface _UIStatusBar : UIView
@property (nonatomic,retain) UIView *foregroundView; 
@property (nonatomic,readonly) _UIStatusBarData * currentAggregatedData;  
@end

@interface NSObject (WG)
-(id)safeValueForKey:(id)arg1;
@end

@interface SBFWallpaperView (Private)
@property (nonatomic,retain) UIView * contentView;     
@end

@interface SBWallpaperController : NSObject
@property (nonatomic,retain) SBFWallpaperView * lockscreenWallpaperView;
@property (nonatomic,retain) SBFWallpaperView * homescreenWallpaperView;
@property (nonatomic,retain) SBFWallpaperView * sharedWallpaperView;
+(id)sharedInstance;
@end

@interface WALockscreenWidgetViewController : UIViewController
@property (nonatomic, strong) WATodayModel *todayModel;
+ (WALockscreenWidgetViewController *)sharedInstanceIfExists;
- (id)_temperature;
- (id)_locationName;
- (void)updateWeather;
- (void)_updateTodayView;
- (void)_updateWithReason:(id)reason;
- (void)_setupWeatherModel;
- (void)todayModelWantsUpdate:(WATodayModel *)todayModel;
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


@interface SBMainDisplaySceneLayoutStatusBarView : UIView {
    _UIStatusBar *_statusBarUnderlyingViewAccessor;
}
@end