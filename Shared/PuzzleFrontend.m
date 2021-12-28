//
//  PuzzleFrontend.m
//  NewPuzzles
//
//  Created by Kevin on 12/27/21.
//

#import "PuzzleFrontend.h"
#import "../puzzles/puzzles.h"

void fatal(const char *fmt, ...) {
    NSString *newFmt = [NSString stringWithFormat:@"Fatal error: %s", fmt];
    va_list args;
    va_start(args, fmt);
    NSLogv(newFmt, args);
    va_end(args);
}

// TODO
void frontend_default_colour(frontend *fe, float *output) {}
void deactivate_timer(frontend *fe) {}
void activate_timer(frontend *fe) {}
void get_random_seed(void **randseed, int *randseedsize) {}

@interface Puzzle ()

@property (nonatomic, readonly) const game *game;

@end

@implementation Puzzle

+ (NSArray<Puzzle *> *)allPuzzles {
    static NSArray<Puzzle *> *puzzles;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableArray *mary = [NSMutableArray arrayWithCapacity:gamecount];
        for (NSInteger i = 0; i < gamecount; i++) {
            [mary addObject:[[self alloc] initWithGame:gamelist[i]]];
        }
        puzzles = [mary copy];
    });

    return puzzles;
}

- (instancetype)initWithGame:(const struct game *)game {
    self = [super init];
    _game = game;
    _name = [NSString stringWithUTF8String:game->name];
    _helpName = [NSString stringWithUTF8String:game->htmlhelp_topic];
    return self;
}

- (instancetype)initWithRawValue:(NSString *)value {
    for (Puzzle *game in Puzzle.allPuzzles) {
        if ([game.name isEqualToString:value]) {
            return game;
        }
    }
    return nil;
}

@end

@implementation PuzzleFronted


@end
