#import <Preferences/Preferences.h>
#import <Social/SLComposeViewController.h>
#import <Social/SLServiceTypes.h>
#import "../include/UIAlertController.h"

static NSString *const settingsPath = @"/var/mobile/Library/Preferences/se.nosskirneh.snooscreens.plist";
static NSDictionary *prefs;

@interface SSSubredditListController : PSListController {
    int subNumber;
}
@end

@interface SnooScreensListController: PSEditableListController <UITableViewDataSource> {
    NSMutableArray *specifiers;
    UILabel *tweakName;
    UILabel *devName;
}
@end

@implementation SnooScreensListController
NSString *tweakName = @"SnooScreens";

- (id)specifiers {
	if(_specifiers == nil) {
        extern NSString *PSDeletionActionKey;
        specifiers = [[NSMutableArray alloc] init];
        PSSpecifier *spec;
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"SSCustomCell" forKey:@"footerCellClass"];
        [specifiers addObject:spec];
        spec = [PSSpecifier emptyGroupSpecifier];
        [specifiers addObject:spec];
        prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
        int count = [prefs objectForKey:@"count"] ? [[prefs objectForKey:@"count"] intValue] : 1;

        for (int i = 1; i <= count; i++) {
            spec = [PSSpecifier preferenceSpecifierNamed:[NSString stringWithFormat:@"Subreddit %d", i]
                                                  target:self
                                                     set:NULL
                                                     get:NULL
                                                  detail:NSClassFromString(@"SSSubredditListController")
                                                    cell:PSLinkCell
                                                    edit:Nil];
            [spec setProperty:@(i) forKey:@"subNumber"];
            [spec setProperty:[prefs objectForKey:[NSString stringWithFormat:@"sub%d-subreddit", i]] forKey:@"subreddit"];
            [spec setProperty:NSClassFromString(@"SSSubredditCell") forKey:@"cellClass"];
            [spec setProperty:NSStringFromSelector(@selector(removedSpecifier:)) forKey:PSDeletionActionKey];
            [specifiers addObject:spec];
        }

        spec = [PSSpecifier preferenceSpecifierNamed:@"Add subreddit..."
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSButtonCell
                                                edit:Nil];
        spec->action = @selector(newSubreddit);
        [spec setProperty:NSClassFromString(@"SSTintedCell") forKey:@"cellClass"];
        [specifiers addObject:spec];

        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Saves the wallpaper you currently have set" forKey:@"footerText"];
        [specifiers addObject:spec];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Save Wallpaper"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSButtonCell
                                                edit:Nil];
        spec->action = @selector(saveWallpaper);
        [spec setProperty:NSClassFromString(@"SSTintedCell") forKey:@"cellClass"];
        [specifiers addObject:spec];
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Credits, thanks, and more" forKey:@"footerText"];
        [specifiers addObject:spec];
        spec = [PSSpecifier preferenceSpecifierNamed:@"More"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:NSClassFromString(@"SSCreditsListController")
                                                cell:PSLinkCell
                                                edit:Nil];
        [specifiers addObject:spec];
        _specifiers = [[NSArray arrayWithArray:specifiers] retain];
	}
	return _specifiers;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    int width = [[UIScreen mainScreen] bounds].size.width;
    CGRect frame1 = CGRectMake(0, 10, width, 60);
    CGRect frame2 = CGRectMake(0, 50, width, 60);

    tweakName = [[UILabel alloc] initWithFrame:frame1];
    [tweakName setNumberOfLines:1];
    tweakName.font = [UIFont fontWithName:@"HelveticaNeue-Ultralight" size:40];
    [tweakName setText:@"SnooScreens"];
    [tweakName setBackgroundColor:[UIColor clearColor]];
    tweakName.textColor = [UIColor /*colorWithRed:99.0f/255.0f green:99.0f/255.0f blue:99.0f/255.0f alpha:1.0*/blackColor];
    tweakName.textAlignment = NSTextAlignmentCenter;

    devName = [[UILabel alloc] initWithFrame:frame2];
    [devName setNumberOfLines:1];
    devName.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20];
    [devName setText:@"forked by Andreas Henriksson"];
    [devName setBackgroundColor:[UIColor clearColor]];
    devName.textColor = [UIColor grayColor];
    devName.textAlignment = NSTextAlignmentCenter;

    [self.table addSubview:tweakName];
    [self.table addSubview:devName];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (!self.isMovingToParentViewController) {
        [self reloadSpecifiers];
    }
}

- (id)_editButtonBarItem {
    return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
                                                         target:self
                                                         action:@selector(tweetSweetNothings:)];
}

