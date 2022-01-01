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

struct frontend {
    __unsafe_unretained PuzzleFrontend *self;
};

typedef NS_ENUM(NSUInteger, PuzzleFrontendState) {
    PuzzleFrontendStateNotStarted,
    PuzzleFrontendStatePlaying,
    PuzzleFrontendStateDead,
};

@interface PuzzleFrontend ()

@property (readonly) frontend frontend;
@property (NS_NONATOMIC_IOSONLY, assign) midend *midend;
@property (NS_NONATOMIC_IOSONLY, strong) GameCanvas *canvas;
@property (NS_NONATOMIC_IOSONLY, strong) CADisplayLink *timer;
@property (NS_NONATOMIC_IOSONLY, assign) PuzzleFrontendState state;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSArray<PuzzleButton *> *buttons;
@property (NS_NONATOMIC_IOSONLY, readwrite, copy) NSString *statusText;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL canSolve;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL canUndo;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL canRedo;
@property (NS_NONATOMIC_IOSONLY, readwrite, assign) BOOL inProgress;

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
    if (!randseed || !randseedsize) return;
    // midend puts it through sha1 so can't get retain than 20 bytes of entropy.
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

+ (PuzzleFrontend *)frontendForPuzzle:(Puzzle *)puzzle {
    static NSMutableDictionary<NSString *, PuzzleFrontend *> *puzzles;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        puzzles = [NSMutableDictionary new];
    });

    PuzzleFrontend *fe = puzzles[puzzle.name];
    if (!fe || fe.state == PuzzleFrontendStateDead) {
        fe = [[PuzzleFrontend alloc] initWithPuzzle:puzzle];
        puzzles[puzzle.name] = fe;
    }
    return fe;
}

- (instancetype)initWithPuzzle:(Puzzle *)puzzle {
    self = [super init];
    _puzzle = puzzle;
    _frontend.self = self;
    // TODO: Restoration?
    return self;
}

- (BOOL)startIfNeeded {
    switch (self.state) {
        case PuzzleFrontendStateNotStarted:
            self.canvas = [[GameCanvas alloc] initWithDelegate:self];
            self.midend = midend_new(&_frontend, self.puzzle.game, &game_canvas_dapi, self.canvas.drawing_context);
            midend_new_game(self.midend);
            self.state = PuzzleFrontendStatePlaying;
        case PuzzleFrontendStatePlaying:
            return true;
        default:
            NSLog(@"Frontend in invalid state: %lu", (unsigned long)self.state);
        case PuzzleFrontendStateDead:
            return false;
    }
}

- (GameCanvas *)canvas {
    if (!_canvas) [self startIfNeeded];
    return _canvas;
}

- (NSArray<PuzzleButton *> *)buttons {
    if (_buttons || ![self startIfNeeded]) {
        return _buttons;
    }
    NSMutableArray *mary = [NSMutableArray new];
    // We'll need this for the blocks later, may as well make it once now.
    __weak __typeof(self) welf = self;
    int nkeys = 0;
    key_label *keys = midend_request_keys(self.midend, &nkeys);
    for (int i = 0; i < nkeys; i++) {
        NSString *label = [NSString stringWithUTF8String:keys[i].label];
        int btnId = keys[i].button;
        PuzzleButton *btn = [[PuzzleButton alloc] initWithLabel:label action:^{
            if (welf && welf.state == PuzzleFrontendStatePlaying) {
                midend_process_key(welf.midend, 0, 0, btnId);
            }
        }];
        [mary addObject:btn];

        // Seems kinda random but is necessary because of the way things work.
        free(keys[i].label);
    }
    free(keys);
    _buttons = [mary copy];
    return _buttons;
}

- (void)newGame {
    midend_new_game(self.midend);
    midend_redraw(self.midend);
    [self updateUndoRedoSolve];
}

- (void)restart {
    midend_restart_game(self.midend);
    [self updateUndoRedoSolve];
}

- (BOOL)canSolve {
    return self.puzzle.game->can_solve && [self startIfNeeded] && midend_status(self.midend) == 0;
}

- (void)undo {
    assert(self.canUndo);
    midend_process_key(self.midend, -1, -1, 'u');
    [self updateUndoRedoSolve];
}

- (void)redo {
    assert(self.canRedo);
    midend_process_key(self.midend, -1, -1, 'r' & 0x1F);
    [self updateUndoRedoSolve];
}

- (void)updateUndoRedoSolve {
    if (![self startIfNeeded]) {
        self.inProgress = self.canSolve = self.canUndo = self.canRedo = false;
    }
    self.canUndo = midend_can_undo(self.midend);
    self.canRedo = midend_can_redo(self.midend);
    self.canSolve = self.puzzle.game->can_solve && midend_status(self.midend) == 0;
    self.inProgress = midend_status(self.midend) == 0;
}

- (NSString *)solve {
    const char *s = midend_solve(self.midend);
    if (s) {
        return [NSString stringWithUTF8String:s];
    } else {
        return nil;
    }
}

- (CGSize)resize:(CGSize)size {
    int width = (int)size.width;
    int height = (int)size.height;
    midend_size(self.midend, &width, &height, true);
    return CGSizeMake(width, height);
}

- (void)redraw {
    midend_redraw(self.midend);
}

- (void)startTimer {
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

- (NSArray<UIColor *> *)gameColorList {
    int count = 0;
    float *colors = midend_colours(self.midend, &count);
    assert(count >= 0);
    NSMutableArray *mary = [[NSMutableArray alloc] initWithCapacity:count];
    for (int i = 0; i < count; i++) {
        [mary addObject:unpack(colors+3*i)];
    }
    sfree(colors);
    return [mary copy];
}

- (void)interaction:(int)type at:(CGPoint)point {
    midend_process_key(self.midend, point.x, point.y, type);
    [self updateUndoRedoSolve];
}

- (void)updateStatusText:(nonnull NSString *)text {
    self.statusText = text;
}

void fe_write(void *ctx, const void *buf, int len) {
    NSMutableData *data = (__bridge NSMutableData *)ctx;
    [data appendBytes:buf length:len];
}

- (NSData *)save {
    if (!self.inProgress) return nil;
    NSMutableData *data = [NSMutableData new];
    midend_serialise(self.midend, fe_write, (__bridge void *)data);
    return [data copy];
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

- (NSString *)restore:(NSData *)save {
    struct read_context context = {
        .data = save,
        .pos = 0,
    };
    const char *error = midend_deserialise(self.midend, fe_read, &context);
    if (error) return [NSString stringWithUTF8String:error];
    [self updateUndoRedoSolve];
    return nil;
}

- (void)finish {
    [self stopTimer];
    // TODO: Save settings/state, stop game(?)
}

- (void)dealloc {
    if (_midend) midend_free(_midend);
}

@end
