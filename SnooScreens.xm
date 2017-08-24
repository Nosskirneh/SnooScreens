#import <PhotoLibrary/PLStaticWallpaperImageViewController.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoardFoundation/SBFWallpaperParallaxSettings.h>
#import <UIKit/UIKit.h>
#import <libactivator/libactivator.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <substrate.h>
#import "include/UIAlertController.h"
#import <SpringBoard/SBWiFiManager.h>

@interface SnooScreens : NSObject<LAListener> {
    int listenerCount;
    int wallpaperMode;
    NSString *imgurLink;
    BOOL isNSFW;
}
@end

SnooScreens *listener;

static NSString *const settingsPath = @"/var/mobile/Library/Preferences/se.nosskirneh.snooscreens.plist";
static NSString *const tweakName = @"SnooScreens";


static inline int FPWListenerName(NSString *listenerName) {
    return [[listenerName substringFromIndex:29] intValue];
}

@implementation SnooScreens

- (id)init {
    if (self = [super init]) {
        listenerCount = 0;
        [self updateListeners];
    }
    return self;
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];

        // Collect preferences etc
        int en = FPWListenerName(listenerName);
        NSString *mode = [NSString stringWithFormat:@"sub%d-", en];
        NSNumber *obj = [prefs objectForKey:[NSString stringWithFormat:@"%@enabled", mode]];
        BOOL enabled = obj ? [obj boolValue] : YES;
        if (!enabled) {
            [event setHandled:NO];
            return;
        }

        // Check WiFi setting and state
        obj = [prefs objectForKey:[NSString stringWithFormat:@"%@onlyWiFi", mode]];
        BOOL onlyWiFi = obj ? [obj boolValue] : YES;
        if (onlyWiFi && ![[%c(SBWiFiManager) sharedInstance] currentNetworkName]) {
            //HBLogDebug(@"No WiFi connection");
            [event setHandled:NO];
            return;
        }

        [event setHandled:YES];
        NSString *subreddit = [prefs objectForKey:[NSString stringWithFormat:@"%@subreddit", mode]] ?: @"No subreddit chosen";
        BOOL allowBoobies = [[prefs objectForKey:[NSString stringWithFormat:@"%@allowBoobies", mode]] boolValue];
        wallpaperMode = [[prefs objectForKey:[NSString stringWithFormat:@"%@wallpaperMode", mode]] intValue] ?: 0;

        // Parse URL
        subreddit = [subreddit stringByReplacingOccurrencesOfString:@" " withString:@""];
        //HBLogDebug(@"Subreddit: %@", subreddit);
        NSURL *blogURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://www.reddit.com%@.json", subreddit]];
        NSError *jsonDataError = nil;
        NSData *jsonData = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:blogURL] returningResponse:nil error:&jsonDataError];

        if (jsonDataError) {
            //HBLogDebug(@"Error downloading json data: %@", jsonDataError);
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                                                     message:@"We couldn't get the image :(. Perhaps you've typed in a subreddit incorrectly, or you're not connected to the internet?"
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel 
                                                      handler:^(UIAlertAction * _Nonnull action) {
               [alertController dismissViewControllerAnimated:YES completion:nil];
            }]];

            [alertController show];
            [alertController release];
            return;
        }

        NSError *jsonError = nil;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
        if (jsonError) {
            //HBLogDebug(@"[%@] JSON Error: %@", tweakName, jsonError);
            return;
        }

        int arrayLength = [json[@"data"][@"children"] count];
        if (arrayLength == 0) {
            UIAlertController *noSubredditAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                                                      message:@"It appears the subreddit you've entered doesn't exist."
                                                                               preferredStyle:UIAlertControllerStyleAlert];

            [noSubredditAlert addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel 
                                                      handler:^(UIAlertAction * _Nonnull action) {
               [noSubredditAlert dismissViewControllerAnimated:YES completion:nil];
            }]];

            [noSubredditAlert show];
            [noSubredditAlert release];
            return;
        }

        if ([[prefs objectForKey:[NSString stringWithFormat:@"%@random", mode]] boolValue]) {
            NSMutableArray *badNumbers = [[NSMutableArray alloc] init];
            int count = 0;
            do {
                int i = arc4random_uniform(arrayLength);
                NSNumber *iInIDForm = [NSNumber numberWithInt:i];
                if ([badNumbers containsObject:iInIDForm]) {
                    continue;
                }

                imgurLink = json[@"data"][@"children"][i][@"data"][@"url"];
                isNSFW = [json[@"data"][@"children"][i][@"data"][@"over_18"] boolValue];
                [badNumbers addObject:iInIDForm];
                count++;
            } while (!(([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) &&
                ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) &&
                (!isNSFW || allowBoobies) &&
                ![[prefs objectForKey:@"currentRedditLink"] isEqualToString:imgurLink]) &&
                count<arrayLength);
            [badNumbers release];
        } else {
            for (int i=0; i<arrayLength; i++) {
                imgurLink = json[@"data"][@"children"][i][@"data"][@"url"];
                isNSFW = [json[@"data"][@"children"][i][@"data"][@"over_18"] boolValue];
                if (([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) &&
                    ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) &&
                    (!isNSFW || allowBoobies) &&
                    ![[prefs objectForKey:@"currentRedditLink"] isEqualToString:imgurLink]) {
                    break;
                }
            }
        }

        if (!(([imgurLink rangeOfString:@"imgur.com"].location != NSNotFound) &&
            ([imgurLink rangeOfString:@"/a/"].location == NSNotFound) &&
            (!isNSFW || allowBoobies))) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                                                     message:[NSString stringWithFormat:@"I didn't find any images that meet your criteria on the front page of %@.", subreddit]
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel 
                                                      handler:^(UIAlertAction * _Nonnull action) {
               [alertController dismissViewControllerAnimated:YES completion:nil];
            }]];

            [alertController show];
            [alertController release];
            return;
        }

        // Save as a preference so we don't reuse the same image.
        [self setPreferenceObject:imgurLink forKey:@"currentRedditLink"];
        //HBLogDebug(@"Final link: %@", [prefs objectForKey:@"currentRedditLink"]);

        // Convert imgur.com links to i.imgur.com
        NSString *finalLink = @"";
        if ([imgurLink rangeOfString:@"i.imgur.com"].location == NSNotFound) {
            for (int i = 0; i < [imgurLink length]; i++) {
                finalLink = [NSString stringWithFormat:@"%@%c", finalLink, [imgurLink characterAtIndex:i]];
                if ([imgurLink characterAtIndex:i] == '/' &&
                    [imgurLink characterAtIndex:i - 1] == '/') {
                    finalLink = [NSString stringWithFormat:@"%@i.", finalLink];
                }
            }
            finalLink = [NSString stringWithFormat:@"%@.jpg", finalLink];
        } else {
            finalLink = imgurLink;
        }

        //HBLogDebug(@"Link: %@", finalLink);
        NSURL *url = [NSURL URLWithString:finalLink];
        //HBLogDebug(@"URL: %@", url);
        [self setPreferenceObject:finalLink forKey:@"currentWallpaper"];

        // Download image
        NSError *imageError = nil;
        NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url]
                                             returningResponse:nil
                                                         error:&imageError];
        if (imageError) {
            //HBLogDebug(@"[%@] Error downloading image: %@", tweakName, imageError);
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@", tweakName]
                                                                                     message:[NSString stringWithFormat:@"There was an error downloading the image %@ from imgur. Perhaps imgur is blocked on your Internet connection? %@.", url, subreddit]
                                                                              preferredStyle:UIAlertControllerStyleAlert];

            [alertController addAction:[UIAlertAction actionWithTitle:@"OK"
                                                      style:UIAlertActionStyleCancel 
                                                      handler:^(UIAlertAction * _Nonnull action) {
               [alertController dismissViewControllerAnimated:YES completion:nil];
            }]];

            [alertController show];
            [alertController release];
        }
        UIImage *rawImage = [UIImage imageWithData:data];

        // Crop image
        CGSize screenSize = [SBFWallpaperParallaxSettings minimumWallpaperSizeForCurrentDevice];
        float ratio = screenSize.height/screenSize.width;

        CGRect rect;
        if ((rawImage.size.height/rawImage.size.width)>ratio) {
            rect = CGRectMake(0.0f,
                              (rawImage.size.height - rawImage.size.width * ratio) * 0.5f,
                              rawImage.size.width,
                              rawImage.size.width * ratio);
        } else {
            rect = CGRectMake((rawImage.size.width - rawImage.size.height / ratio) * 0.5f,
                              0.0f,
                              (rawImage.size.height / ratio),
                              rawImage.size.height);
        }

        CGImageRef imageRef = CGImageCreateWithImageInRect([rawImage CGImage], rect);
        UIImage *image = [[[UIImage alloc] initWithCGImage:imageRef] autorelease];
        CGImageRelease(imageRef);

        // Set wallpaper
        PLStaticWallpaperImageViewController *wallpaperViewController = [[[PLStaticWallpaperImageViewController alloc] initWithUIImage:image] autorelease];
        wallpaperViewController.saveWallpaperData = YES;

        MSHookIvar<int>(wallpaperViewController, "_wallpaperMode") = wallpaperMode;

        [wallpaperViewController _savePhoto];

        if ([[prefs objectForKey:[NSString stringWithFormat:@"%@savePhoto", mode]] boolValue]) {
            UIImageWriteToSavedPhotosAlbum(rawImage, nil, nil, nil);
        }

        [self loadPrefs];
    });
    
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedGroupForListenerName:(NSString *)listenerName {
    return @"SnooScreens";
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedTitleForListenerName:(NSString *)listenerName {
    int en = FPWListenerName(listenerName);
    return [NSString stringWithFormat:@"Subreddit %d", en];
}

- (NSString *)activator:(LAActivator *)activator requiresLocalizedDescriptionForListenerName:(NSString *)listenerName {
    int en = FPWListenerName(listenerName);
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    return [prefs objectForKey:[NSString stringWithFormat:@"sub%d-subreddit", en]] ?: @"No subreddit chosen";
}

- (NSArray *)activator:(LAActivator *)activator requiresCompatibleEventModesForListenerWithName:(NSString *)listenerName {
    return [NSArray arrayWithObjects:@"springboard", @"lockscreen", @"application", nil];
}

- (NSArray *)activator:(LAActivator *)activator requiresExclusiveAssignmentGroupsForListenerName:(NSString *)listenerName {
    return @[];
}

- (NSData *)activator:(LAActivator *)activator requiresSmallIconDataForListenerName:(NSString *)listenerName scale:(CGFloat *)scale {
    if (*scale == 1.0) {
        return [NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/SnooScreens.bundle/SnooScreens.png"];
    } else {
        return [NSData dataWithContentsOfFile:@"/Library/PreferenceBundles/SnooScreens.bundle/SnooScreens@2x.png"];
    }
}

- (void)setPreferenceObject:(id)object forKey:(NSString *)key {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:settingsPath];
    [dict setObject:object forKey:key];
    [dict writeToFile:settingsPath atomically:YES];
}

- (void)updateListeners {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    if (listenerCount) {
        for (int i = 1; i <= listenerCount; i++) {
            [[LAActivator sharedInstance] unregisterListenerWithName:[NSString stringWithFormat:@"se.nosskirneh.snooscreens.sub%d", i]];
        }
    }

    [self loadPrefs]; // gets new count value
    for (int i = 1; i <= listenerCount; i++) {
        [[LAActivator sharedInstance] registerListener:self forName:[NSString stringWithFormat:@"se.nosskirneh.snooscreens.sub%d", i]];
    }
    [pool drain];
}

- (void)loadPrefs {
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    listenerCount = [[prefs objectForKey:@"count"] intValue];
}

@end

static void loadPreferences() {
    [listener loadPrefs];
}

static void updateListeners() {
    [listener updateListeners];
}

%ctor {
    listener = [[SnooScreens alloc] init];
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)loadPreferences,
                                    CFSTR("se.nosskirneh.snooscreens/prefsChanged"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
                                    NULL,
                                    (CFNotificationCallback)updateListeners,
                                    CFSTR("se.nosskirneh.snooscreens/updateListeners"),
                                    NULL,
                                    CFNotificationSuspensionBehaviorDeliverImmediately);
}