- (void)tweetSweetNothings:(id)sender {
    SLComposeViewController *composeController = [SLComposeViewController
                                                  composeViewControllerForServiceType:SLServiceTypeTwitter];
    [composeController setInitialText:@"I downloaded #SnooScreens by @JamesIscNeutron and I love it!"];
    [self presentViewController:composeController
                       animated:YES
                     completion:nil];
}

- (void)saveWallpaper {
    NSString *link;
    prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    link = [prefs objectForKey:@"currentWallpaper"];
    if (!link) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"SnooScreens"
                                                                                 message:@"You don't have a wallpaper link saved! This means that you last used this on an older version that did not yet support this feature. After setting another wallpaper with SnooScreens, this feature should work."
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

    NSURL *url = [NSURL URLWithString:link];
    NSError *imageError = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:url] returningResponse:nil error:&imageError];

    if (imageError) {
        //HBLogDebug(@"[%@] Error downloading image: %@", tweakName, imageError);
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"SnooScreens"
                                                                                 message:[NSString stringWithFormat:@"There was an error downloading the image %@ from imgur. Perhaps imgur is blocked on your Internet connection?", url]
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

    UIImage *rawImage = [UIImage imageWithData:data];
    UIImageWriteToSavedPhotosAlbum(rawImage, nil, nil, nil);
}

- (void)newSubreddit {
    prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    int count = [prefs objectForKey:@"count"] ? [[prefs objectForKey:@"count"] intValue] : 1;
    count++;

    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:prefs];
    [defaults setObject:[NSNumber numberWithInt:count] forKey:@"count"];
    [defaults writeToFile:settingsPath atomically:YES];
    [self reloadSpecifiers];
}

- (void)removedSpecifier:(PSSpecifier *)specifier {
    prefs = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    int count = [prefs objectForKey:@"count"] ? [[prefs objectForKey:@"count"] intValue] : 1;
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:prefs];
    int index = [specifier.properties[@"subNumber"] intValue];

    for (int i = index; i <= count; i++) {
        NSArray *keys = @[ @"-subreddit",
                           @"-wallpaperMode",
                           @"-allowBoobies",
                           @"-savePhoto",
                           @"-random" ];
        for (NSString *key in keys) {
            NSString *currentKey = [NSString stringWithFormat:@"sub%d%@", i+1, key];
            NSString *newKey = [NSString stringWithFormat:@"sub%d%@", i, key];
            id object = [defaults objectForKey:currentKey];
            if (object)
                [defaults setObject:object forKey:newKey];
            else
                [defaults removeObjectForKey:newKey];
        }
    }

    count--;
    [defaults setObject:@(count) forKey:@"count"];
    [defaults writeToFile:settingsPath atomically:YES];
    [self performSelector:@selector(reloadSpecifiers) withObject:nil afterDelay:0.3f];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return YES if you want the specified item to be editable.
    //HBLogDebug(@"indexPath: %@, length: %lu", indexPath, (unsigned long)indexPath.length);
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if ([cell.textLabel.text isEqualToString:@"More"]) {
        return NO;
    }
    return YES;
}

@end

@interface SSCustomCell : PSTableCell
@end

@implementation SSCustomCell

- (id)initWithSpecifier:(id)specifier {
    return [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell" specifier:specifier];
}

- (CGFloat)preferredHeightForWidth:(CGFloat)arg1 {
    return 90.f;
}

@end

@interface SSCreditsListController: PSListController
@end
@implementation SSCreditsListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [[self loadSpecifiersFromPlistName:@"credits" target:self] retain];
    }
    return _specifiers;
}

- (void)openMiloTwitter {
    if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetbot:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetbot:///user_profile/JamesIscNeutron"]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitterrific:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitterrific:///profile?screen_name=JamesIscNeutron"]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"tweetings:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"tweetings:///user?screen_name=JamesIscNeutron"]];
    else if ([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:@"twitter:"]])
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"twitter://user?screen_name=JamesIscNeutron"]];
    else
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://mobile.twitter.com/JamesIscNeutron"]];
}

- (void)openGitHub {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/nosskirneh/SnooScreens"]];
}

- (void)openMiloReddit {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.reddit.com/user/James-Isaac-Neutron"]];
}

@end

@implementation SSSubredditListController

- (void)setSpecifier:(PSSpecifier *)specifier {
    subNumber = [specifier.properties[@"subNumber"] intValue];
    [super setSpecifier:specifier];
    
}

