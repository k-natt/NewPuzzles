//
//  PuzzleFrontend.m
//  NewPuzzles
//
//  Created by Kevin on 12/27/21.
//

#import "PuzzleFrontend.h"
#import "GameCanvas.h"
#import "Puzzle.h"
#import "puzzles.h"
#import "PuzzleMenu.h"

#define AssertOnMain() do { NSAssert(NSThread.isMainThread, @"Not called on main thread"); } while (0)
#define AssertHasGame() do { NSAssert(self.hasGame, @"No game found"); } while (0)

NSString * const PuzzleErrorDomain = @"PuzzleErrorDomain";

extern const game filling;

struct frontend {
    __unsafe_unretained PuzzleFrontend *self;
};

void onMain(void(^action)(void)) {
    if (NSThread.isMainThread) {
        action();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            action();
        });
    }
}

@interface NSError (PuzzleError)
+ (instancetype)puzzleErrorWithMessage:(const char *)message;
@end

@implementation NSError (PuzzleError)

+ (instancetype)puzzleErrorWithMessage:(const char *)message {
    return [self errorWithDomain:PuzzleErrorDomain code:0 userInfo:@{
        NSLocalizedDescriptionKey: [NSString stringWithUTF8String:message]
    }];
}

@end


@interface PuzzleFrontend ()

@property (readonly) frontend frontend;
@property (readonly) NSArray<UIColor *> *gameColorList;
@property (NS_NONATOMIC_IOSONLY, assign) midend *midend;
@property (NS_NONATOMIC_IOSONLY, strong) CADisplayLink *timer;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSArray<PuzzleButton *> *buttons;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSString *statusText;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL wantsStatusBar;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL canSolve;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL canUndo;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL canRedo;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL inProgress;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) PuzzleFrontendStatus status;

//@property (NS_NONATOMIC_IOSONLY, strong) NSTimer *saveTimer;
@property (NS_NONATOMIC_IOSONLY, assign) BOOL hasGame;
@property (NS_NONATOMIC_IOSONLY, assign) BOOL hasPendingResize;
@property (NS_NONATOMIC_IOSONLY, assign) CGSize newSize;

- (void)startTimer;
- (void)stopTimer;

@end

void fatal(const char *fmt, ...) {
    NSString *newFmt = [NSString stringWithFormat:@"Fatal error: %s", fmt];
    va_list args;
    va_start(args, fmt);
    NSLogv(newFmt, args);
    va_end(args);

    NSLog(@"%@", [NSThread callStackSymbols]);

#if DEBUG
    raise(SIGTRAP);
#endif
    abort();
}

void frontend_default_colour(frontend *fe, float *output) {
    pack(@"default_background", output);
}

void deactivate_timer(frontend *fe) {
    [fe->self stopTimer];
}

void activate_timer(frontend *fe) {
    [fe->self startTimer];
}

void get_random_seed(void **randseed, int *randseedsize) {
    NSCParameterAssert(randseed);
    NSCParameterAssert(randseedsize);
    // midend puts it through sha1 so won't retain than 20 bytes of entropy.
    *randseedsize = 20;
    *randseed = malloc(*randseedsize);
    arc4random_buf(*randseed, *randseedsize);
    // Caller frees the buffer
}

@implementation PuzzleButton

- (instancetype)initWithLabel:(NSString *)label action:(void(^)(void))action {
    self = [super init];
    _label = label;
    _action = action;
    return self;
}

@end

@implementation PuzzleFrontend

- (instancetype)initWithPuzzle:(Puzzle *)puzzle {
    self = [super init];
    _puzzle = puzzle;
    _frontend.self = self;
    _gameColorList = [self colorsForGame:puzzle.game];
    _canvas = [[GameCanvas alloc] initWithDelegate:self];
    _midend = midend_new(&_frontend, puzzle.game, &game_canvas_dapi, _canvas.drawing_context);
    _hasGame = false;
    _wantsStatusBar = midend_wants_statusbar(self.midend);
    return self;
}

- (NSArray<UIColor *> *)colorsForGame:(const game *)game {
    int count = 0;
    // Strictly speaking, we're supposed to go through the midend. But we want
    // this before creating the midend, and we don't need/want the midend extras.
//    float *colors = midend_colours(self.midend, &count);
    float *colors = game->colours(&_frontend, &count);
    assert(count >= 0);
    NSMutableArray *mary = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        NSString *colorName = [NSString stringWithFormat:@"%s_%d", game->htmlhelp_topic, i];
        UIColor *color = [UIColor colorNamed:colorName];
        [mary addObject:color ?: unpack(colors+3*i)];
    }
    sfree(colors);
    return [mary copy];
}

