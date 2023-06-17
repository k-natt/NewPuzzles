//
//  PuzzleMenu.h
//  NewPuzzles
//
//  Created by Kevin on 1/1/22.
//

#import <Foundation/Foundation.h>

typedef struct game_params game_params;
struct preset_menu;
NS_ASSUME_NONNULL_BEGIN

@interface PuzzleMenuEntry : NSObject

+ (NSArray<PuzzleMenuEntry *> *)parse:(const struct preset_menu *)menu;

@property (readonly) NSString *title;
@property (readonly) NSInteger identifier;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface PuzzleMenuPreset: PuzzleMenuEntry

@property (readonly) game_params *params;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface PuzzleMenuSubmenu: PuzzleMenuEntry

@property (readonly) NSArray<PuzzleMenuEntry *> *submenu;

- (instancetype)init NS_UNAVAILABLE;

@end

@interface PuzzleMenuCustom : NSObject

@end

NS_ASSUME_NONNULL_END
