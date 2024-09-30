//
//  PuzzleFrontend.h
//  NewPuzzles
//
//  Created by Kevin on 12/27/21.
//

@import Foundation;

#import "GameCanvas.h"

NS_ASSUME_NONNULL_BEGIN

extern NSErrorDomain const PuzzleErrorDomain;
// No specific codes

@class Puzzle;
@class PuzzleMenuEntry;
@class PuzzleMenuPreset;

typedef NSError *_Nullable __autoreleasing *_Nullable NSErrorPointer;

@interface PuzzleButton: NSObject

@property (readonly) NSString *label;
@property (readonly) void(^action)(void);

- (instancetype)init NS_UNAVAILABLE;

@end

typedef NS_ENUM(NSUInteger, PuzzleFrontendStatus) {
    PuzzleFrontendStatusUnloaded,
    PuzzleFrontendStatusActive,
    PuzzleFrontendStatusWon,
    PuzzleFrontendStatusLost,
};

@interface PuzzleFrontend : NSObject <GameCanvasDelegate>

// Must call newGame or restore before playing.
- (instancetype)initWithPuzzle:(Puzzle *)puzzle;

@property (readonly) Puzzle *puzzle;

// Lazy so we don't start all games at once because SwiftUI instantiates navigation destinations immediately
@property (readonly) GameCanvas *canvas;

// Static, don't need to KVO
@property (readonly) BOOL wantsStatusBar;

// KVO-able
@property (readonly, nullable) NSString *statusText;
@property (readonly) NSArray<PuzzleButton *> *buttons;
@property (readonly) BOOL canSolve;
@property (readonly) BOOL canUndo;
@property (readonly) BOOL canRedo;
@property (readonly) BOOL inProgress;
@property (readonly) PuzzleFrontendStatus status;

- (instancetype)init NS_UNAVAILABLE;

// Generates in the background, calls completion on main queue when done.
- (void)newGame:(void(^)(void))completion;
- (void)restart;
- (BOOL)solveWithError:(NSErrorPointer)error;

// Returns nil if game is over. No sense saving a failed or won game.
- (nullable NSData *)save;

// Documentatino says gameSeed could contain non-ascii, but the code suggests
// it should always be a decimal number. So export as string for now I guess.
- (nullable NSString *)gameSeed;
- (nullable NSString *)gameStateExportable;
- (nullable NSString *)gameSettingsExportable;

// Returns nil on success, error message on failure.
- (BOOL)restore:(NSData *)save error:(NSErrorPointer)error;
+ (nullable Puzzle *)identify:(NSData *)data error:(NSErrorPointer)error;

- (NSInteger)currentPresetId;
- (NSArray<PuzzleMenuEntry *> *)menu;

// Must call newGame after.
- (void)applyPreset:(PuzzleMenuPreset *)preset;
- (BOOL)applyPresetId:(NSInteger)presetId;

- (void)undo;
- (void)redo;

// TODO: Do we really want/need this? Can probably get away without?
// Must call this once and only once, must not call any other methods afterwards.
- (void)finish;

@end

NS_ASSUME_NONNULL_END
