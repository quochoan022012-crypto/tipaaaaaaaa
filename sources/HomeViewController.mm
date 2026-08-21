#import "HomeViewController.h"
#import "oxorany.h" // Nếu file header oxorany nằm ở thư mục khác, đảm bảo nó được include đúng hoặc nằm trong thư mục oxorany/
#import <QuartzCore/QuartzCore.h>

// Khai báo các hàm ngoại vi hệ thống và API client
extern void SetHUDEnabled(BOOL enabled);
extern BOOL IsHUDEnabled(void);
extern int GetGameProcesspid(char *name);


// ========== THỜI GIAN TỰ ĐỘNG THOÁT ==========
static const CFTimeInterval kAutoExitTimeout = 30.0; // 30 giây
// =============================================

@interface HomeViewController ()

@property (nonatomic, strong) UILabel  *titleLabel;
@property (nonatomic, strong) UILabel  *subTitleLabel;
@property (nonatomic, strong) UIView   *cardView;
@property (nonatomic, strong) UIView   *glowView;
@property (nonatomic, strong) UILabel  *hudLabel;
@property (nonatomic, strong) UILabel  *hudStatusLabel;
@property (nonatomic, strong) UISwitch *hudSwitch;
@property (nonatomic, strong) UILabel  *descLabel;
@property (nonatomic, strong) UILabel  *autoCleanLabel;
@property (nonatomic, strong) UISwitch *autoCleanSwitch;
@property (nonatomic, strong) UIView   *statusDot;
@property (nonatomic, strong) NSTimer  *pollTimer;
@property (nonatomic, strong) NSTimer  *autoExitTimer;

@property (nonatomic, assign) BOOL      lastGameRunning;
@property (nonatomic, assign) NSInteger gameMissingStreak;
@property (nonatomic, assign) CFTimeInterval pendingHUDEnableUntil;

@end

static CGRect MakeFrameRectHelper(CGFloat x, CGFloat y, CGFloat w, CGFloat h) {
    return CGRectMake(x, y, w, h);
}

@implementation HomeViewController

#pragma mark - Integrity Check Info.plist

- (void)checkInfoPlistIntegrity {
    NSDictionary *infoDict = [[NSBundle mainBundle] infoDictionary];
    
    NSString *displayName = infoDict[@"CFBundleDisplayName"];
    NSString *versionString = infoDict[@"CFBundleVersion"];
    
    NSString *originalName = @"Banana cheat"; 
    NSString *originalVersion = @"Telegram:@anhtua3";
    
    if (![displayName isEqualToString:originalName] || ![versionString isEqualToString:originalVersion]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"CẢNH BÁO BẢN QUYỀN"
                                                                            message:@"Phát hiện file ứng dụng đã bị chỉnh sửa thông tin bất hợp pháp! Ứng dụng sẽ tự đóng."
                                                                     preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"Thoát" 
                                                                 style:UIAlertActionStyleDestructive 
                                                               handler:^(UIAlertAction * action) {
                exit(0);
            }];
            
            [alert addAction:exitAction];
            
            UIViewController *top = [self topPresentedViewController];
            [top presentViewController:alert animated:YES completion:nil];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            exit(0);
        });
    }
}

#pragma mark - Gradient

- (CAGradientLayer *)gradientLayerForView:(UIView *)view {
    CAGradientLayer *g = [CAGradientLayer layer];
    g.frame = view.bounds;
    g.colors = @[
        (__bridge id)[UIColor colorWithWhite:0.12 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0.10 alpha:1.0].CGColor,
        (__bridge id)[UIColor colorWithWhite:0.08 alpha:1.0].CGColor
    ];
    g.startPoint   = CGPointMake(0, 0);
    g.endPoint     = CGPointMake(1, 1);
    g.cornerRadius = 28.0;
    return g;
}

