//
//  Puzzle.m
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

#import "Puzzle.h"
#import "PuzzleFrontend.h"
#import "puzzles.h"

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
