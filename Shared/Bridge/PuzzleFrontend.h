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
@property (readonly) BOOL wantsStatusBar;
@property (readonly) BOOL canSolve;

// TODO: make these bindable/KVO-able
@property (readonly) BOOL canUndo;
@property (readonly) BOOL canRedo;

- (instancetype)init NS_UNAVAILABLE;

- (void)newGame;
- (void)restart;
// If return value is nonnull, it is an error description for the user.
- (nullable NSString *)solve;

// TODO: Do we really want/need this? Can probably get away without?
// Must call this once and only once, must not call any other methods afterwards.
- (void)finish;

@end

NS_ASSUME_NONNULL_END