- (void)autoExitApp {
    NSLog(@"⏰ [AutoExit] Đã %d giây - Tự động đóng app", (int)kAutoExitTimeout);
    SetHUDEnabled(NO);
    exit(0);
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self checkInfoPlistIntegrity];
    
    self.view.backgroundColor  = [UIColor blackColor];

    UIView *bgGlow = [[UIView alloc] initWithFrame:self.view.bounds];
    bgGlow.autoresizingMask       = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    bgGlow.userInteractionEnabled = NO;
    bgGlow.backgroundColor        = [[UIColor whiteColor] colorWithAlphaComponent:0.01];
    [self.view addSubview:bgGlow];

    _titleLabel                    = [[UILabel alloc] initWithFrame:CGRectZero];
    _titleLabel.text               = @"HOME";
    _titleLabel.font               = [UIFont systemFontOfSize:42 weight:UIFontWeightBlack];
    _titleLabel.textColor          = [UIColor whiteColor];
    _titleLabel.layer.shadowColor  = [UIColor whiteColor].CGColor;
    _titleLabel.layer.shadowOpacity = 0.15f;
    _titleLabel.layer.shadowRadius = 16.0f;
    _titleLabel.layer.shadowOffset = CGSizeZero;
    [self.view addSubview:_titleLabel];

    _subTitleLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
    _subTitleLabel.text      = @"FREE FIRE HUD PANEL";
    _subTitleLabel.font      = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    _subTitleLabel.textColor = [UIColor colorWithWhite:1 alpha:0.55];
    [self.view addSubview:_subTitleLabel];

    _glowView                     = [[UIView alloc] initWithFrame:CGRectZero];
    _glowView.backgroundColor       = [[UIColor blackColor] colorWithAlphaComponent:0.2];
    _glowView.layer.cornerRadius  = 34.0f;
    _glowView.layer.shadowColor   = [UIColor whiteColor].CGColor;
    _glowView.layer.shadowOpacity = 0.05f;
    _glowView.layer.shadowRadius  = 45.0f;
    _glowView.layer.shadowOffset  = CGSizeZero;
    [self.view addSubview:_glowView];

    _cardView                     = [[UIView alloc] initWithFrame:CGRectZero];
    _cardView.layer.cornerRadius  = 28.0f;
    _cardView.clipsToBounds       = YES;
    _cardView.backgroundColor       = [UIColor clearColor];
    [self.view addSubview:_cardView];
    [_cardView.layer insertSublayer:[self gradientLayerForView:_cardView] atIndex:0];
    _cardView.layer.borderWidth = 1.2f;
    _cardView.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08].CGColor;

    _hudLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
    _hudLabel.text      = @"HUD MENU";
    _hudLabel.font      = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    _hudLabel.textColor = [UIColor whiteColor];
    [_cardView addSubview:_hudLabel];

    _hudStatusLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
    _hudStatusLabel.font      = [UIFont systemFontOfSize:12 weight:UIFontWeightBold];
    _hudStatusLabel.textColor = [UIColor whiteColor];
    _hudStatusLabel.text      = @"ONLINE";
    [_cardView addSubview:_hudStatusLabel];

    _statusDot                     = [[UIView alloc] initWithFrame:CGRectZero];
    _statusDot.backgroundColor     = [UIColor whiteColor];
    _statusDot.layer.cornerRadius  = 5.0f;
    _statusDot.layer.shadowColor   = [UIColor whiteColor].CGColor;
    _statusDot.layer.shadowOpacity = 0.2f;
    _statusDot.layer.shadowRadius  = 4.0f;
    _statusDot.layer.shadowOffset  = CGSizeZero;
    [_cardView addSubview:_statusDot];

    _statusDot.hidden = YES;
    _hudStatusLabel.hidden = YES;

    _hudSwitch                     = [[UISwitch alloc] initWithFrame:CGRectZero];
    _hudSwitch.onTintColor         = [UIColor whiteColor];
    _hudSwitch.thumbTintColor      = [UIColor colorWithWhite:0.2 alpha:1.0];
    _hudSwitch.layer.shadowColor   = [UIColor blackColor].CGColor;
    _hudSwitch.layer.shadowOpacity = 0.3f;
    _hudSwitch.layer.shadowRadius  = 5.0f;
    _hudSwitch.layer.shadowOffset  = CGSizeZero;
    [_hudSwitch addTarget:self
                   action:@selector(hudSwitchChanged:)
         forControlEvents:UIControlEventValueChanged];
    [_cardView addSubview:_hudSwitch];

    _descLabel                 = [[UILabel alloc] initWithFrame:CGRectZero];
    _descLabel.numberOfLines = 0;
    _descLabel.text          = @"Enable floating in-game HUD overlay system with advanced rendering and real-time touch support.";
    _descLabel.textColor     = [UIColor colorWithWhite:1 alpha:0.72];
    _descLabel.font          = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    [_cardView addSubview:_descLabel];

    UIView *line           = [[UIView alloc] initWithFrame:CGRectZero];
    line.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.08];
    line.tag               = 999;
    [_cardView addSubview:line];

    _autoCleanLabel           = [[UILabel alloc] initWithFrame:CGRectZero];
    _autoCleanLabel.text      = @"AUTO VAR CLEAN";
    _autoCleanLabel.font      = [UIFont systemFontOfSize:15 weight:UIFontWeightBold];
    _autoCleanLabel.textColor = [UIColor colorWithWhite:1 alpha:0.92];
    [_cardView addSubview:_autoCleanLabel];

    _autoCleanSwitch                     = [[UISwitch alloc] initWithFrame:CGRectZero];
    _autoCleanSwitch.onTintColor     = [UIColor whiteColor];
    _autoCleanSwitch.thumbTintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    _autoCleanSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoVarCleanBeforeHUD"];
    [_autoCleanSwitch addTarget:self
                          action:@selector(autoCleanSwitchChanged:)
                forControlEvents:UIControlEventValueChanged];
    [_cardView addSubview:_autoCleanSwitch];

    CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"shadowOpacity"];
    pulse.fromValue         = @(0.02);
    pulse.toValue           = @(0.10);
    pulse.duration          = 1.2;
    pulse.autoreverses      = YES;
    pulse.repeatCount       = HUGE_VALF;
    [_glowView.layer addAnimation:pulse forKey:@"pulseGlow"];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appBecameActive)
                                                 name:UIApplicationDidBecomeActiveNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appWillTerminate)
                                                 name:UIApplicationWillTerminateNotification
                                               object:nil];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(appDidEnterBackground)
                                                 name:UIApplicationDidEnterBackgroundNotification
                                               object:nil];

    _gameMissingStreak    = 0;
    _pendingHUDEnableUntil = 0;

    [self startAutoExitTimer];
    [self startPollingGameState];
    [self refreshHUDState];
}

