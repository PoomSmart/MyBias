#import "../PS.h"

BOOL timeLapseOverride = NO;

static NSDictionary *mbDefaults()
{
	return [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.camera.plist"];
}

%hook CaptureController

- (BOOL)canChangeFocusOrExposure
{
	NSString *key1 = @"CAMExposureBiasSliderPano";
	NSString *key2 = @"CAMExposureBiasSliderTimeLapse";
	BOOL allow1 = [mbDefaults()[key1] boolValue] && [self isCapturingPanorama];
	BOOL allow2 = [mbDefaults()[key2] boolValue] && [self isCapturingTimelapse];
	return (allow1 || allow2) ? YES : %orig;
}

%end

%hook CameraView

- (BOOL)_isCapturingTimelapse
{
	return timeLapseOverride ? NO : %orig;
}

- (BOOL)_canModifyExposureBias
{
	NSString *key = @"CAMExposureBiasSliderTimeLapse";
	timeLapseOverride = [mbDefaults()[key] boolValue];
	BOOL orig = %orig;
	timeLapseOverride = NO;
	return orig;
}

- (BOOL)_allowExposureBiasForMode:(NSInteger)mode
{
	NSString *key1 = @"CAMExposureBiasSliderPano";
	NSString *key2 = @"CAMExposureBiasSliderTimeLapse";
	BOOL allow1 = [mbDefaults()[key1] boolValue] && mode == 3;
	BOOL allow2 = [mbDefaults()[key2] boolValue] && mode == 6;
	return (allow1 || allow2) ? YES : %orig;
}

- (BOOL)_allowFocusRectPanning
{
	return [mbDefaults()[@"CAMFocusRectPanning"] boolValue] ||
			[mbDefaults()[@"CAMEnableSeparateExposure"] boolValue];
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

%hook ApplicationViewController

- (void)loadView
{
	%orig;
	CAMCameraView *cameraView = MSHookIvar<CAMCameraView *>(self, "_cameraView");
	if (cameraView)
		[cameraView _updateForFocusCapabilities];
}

%end

%hook PreviewView

- (BOOL)_enableExposureBias
{
	NSString *key = @"CAMExposureBiasSlider";
	id val = mbDefaults()[key];
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

%ctor
{
	BOOL iOS9 = isiOS9Up;
	%init(CaptureController = iOS9 ? objc_getClass("CMKCaptureController") : objc_getClass("CAMCaptureController"),
			CameraView = iOS9 ? objc_getClass("CMKCameraView") : objc_getClass("CAMCameraView"),
			ApplicationViewController = iOS9 ? objc_getClass("CMKApplicationViewController") : objc_getClass("CAMApplicationViewController"),
			PreviewView = iOS9 ? objc_getClass("CMKPreviewView") : objc_getClass("CAMPreviewView"));
}