- (id)specifiers {
    if (_specifiers == nil) {
        //HBLogDebug(@"[SnooScreens] We got called!");
        NSMutableArray *specifiers = [[NSMutableArray alloc] init];
        NSString *methodName = [NSString stringWithFormat:@"sub%d", subNumber];

        //HBLogDebug(@"Creating first specifier");
        NSArray *suggestions = [NSArray arrayWithObjects:@"Need a suggestion? How about /r/EarthPorn?",
                                                         @"Here's a tip: I support mulitreddits! Try /user/CastleCorp/m/find_me_wallpapers",
                                                         @"Can't think of a subreddit? Why not /r/wallpaper?",
                                                         @"Out of ideas? Try /r/spaceporn!",
                                                         @"Need another suggestion? How does /r/CityPorn sound?",
                                                         @"There's even a subreddit for wallpapers that look nice with SnooScreens! Try /r/SnooScreens!",
                                                         nil];
        int randomIndex = arc4random_uniform([suggestions count]);
        PSSpecifier *spec = [PSSpecifier groupSpecifierWithHeader:[NSString stringWithFormat:@"Subreddit %d", subNumber]
                                                           footer:[suggestions objectAtIndex:randomIndex]];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating second specifier");
        PSTextFieldSpecifier *textSpec = [PSTextFieldSpecifier preferenceSpecifierNamed:@"Subreddit"
                                                                                target:self
                                                                                   set:@selector(setPreferenceValue:specifier:)
                                                                                   get:@selector(readPreferenceValue:)
                                                                                detail:Nil
                                                                                  cell:PSEditTextCell
                                                                                  edit:Nil];
        [textSpec setProperty:@"/r/" forKey:@"default"];
        [textSpec setProperty:[NSString stringWithFormat:@"%@-subreddit", methodName] forKey:@"key"];
        [specifiers addObject:textSpec];

        [specifiers addObject:[PSSpecifier emptyGroupSpecifier]];

        spec = [PSSpecifier preferenceSpecifierNamed:@"Enabled"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:[NSString stringWithFormat:@"%@-enabled", methodName] forKey:@"key"];
        [spec setProperty:@YES forKey:@"default"];
        [specifiers addObject:spec];


        //HBLogDebug(@"Creating third specifier");
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Pick an activation method for this subreddit." forKey:@"footerText"];
        [spec setProperty:@"PSGroupCell" forKey:@"cell"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating fourth specifier");
        spec = [PSSpecifier preferenceSpecifierNamed:@"Activation Method"
                                              target:self
                                                 set:NULL
                                                 get:NULL
                                              detail:Nil
                                                cell:PSLinkCell
                                                edit:Nil];
        [spec setProperty:@YES forKey:@"isContoller"];
        [spec setProperty:[NSString stringWithFormat:@"se.nosskirneh.snooscreens.%@", methodName] forKey:@"activatorListener"];
        [spec setProperty:@"/System/Library/PreferenceBundles/LibActivator.bundle" forKey:@"lazy-bundle"];
        spec->action = @selector(lazyLoadBundle:);
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating fifth specifier");
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Apply to home screen, lock screen, or both." forKey:@"footerText"];
        [spec setProperty:@"PSGroupCell" forKey:@"cell"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating sixth specifier");
        spec = [PSSpecifier preferenceSpecifierNamed:@"Set to"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:NSClassFromString(@"PSListItemsController")
                                                cell:PSLinkListCell
                                                edit:Nil];
        [spec setProperty:[NSString stringWithFormat:@"%@-wallpaperMode", methodName] forKey:@"key"];
        [spec setProperty:NSStringFromSelector(@selector(titlesDataSource)) forKey:@"titlesDataSource"];
        [spec setProperty:NSStringFromSelector(@selector(valuesDataSource)) forKey:@"valuesDataSource"];
        //spec->_values = [NSArray arrayWithObjects:@"1", @"2", @"0", nil];
        [spec setProperty:@"0" forKey:@"default"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating seventh specifier");
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Allow NSFW images to be saved & set as your wallpaper." forKey:@"footerText"];
        [spec setProperty:@"PSGroupCell" forKey:@"cell"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating eighth specifier");
        spec = [PSSpecifier preferenceSpecifierNamed:@"Allow NSFW images"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:[NSString stringWithFormat:@"%@-allowBoobies", methodName] forKey:@"key"];
        [spec setProperty:@NO forKey:@"default"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating ninth specifier");
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Save the photo to your photo library after setting it as your wallpaper." forKey:@"footerText"];
        [spec setProperty:@"PSGroupCell" forKey:@"cell"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating tenth specifier");
        spec = [PSSpecifier preferenceSpecifierNamed:@"Save photo"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:[NSString stringWithFormat:@"%@-savePhoto", methodName] forKey:@"key"];
        [spec setProperty:@NO forKey:@"default"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating eleventh specifier");
        spec = [PSSpecifier emptyGroupSpecifier];
        [spec setProperty:@"Use a random image. If this is disabled, the top image will be grabbed." forKey:@"footerText"];
        [spec setProperty:@"PSGroupCell" forKey:@"cell"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating twelfth specifier");
        spec = [PSSpecifier preferenceSpecifierNamed:@"Random image"
                                              target:self
                                                 set:@selector(setPreferenceValue:specifier:)
                                                 get:@selector(readPreferenceValue:)
                                              detail:Nil
                                                cell:PSSwitchCell
                                                edit:Nil];
        [spec setProperty:[NSString stringWithFormat:@"%@-random", methodName] forKey:@"key"];
        [spec setProperty:@NO forKey:@"default"];
        [specifiers addObject:spec];

        //HBLogDebug(@"Creating _specifiers");
        _specifiers = [[specifiers copy] retain];
    }
    //HBLogDebug(@"returning _specifiers");
    return _specifiers;
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.view endEditing:YES];
    [super viewWillDisappear:animated];
}

- (id) readPreferenceValue:(PSSpecifier*)specifier {
    NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:settingsPath];
    if (!exampleTweakSettings[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return exampleTweakSettings[specifier.properties[@"key"]];
}

- (void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    [defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:settingsPath]];
    [defaults setObject:value forKey:specifier.properties[@"key"]];
    [defaults writeToFile:settingsPath atomically:YES];

    if ([[specifier name] isEqualToString:@"Subreddit"])
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("se.nosskirneh.snooscreens/updateListeners"), NULL, NULL, YES);
    else
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("se.nosskirneh.snooscreens/prefsChanged"), NULL, NULL, YES);
}

- (NSArray *)titlesDataSource {
    return [NSArray arrayWithObjects:@"Home Screen", @"Lock Screen", @"Both", nil];
}

- (NSArray *)valuesDataSource {
    return [NSArray arrayWithObjects:@"1", @"2", @"0", nil];
}

- (void)loadView {
    [super loadView];
    self.navigationItem.title = [NSString stringWithFormat:@"Subreddit %d", subNumber];
}

@end

@interface SnooScreensDevCell : PSTableCell {
    UIImageView *_background;
    UILabel *devName;
    UILabel *devRealName;
    UILabel *jobSubtitle;
}
@end

@implementation SnooScreensDevCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])){
        UIImage *bkIm = [[UIImage alloc] initWithContentsOfFile:@"/Library/PreferenceBundles/SnooScreens.bundle/milo@2x.png"];
        _background = [[UIImageView alloc] initWithImage:bkIm];
        _background.frame = CGRectMake(10, 15, 70, 70);
        [self addSubview:_background];

        CGRect frame = [self frame];

        devName = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 95,
                                                            frame.origin.y + 10,
                                                            frame.size.width,
                                                            frame.size.height)];
        [devName setText:@"Milo Darling"];
        [devName setBackgroundColor:[UIColor clearColor]];
        [devName setTextColor:[UIColor blackColor]];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            [devName setFont:[UIFont fontWithName:@"Helvetica Light" size:30]];
        else
            [devName setFont:[UIFont fontWithName:@"Helvetica Light" size:23]];
        
        [self addSubview:devName];

        devRealName = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 95,
                                                                frame.origin.y + 30,
                                                                frame.size.width,
                                                                frame.size.height)];
        [devRealName setText:@"Original author"];
        [devRealName setTextColor:[UIColor grayColor]];
        [devRealName setBackgroundColor:[UIColor clearColor]];
        [devRealName setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];

        [self addSubview:devRealName];

        jobSubtitle = [[UILabel alloc] initWithFrame:CGRectMake(frame.origin.x + 95,
                                                                frame.origin.y + 50,
                                                                frame.size.width,
                                                                frame.size.height)];
        [jobSubtitle setText:@"@JamesIscNeutron"];
        [jobSubtitle setTextColor:[UIColor grayColor]];
        [jobSubtitle setBackgroundColor:[UIColor clearColor]];
        [jobSubtitle setFont:[UIFont fontWithName:@"Helvetica Light" size:15]];

        [self addSubview:jobSubtitle];
    }
    return self;
}

@end

@interface SSTintedCell : PSTableCell
@end
@implementation SSTintedCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.textLabel.textColor = [UIColor colorWithRed:48.0f/255.0f
                                               green:56.0f/255.0f
                                                blue:103.0f/255.0f
                                               alpha:1.0];
}

@end

@interface SSSubredditCell : PSTableCell
@end

@implementation SSSubredditCell

- (void)layoutSubviews {
    [super layoutSubviews];

    self.detailTextLabel.text = self.specifier.properties[@"subreddit"];
    self.detailTextLabel.textColor = [UIColor colorWithWhite:0.5568627451f alpha:1];
}

@end