- (void)startAutoExitTimer {
    [self stopAutoExitTimer]; 
    
    _autoExitTimer = [NSTimer scheduledTimerWithTimeInterval:kAutoExitTimeout
                                                     target:self
                                                   selector:@selector(autoExitApp)
                                                   userInfo:nil
                                                    repeats:NO];
}

- (void)stopAutoExitTimer {
    if (_autoExitTimer) {
        [_autoExitTimer invalidate];
        _autoExitTimer = nil;
    }
}

#pragma mark - App Lifecycle

- (void)appWillTerminate {
    SetHUDEnabled(NO);
}

- (void)appDidEnterBackground {
    if (![self isGameRunning]) {
        SetHUDEnabled(NO);
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.hudSwitch.on) [self.hudSwitch setOn:NO animated:NO];
        });
    }
}

- (void)appBecameActive {
    [self checkInfoPlistIntegrity];
    [self startAutoExitTimer];
    [self refreshHUDState];
}

#pragma mark - Top VC Helper

- (UIViewController *)topPresentedViewController {
    UIViewController *vc = self;
    while (vc.presentedViewController) vc = vc.presentedViewController;
    return vc;
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];

    UIEdgeInsets insets = self.view.safeAreaInsets;
    CGFloat w = self.view.bounds.size.width;

    _titleLabel.frame   = CGRectMake(24, insets.top + 18, w - 48, 48);
    _subTitleLabel.frame = CGRectMake(26, CGRectGetMaxY(_titleLabel.frame) + 2, 250, 18);

    @autoreleasepool {
        CGFloat cardX = 18.0f, cardW = w - 36.0f;
        CGFloat cardY = CGRectGetMaxY(_subTitleLabel.frame) + 20.0f;
        CGFloat cardH = 240.0f;

        _glowView.frame = CGRectMake(cardX + 8, cardY + 10, cardW - 16, cardH - 16);
        _cardView.frame = CGRectMake(cardX, cardY, cardW, cardH);

        for (CALayer *l in _cardView.layer.sublayers) {
            if ([l isKindOfClass:[CAGradientLayer class]]) {
                l.frame = _cardView.bounds;
            }
        }

        _hudLabel.frame       = CGRectMake(20, 20, 180, 28);
        _statusDot.frame      = CGRectMake(22, 58, 10, 10);
        _hudStatusLabel.frame = CGRectMake(40, 53, 120, 18);

        CGSize swSz = _hudSwitch.intrinsicContentSize;
        _hudSwitch.frame = CGRectMake(cardW - swSz.width - 22, 24, swSz.width, swSz.height);

        _descLabel.frame = CGRectMake(20, 88, cardW - 40, 48);

        UIView *divLine = [_cardView viewWithTag:999];
        divLine.frame   = CGRectMake(20, 152, cardW - 40, 1);

        _autoCleanLabel.frame = CGRectMake(20, 174, 200, 24);
        CGSize csSz = _autoCleanSwitch.intrinsicContentSize;
        _autoCleanSwitch.frame = MakeFrameRectHelper(cardW - csSz.width - 22, 170, csSz.width, csSz.height);
    }
}

