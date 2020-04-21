#include "WeatherHeaders.h"
#include "SB-IconHeaders.h"
#include <MRYIPCCenter.h>
#include "WeatherGroundServer.h"
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)