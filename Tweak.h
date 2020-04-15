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


@interface WUIDynamicWeatherBackground : UIView 
@property (nonatomic,retain) WUIWeatherCondition * condition; 
@property (nonatomic,retain) WUIGradientLayer * gradientLayer;  
- (id)initWithFrame:(CGRect)arg1 ;
- (void)setCity:(id)arg1 ;
@end


@interface SBFStaticWallpaperView (WG)
@property (nonatomic, strong) WUIDynamicWeatherBackground *bgView; 
@property (nonatomic, strong) City *myCity; 
@end

@interface UIView (Private)
-(id)_viewControllerForAncestor;
@end

@interface SBFWallpaperView (Private)
@property (nonatomic,retain) UIView * contentView;     
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