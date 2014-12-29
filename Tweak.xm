#import <substrate.h>

BOOL timeLapseOverride = NO;

@interface CAMCaptureController
- (BOOL)isCapturingPanorama;
- (BOOL)isCapturingTimelapse;
@end

@interface CAMCameraView
- (void)_updateForFocusCapabilities;
@end

static NSDictionary *mbDefaults()
{
	return [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.camera.plist"];
}

%hook CAMCaptureController

- (BOOL)canChangeFocusOrExposure
{
	NSString *key1 = @"CAMExposureBiasSliderPano";
	NSString *key2 = @"CAMExposureBiasSliderTimeLapse";
	BOOL allow1 = [[mbDefaults() objectForKey:key1] boolValue] && [self isCapturingPanorama];
	BOOL allow2 = [[mbDefaults() objectForKey:key2] boolValue] && [self isCapturingTimelapse];
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
	NSString *key = @"CAMExposureBiasSliderTimeLapse";
	timeLapseOverride = [[mbDefaults() objectForKey:key] boolValue];
	BOOL orig = %orig;
	timeLapseOverride = NO;
	return orig;
}

- (BOOL)_allowExposureBiasForMode:(int)mode
{
	NSString *key1 = @"CAMExposureBiasSliderPano";
	NSString *key2 = @"CAMExposureBiasSliderTimeLapse";
	BOOL allow1 = [[mbDefaults() objectForKey:key1] boolValue] && mode == 3;
	BOOL allow2 = [[mbDefaults() objectForKey:key2] boolValue] && mode == 6;
	return (allow1 || allow2) ? YES : %orig;
}

- (BOOL)_allowFocusRectPanning
{
	return [[mbDefaults() objectForKey:@"CAMFocusRectPanning"] boolValue] ||
			[[mbDefaults() objectForKey:@"CAMEnableSeparateExposure"] boolValue];
}

- (BOOL)_allowExposureBiasTextView
{
	return [[mbDefaults() objectForKey:@"CAMExposureBiasOverlay"] boolValue];
}

- (void)_startFocus:(BOOL)arg1 andExposure:(BOOL)arg2 atPoint:(CGPoint)arg3 startFocusAnimation:(BOOL)arg4
{
	[self _updateForFocusCapabilities];
	%orig;
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
	NSString *key = @"CAMExposureBiasSlider";
	id val = [mbDefaults() objectForKey:key];
	BOOL keyExist = val != nil;
	return keyExist ? [val boolValue] : YES;
}

- (BOOL)_allowDismissFocusAttachment
{
	return [[mbDefaults() objectForKey:@"CAMShowDismissFocusAttachment"] boolValue];
}

- (BOOL)_allowFocusLockAttachments
{
	return [[mbDefaults() objectForKey:@"CAMEnableFocusLockAttachments"] boolValue];
}

- (BOOL)_allowSplitFocusAndExposure
{
	return [[mbDefaults() objectForKey:@"CAMEnableSeparateExposure"] boolValue];
}

%end