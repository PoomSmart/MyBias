#import <substrate.h>

BOOL timeLapseOverride = NO;

@interface CAMCaptureController
- (BOOL)isCapturingPanorama;
- (BOOL)isCapturingTimelapse;
@end

@interface CAMCameraView
- (void)_updateForFocusCapabilities;
@end

%hook CAMCaptureController

- (BOOL)canChangeFocusOrExposure
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key1 = @"CAMExposureBiasSliderPano";
	NSString *key2 = @"CAMExposureBiasSliderTimeLapse";
	BOOL allow1 = [defaults boolForKey:key1] && [self isCapturingPanorama];
	BOOL allow2 = [defaults boolForKey:key2] && [self isCapturingTimelapse];
	return (allow1 || allow2) ? YES : %orig;
}

%end

%hook CAMCameraView

- (BOOL)_isCapturingTimelapse
{
	return timeLapseOverride ? NO : %orig;
}

- (BOOL)_canModifyExposureBias
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = @"CAMExposureBiasSliderTimeLapse";
	timeLapseOverride = [defaults boolForKey:key];
	BOOL orig = %orig;
	timeLapseOverride = NO;
	return orig;
}

- (BOOL)_allowExposureBiasForMode:(int)mode
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key1 = @"CAMExposureBiasSliderPano";
	NSString *key2 = @"CAMExposureBiasSliderTimeLapse";
	BOOL allow1 = [defaults boolForKey:key1] && mode == 3;
	BOOL allow2 = [defaults boolForKey:key2] && mode == 6;
	return (allow1 || allow2) ? YES : %orig;
}

%end

%hook CAMApplicationViewController

- (void)loadView
{
	%orig;
	CAMCameraView *cameraView = MSHookIvar<CAMCameraView *>(self, "_cameraView");
	if (cameraView)
		[cameraView _updateForFocusCapabilities];
}

%end

%hook CAMPreviewView

- (BOOL)_enableExposureBias
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *key = @"CAMExposureBiasSlider";
	BOOL keyExist = [defaults objectForKey:key] != nil;
	return keyExist ? [defaults boolForKey:key] : YES;
}

%end