#import "../PS.h"

BOOL timeLapseOverride = NO;

static NSDictionary *mbDefaults()
{
	return [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.camera.plist"];
}

%group iOS8

%hook CAMCaptureController

- (BOOL)canChangeFocusOrExposure
{
	BOOL allow1 = [mbDefaults()[@"CAMExposureBiasSliderPano"] boolValue] && [self isCapturingPanorama];
	BOOL allow2 = [mbDefaults()[@"CAMExposureBiasSliderTimeLapse"] boolValue] && [self isCapturingTimelapse];
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
	timeLapseOverride = [mbDefaults()[@"CAMExposureBiasSliderTimeLapse"] boolValue];
	BOOL orig = %orig;
	timeLapseOverride = NO;
	return orig;
}

- (BOOL)_allowExposureBiasForMode:(int)mode
{
	BOOL allow1 = [mbDefaults()[@"CAMExposureBiasSliderPano"] boolValue] && mode == 3;
	BOOL allow2 = [mbDefaults()[@"CAMExposureBiasSliderTimeLapse"] boolValue] && mode == 6;
	return (allow1 || allow2) ? YES : %orig;
}

- (BOOL)_allowFocusRectPanning
{
	return [mbDefaults()[@"CAMFocusRectPanning"] boolValue] || [mbDefaults()[@"CAMEnableSeparateExposure"] boolValue];
}

- (BOOL)_allowExposureBiasTextView
{
	return [mbDefaults()[@"CAMExposureBiasOverlay"] boolValue];
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
	id val = mbDefaults()[@"CAMExposureBiasSlider"];
	BOOL keyExist = val != nil;
	return keyExist ? [val boolValue] : YES;
}

- (BOOL)_allowDismissFocusAttachment
{
	return [mbDefaults()[@"CAMShowDismissFocusAttachment"] boolValue];
}

- (BOOL)_allowFocusLockAttachments
{
	return [mbDefaults()[@"CAMEnableFocusLockAttachments"] boolValue];
}

- (BOOL)_allowSplitFocusAndExposure
{
	return [mbDefaults()[@"CAMEnableSeparateExposure"] boolValue];
}

%end

%end

%group iOS9

%hook CAMViewfinderViewController

- (BOOL)_isCapturingTimelapse
{
	return timeLapseOverride ? NO : %orig;
}

%end

%hook CAMPreviewViewController

- (BOOL)_canModifyExposureBias
{
	timeLapseOverride = [mbDefaults()[@"CAMExposureBiasSliderTimeLapse"] boolValue];
	BOOL orig = %orig;
	timeLapseOverride = NO;
	return orig;
}

- (BOOL)_allowExposureBiasForMode:(int)mode
{
	BOOL allow1 = [mbDefaults()[@"CAMExposureBiasSliderPano"] boolValue] && mode == 3;
	BOOL allow2 = [mbDefaults()[@"CAMExposureBiasSliderTimeLapse"] boolValue] && mode == 6;
	return (allow1 || allow2) ? YES : %orig;
}

%end

%end

%ctor
{
	%init;
}