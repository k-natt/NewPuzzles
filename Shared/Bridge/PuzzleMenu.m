//
//  PuzzleMenu.m
//  NewPuzzles
//
//  Created by Kevin on 1/1/22.
//

#import "PuzzleMenu.h"
#import "puzzles.h"

@interface PuzzleMenuPreset ()
- (instancetype)initWithTitle:(NSString *)title id:(int)identifier params:(game_params *)params;
@end

@interface PuzzleMenuSubmenu ()
- (instancetype)initWithTitle:(NSString *)title id:(int)identifier submenu:(NSArray<PuzzleMenuEntry *> *)submenu;
@end

@implementation PuzzleMenuEntry

+ (NSArray<PuzzleMenuEntry *> *)parse:(const struct preset_menu *)menu {
    NSMutableArray *entries = [NSMutableArray new];
    for (NSInteger i = 0; i < menu->n_entries; i++) {
        struct preset_menu_entry *entry = menu->entries+i;
        NSString *title = [NSString stringWithUTF8String:entry->title];
        int identifier = entry->id;
        PuzzleMenuEntry *menuEntry;
        if (entry->params) {
            menuEntry = [[PuzzleMenuPreset alloc] initWithTitle:title id:identifier params:entry->params];
        } else if (entry->submenu) {
            NSArray *submenu = [self parse:entry->submenu];
            menuEntry = [[PuzzleMenuSubmenu alloc] initWithTitle:title id:identifier submenu:submenu];
        } else {
            assert(!"Neither params nor submenu provided");
            continue;
        }
        [entries addObject:menuEntry];
    }
    return [entries copy];
}

- (instancetype)initWithTitle:(NSString *)title id:(int)identifier {
    self = [super init];
    _title = title;
    _identifier = identifier;
    return self;
}

@end

@implementation PuzzleMenuPreset

- (instancetype)initWithTitle:(NSString *)title id:(int)identifier params:(game_params *)params {
    self = [super initWithTitle:title id:identifier];
    _params = params;
    return self;
}

@end

@implementation PuzzleMenuSubmenu

- (instancetype)initWithTitle:(NSString *)title id:(int)identifier submenu:(NSArray<PuzzleMenuEntry *> *)submenu {
    self = [super initWithTitle:title id:identifier];
    _submenu = submenu;
    return self;
}

@end