#pragma mark - Dealloc

- (void)dealloc {
    SetHUDEnabled(NO);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_pollTimer invalidate]; _pollTimer = nil;
    [self stopAutoExitTimer];
}

#pragma mark - Game State

- (BOOL)isGameRunning {
    return GetGameProcesspid((char *)"FreeFire") != -1;
}

- (void)startPollingGameState {
    __weak __typeof(self) weakSelf = self;
    _pollTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                 repeats:YES
                                                   block:^(NSTimer *t) {
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf) [strongSelf refreshHUDState];
    }];
}

#pragma mark - Actions

- (void)autoCleanSwitchChanged:(UISwitch *)sw {
    [[NSUserDefaults standardUserDefaults] setBool:sw.on forKey:@"AutoVarCleanBeforeHUD"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)hudSwitchChanged:(UISwitch *)sw {
    if (sw.on) {
        if (![self isGameRunning]) {
            [sw setOn:NO animated:YES];
            UIAlertController *a =
                [UIAlertController alertControllerWithTitle:@"CHƯA VÀO GAME"
                                                     message:@"Vào Free Fire trước, sau đó quay lại đây bật HUD."
                                              preferredStyle:UIAlertControllerStyleAlert];
            [a addAction:[UIAlertAction actionWithTitle:@"OK"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
            [self presentViewController:a animated:YES completion:nil];
            return;
        }

        BOOL autoClean = [[NSUserDefaults standardUserDefaults] boolForKey:@"AutoVarCleanBeforeHUD"];
        _pendingHUDEnableUntil = CACurrentMediaTime() + 2.5;

        [UIView animateWithDuration:0.18
                         animations:^{ sw.transform = CGAffineTransformMakeScale(1.15, 1.15); }
                         completion:^(BOOL f) {
            [UIView animateWithDuration:0.18
                             animations:^{ sw.transform = CGAffineTransformIdentity; }];
        }];

        if (autoClean) {
            sw.enabled = NO;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                SetHUDEnabled(YES);
                sw.enabled = YES;
                [self refreshHUDState];
            });
        } else {
            SetHUDEnabled(YES);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                [self refreshHUDState];
            });
        }

    } else {
        _pendingHUDEnableUntil = 0;
        SetHUDEnabled(NO);

        [UIView animateWithDuration:0.18
                         animations:^{ sw.transform = CGAffineTransformMakeScale(1.15, 1.15); }
                         completion:^(BOOL f) {
            [UIView animateWithDuration:0.18
                             animations:^{ sw.transform = CGAffineTransformIdentity; }];
        }];

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [self refreshHUDState];
        });
    }
}

#pragma mark - Refresh HUD

- (void)refreshHUDState {
    BOOL gameNow = [self isGameRunning];
    BOOL hud     = IsHUDEnabled();

    if (!gameNow) _gameMissingStreak++;
    else          _gameMissingStreak = 0;

    BOOL game = gameNow || (_gameMissingStreak < 3);

    if (!game) {
        if (hud) { SetHUDEnabled(NO); hud = NO; }
        _hudSwitch.enabled         = NO;
        if (_hudSwitch.on) [_hudSwitch setOn:NO animated:YES];
        _descLabel.alpha           = 0.45;
        _hudStatusLabel.text       = @"OFFLINE";
        _hudStatusLabel.textColor  = [UIColor colorWithWhite:0.5 alpha:1.0];
        _statusDot.backgroundColor = [UIColor colorWithWhite:0.3 alpha:1.0];
        _pendingHUDEnableUntil     = 0;
        return;
    }

    _hudSwitch.enabled         = YES;
    _descLabel.alpha           = 1.0;
    _hudStatusLabel.text       = @"ONLINE";
    _hudStatusLabel.textColor  = [UIColor whiteColor];
    _statusDot.backgroundColor = [UIColor whiteColor];

    CFTimeInterval now   = CACurrentMediaTime();
    BOOL inGrace = (_pendingHUDEnableUntil > 0 && now < _pendingHUDEnableUntil);

    if (!hud && inGrace) {
        if (!_hudSwitch.on) [_hudSwitch setOn:YES animated:NO];
        return;
    }

    if (_hudSwitch.on != hud) [_hudSwitch setOn:hud animated:YES];
    if (hud) _pendingHUDEnableUntil = 0;
}

@end