- (void)updateButtons {
    NSMutableArray *mary = [NSMutableArray new];
    // We'll need this for the blocks later, may as well make it once now.
    __weak __typeof(self) welf = self;
    int nkeys = 0;
    key_label *keys = midend_request_keys(self.midend, &nkeys);
    for (int i = 0; i < nkeys; i++) {
        NSString *label = [NSString stringWithUTF8String:keys[i].label];
        free(keys[i].label);

        if (self.puzzle.game == &filling && [label isEqualToString:@"Clear"]) {
            // This one doesn't fit and doesn't really matter anyway.
            continue;
        }
        int btnId = keys[i].button;
        PuzzleButton *btn = [[PuzzleButton alloc] initWithLabel:label action:^{
            if (welf) {
                midend_process_key(welf.midend, 0, 0, btnId);
            }
        }];
        [mary addObject:btn];
    }
    free(keys);
    self.buttons = mary;
}

- (void)newGame:(void (^)(void))completion {
    AssertOnMain();
    self.hasGame = false;
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        midend_new_game(self.midend);
        dispatch_async(dispatch_get_main_queue(), ^{
            self.hasGame = true;
            if (self.hasPendingResize) {
                [self resize:self.newSize];
                self.hasPendingResize = false;
            }
            if (midend_tilesize(self.midend)) {
                midend_redraw(self.midend);
            }
            [self updateButtons];
            [self updateProperties];
            if (completion) completion();
        });
    });
}

- (void)restart {
    AssertOnMain();
    AssertHasGame();
    midend_restart_game(self.midend);
    [self updateProperties];
}

- (void)undo {
    AssertOnMain();
    AssertHasGame();
    NSAssert(self.canUndo, @"Tried to undo while disabled");
    midend_process_key(self.midend, -1, -1, UI_UNDO);
    [self updateProperties];
}

- (void)redo {
    AssertOnMain();
    AssertHasGame();
    NSAssert(self.canRedo, @"Tried to redo while disabled");
    midend_process_key(self.midend, -1, -1, UI_REDO);
    [self updateProperties];
}

- (BOOL)solveWithError:(NSError **)error {
    AssertOnMain();
    AssertHasGame();
    NSAssert(self.canSolve, @"Tried to solve while disabled");
    const char *s = midend_solve(self.midend);
    if (s) {
        if (error) *error = [NSError puzzleErrorWithMessage:s];
        return false;
    } else {
        return true;
    }
}

- (void)updateProperties {
    AssertOnMain();
    AssertHasGame();
    self.canUndo = midend_can_undo(self.midend);
    self.canRedo = midend_can_redo(self.midend);
    int status = midend_status(self.midend);
    if (status < 0) self.status = PuzzleFrontendStatusLost;
    if (status > 0) self.status = PuzzleFrontendStatusWon;
    if (status == 0) self.status = PuzzleFrontendStatusActive;
    self.canSolve = self.puzzle.game->can_solve && self.status == PuzzleFrontendStatusActive;
    self.inProgress = midend_status(self.midend) == 0;
}

- (void)resize:(CGSize)size {
    AssertOnMain();

    if (!self.hasGame) {
        self.hasPendingResize = true;
        self.newSize = size;
        return;
    }

    int width = (int)size.width;
    int height = (int)size.height;
    midend_size(self.midend, &width, &height, true);
    [self.canvas canvasSizeUpdated:CGSizeMake(width, height)];
}

- (NSArray<PuzzleMenuEntry *> *)menu {
    struct preset_menu *menu = midend_get_presets(self.midend, NULL);
    return [PuzzleMenuEntry parse:menu];
}

- (void)applyParams:(struct game_params *)params {
    AssertOnMain();
    self.hasGame = false;
    midend_set_params(self.midend, params);
    [self newGame:^{}];
}

- (void)applyPreset:(PuzzleMenuPreset *)preset {
    [self applyParams:preset.params];
}

static struct game_params * _Nullable find_params(int presetId, struct preset_menu *menu) {
    int idx = 0;
    while (idx < menu->n_entries) {
        if (menu->entries[idx].id == presetId) {
            return menu->entries[idx].params;
        } else if (menu->entries[idx].submenu) {
            struct game_params *paramsFromSubmenu = find_params(presetId, menu->entries[idx].submenu);
            if (paramsFromSubmenu) return paramsFromSubmenu;
        }

        idx += 1;
    }
    return NULL;
}

