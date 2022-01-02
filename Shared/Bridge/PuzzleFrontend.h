//
//  PuzzleFrontend.h
//  NewPuzzles
//
//  Created by Kevin on 12/27/21.
//

@import Foundation;

#import "GameCanvas.h"

NS_ASSUME_NONNULL_BEGIN

@class Puzzle;
@class PuzzleMenuEntry;
@class PuzzleMenuPreset;

@interface PuzzleButton: NSObject

@property (readonly) NSString *label;
@property (readonly) void(^action)(void);

- (instancetype)init NS_UNAVAILABLE;

@end


@interface PuzzleFrontend : NSObject <GameCanvasDelegate>

// Must cache the results because of the way SwiftUI is constantly rebuilding everything.
// Not thread-safe
+ (PuzzleFrontend *)frontendForPuzzle:(Puzzle *)puzzle;

@property (readonly) Puzzle *puzzle;

// Lazy so we don't start all games at once because SwiftUI instantiates navigation destinations immediately
@property (readonly) GameCanvas *canvas;

@property (readonly) NSArray<PuzzleButton *> *buttons;

@property (readonly, nullable) NSString *statusText;
@property (readonly) BOOL wantsStatusBar;
@property (readonly) BOOL canSolve;
@property (readonly) BOOL canUndo;
@property (readonly) BOOL canRedo;
@property (readonly) BOOL inProgress;

- (instancetype)init NS_UNAVAILABLE;

- (void)newGame;
- (void)restart;
// If return value is nonnull, it is an error description for the user.
- (nullable NSString *)solve;

// Returns nil if game is over. No sense saving a failed or won game.
- (nullable NSData *)save;
// Returns nil on success, error message on failure.
- (nullable NSString *)restore:(NSData *)save;

- (NSInteger)currentPresetId;
- (NSArray<PuzzleMenuEntry *> *)menu;
- (void)applyPreset:(PuzzleMenuPreset *)preset;

- (void)undo;
- (void)redo;

// TODO: Do we really want/need this? Can probably get away without?
// Must call this once and only once, must not call any other methods afterwards.
- (void)finish;

@end

NS_ASSUME_NONNULL_END
