#import "../asteroidicon/source/Asteroid.h"
@interface SBHomeScreenView : UIView
@property (nonatomic, retain) WUIWeatherConditionBackgroundView *referenceView;
@property (nonatomic,retain) NSTimer *refreshTimer;
@property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayModel;
@end 

@interface SBHomeScreenView (Weather)
-(void)updateView;
@end 

static float deviceVersion = [[[UIDevice currentDevice] systemVersion] floatValue];

%group LiveWeather
%hook SBHomeScreenView
%property (nonatomic, retain) WUIWeatherConditionBackgroundView *referenceView;
%property (nonatomic,retain) NSTimer *refreshTimer;
%property (nonatomic, retain) WATodayAutoupdatingLocationModel *todayModel;

- (void)layoutSubviews {
    %orig;
    if(!self.referenceView){

        [self updateView];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(weatherTimer:) name:@"weatherTimerUpdate" object:nil];
    }
    /*
    [NSTimer scheduledTimerWithTimeInterval:300.0f
                                     target:self
                                   selector:@selector(updateView)
                                   userInfo:nil
                                    repeats:YES];
    */
    
    //[self updateView];
}
%new
- (void) weatherTimer: (NSNotification *)notification{
    [self updateView];
}

%new 
-(void)updateView{
    NSLog(@"lock_TWEAK | updateView");
    //WeatherPreferences* wPrefs = [%c(WeatherPreferences) sharedPreferences];
    
    //City* city = [wPrefs localWeatherCity];
    
    WeatherPreferences* wPrefs = [%c(WeatherPreferences) sharedPreferences];
    self.todayModel = [NSClassFromString(@"WATodayModel") autoupdatingLocationModelWithPreferences: wPrefs effectiveBundleIdentifier:@"com.apple.weather"];
    
    [self.todayModel.locationManager forceLocationUpdate];
    [self.todayModel _executeLocationUpdateForLocalWeatherCityWithCompletion:^{nil;}];

    
    
    //[[%c(WATodayAutoupdatingLocationModel) alloc] init];
    //[todayModel setPreferences:wPrefs];
    City *city = ([prefs boolForKey:@"isLocal"] ? [[%c(WeatherPreferences) sharedPreferences] localWeatherCity] : [[%c(WeatherPreferences) sharedPreferences] cityFromPreferencesDictionary:[[[%c(WeatherPreferences) userDefaultsPersistence]userDefaults] objectForKey:@"Cities"][0]]);
    
    //City *city = todayModel.forecastModel.city;
    
   // WALockscreenWidgetViewController *weatherCont = [[NSClassFromString(@"WALockscreenWidgetViewController") alloc] init];
    
    [city update];
    
    NSLog(@"lock_TWEAK | city: %@ and %@ request: %@",city, self.todayModel.forecastModel.city, self.todayModel.geocodeRequest);
    /*
    City *city = nil;
    if ([prefs boolForKey:@"isLocal"]){
        
        //city = [[%c(WeatherPreferences) sharedPreferences] localWeatherCity];
        
        //if([[NSDate date] compare:[[city updateTime] dateByAddingTimeInterval:(.5)*3600]] == NSOrderedDescending) {
            WeatherLocationManager *weatherLocationManager = [%c(WeatherLocationManager) sharedWeatherLocationManager];
            
            CLLocationManager *locationManager = [[CLLocationManager alloc]init];
            [weatherLocationManager setDelegate:locationManager];
            
            if(![weatherLocationManager locationTrackingIsReady]) {
                [weatherLocationManager setLocationTrackingReady:YES activelyTracking:NO watchKitExtension:nil];
            }
            
            [[%c(WeatherPreferences) sharedPreferences] setLocalWeatherEnabled:YES];
            [weatherLocationManager setLocationTrackingActive:YES];
            [[%c(TWCLocationUpdater) sharedLocationUpdater] updateWeatherForLocation:[weatherLocationManager location] city:city];
            [weatherLocationManager setLocationTrackingActive:NO];
        city = todayModel.forecastModel.city;
        //}
        
        //city = [[%c(WeatherPreferences) sharedPreferences] localWeatherCity];
    } else {
        city = [[%c(WeatherPreferences) sharedPreferences] cityFromPreferencesDictionary:[[[%c(WeatherPreferences) userDefaultsPersistence]userDefaults] objectForKey:@"Cities"][0]];
    }*/

    
        //if (city){
            NSLog(@"lock_TWEAK | adding to superview");
            [self.referenceView removeFromSuperview];
    
            self.referenceView = [[%c(WUIWeatherConditionBackgroundView) alloc] initWithFrame:self.frame];
            [self.referenceView.background setCity:city];
            [self.referenceView.background setTag:123];
            [[self.referenceView.background condition] resume];

            self.referenceView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            self.referenceView.clipsToBounds = YES;
            [self addSubview:self.referenceView];
            [self sendSubviewToBack:self.referenceView];
       // }
}
        
%end 
%end 

@interface SBIconBlurryBackgroundView : UIView
@end 

@interface SBFolderIconBackgroundView : SBIconBlurryBackgroundView
@end 

%hook SBFolderIconBackgroundView
-(void)layoutSubviews{
    %orig;
    if([prefs boolForKey:@"noFolders"]){
        self.hidden = TRUE;
    }
}
%end 

//Dock 
@interface SBDockView : UIView 
@end 

@interface SBWallpaperEffectView : UIView
@end 

%hook SBDockView
-(void)layoutSubviews{
    %orig;
    if([prefs boolForKey:@"noDock"]){
        MSHookIvar<SBWallpaperEffectView*>(self, "_backgroundView").hidden = YES;
        MSHookIvar<UIImageView*>(self, "_backgroundImageView").hidden = YES;
    }
}
%end 

@interface SBHighlightView : UIView
@end 

%hook SBHighlightView
-(void)layoutSubviews{
    %orig;
    if([prefs boolForKey:@"noDock"]){
        self.hidden = YES;
    } 
}
%end 

//Hide background accross views
//Thanks June
%group WeatherBackground
%hook WUIDynamicWeatherBackground
	-(id)gradientLayer{
		return nil;
		return %orig;
	}
	-(void)setCurrentBackground:(CALayer *)arg1{

	}
	-(void)setBackgroundCache:(NSCache *)arg1{
	
	}
	/* 11.1.2 Still nees improving */ 
	-(void)addSublayer:(id)arg1{
		%orig;
			if(deviceVersion < 11.3){
				CALayer* layer = arg1;
				for(CALayer* firstLayers in layer.sublayers){
					if(firstLayers.backgroundColor){
						firstLayers.backgroundColor = [UIColor clearColor].CGColor;
					}
					for(CALayer* secLayers in firstLayers.sublayers){
						for(CALayer* thrLayers in secLayers.sublayers){
							if([thrLayers isKindOfClass:[CAGradientLayer class]]){
								thrLayers.hidden = YES;
							}
						}
					}
				}
			}
	}
%end
%end 

%ctor{
    if([prefs boolForKey:@"homeScreenWeather"]){
        %init(LiveWeather);
	}
    if([prefs boolForKey:@"hideWeatherBackground"]){
        %init(WeatherBackground);
    }
    %init(_ungrouped);
}