- (BOOL)applyPresetId:(NSInteger)presetId {
    NSParameterAssert(presetId <= INT_MAX);
    struct game_params *params = find_params((int)presetId, midend_get_presets(self.midend, NULL));
    if (params) {
        [self applyParams:params];
        return YES;
    }
    return NO;
}

- (NSInteger)currentPresetId {
    return midend_which_preset(self.midend);
}

- (void)startTimer {
    AssertOnMain();
    // Gets called every tick.
    if (self.timer) {
        return;
    }
    // TODO: May want to get it from UIScreen to support multiple screens?
    self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
    [self.timer addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
}

- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick:(CADisplayLink *)sender {
    if (sender != self.timer) {
        NSLog(@"Received tick from wrong display link!");
        [sender invalidate];
        return;
    }
    midend_timer(self.midend, sender.targetTimestamp - sender.timestamp);
}

- (void)interaction:(int)type at:(CGPoint)point {
    AssertOnMain();
    AssertHasGame();
    midend_process_key(self.midend, point.x, point.y, type);
    [self updateProperties];
}

- (void)updateStatusText:(NSString *)text {
    // May need to handle bg/no game if this gets called while generating.
    AssertOnMain();
    AssertHasGame();
    self.statusText = text;
}

- (void)redraw {
    AssertOnMain();
    // TODO: Figure this out
//    AssertHasGame();
    if (self.hasGame) midend_redraw(self.midend);
}

void fe_write(void *ctx, const void *buf, int len) {
    NSMutableData *data = (__bridge NSMutableData *)ctx;
    [data appendBytes:buf length:len];
}

- (NSData *)save {
    AssertOnMain();
    AssertHasGame();
    if (!self.inProgress) return nil;
    NSMutableData *data = [NSMutableData new];
    midend_serialise(self.midend, fe_write, (__bridge void *)data);
    return [data copy];
}

- (NSString *)gameSeed {
    char *seed = midend_get_random_seed(self.midend);
    if (seed) {
        NSString *str = [NSString stringWithCString:seed encoding:NSASCIIStringEncoding];
        free(seed);
        return str;
    }
    return nil;
}

- (NSString *)gameStateExportable {
    char *state = midend_text_format(self.midend);
    if (state) {
        NSString *str = [NSString stringWithCString:state encoding:NSASCIIStringEncoding];
        free(state);
        return str;
    }
    return nil;

}

- (NSString *)gameSettingsExportable {
    char *settings = midend_text_format(self.midend);
    if (settings) {
        NSString *str = [NSString stringWithCString:settings encoding:NSASCIIStringEncoding];
        free(settings);
        return str;
    }
    return nil;

}

struct read_context {
    NSData *data;
    NSUInteger pos;
};

bool fe_read(void *ctx, void *buf, int len) {
    struct read_context *context = (struct read_context *)ctx;
    NSRange range = NSMakeRange(context->pos, (NSUInteger)len);
    if (NSMaxRange(range) > context->data.length) {
        return false;
    }
    [context->data getBytes:buf range:range];
    context->pos += len;
    return true;
}

+ (Puzzle *)identify:(NSData *)save error:(NSErrorPointer)error {
    AssertOnMain();
    struct read_context context = {
        .data = save,
        .pos = 0,
    };
    char *name;
    const char *emsg = identify_game(&name, fe_read, &context);
    Puzzle *puzzle;
    if (emsg) {
        if (error) *error = [NSError puzzleErrorWithMessage:emsg];
    } else {
        puzzle = [[Puzzle alloc] initWithRawValue:[NSString stringWithUTF8String:name]];
        if (!puzzle && error) *error = [NSError puzzleErrorWithMessage:"Unknown puzzle type"];
        sfree(name);
    }
    return puzzle;
}

- (BOOL)restore:(NSData *)save error:(NSErrorPointer)error {
    AssertOnMain();
    struct read_context context = {
        .data = save,
        .pos = 0,
    };
    const char *emsg = midend_deserialise(self.midend, fe_read, &context);
    if (emsg) {
        if (error) *error = [NSError puzzleErrorWithMessage:emsg];
        return false;
    }
    self.hasGame = true;
    [self updateButtons];
    [self updateProperties];
    return true;
}

- (void)finish {
    AssertOnMain();
    [self stopTimer];
    // TODO: Save settings/state, stop game(?)
}

- (void)dealloc {
    if (_midend) midend_free(_midend);
}

@end
