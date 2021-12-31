//
//  Puzzle.h
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@class PuzzleFrontend;
typedef struct game game;

@interface Puzzle : NSObject

@property (class, readonly) NSArray<Puzzle *> *allPuzzles;

@property (nonatomic, readonly) const game *game;

@property (readonly) NSString *name;
@property (readonly) NSString *helpName;

- (instancetype)init NS_UNAVAILABLE;

// Unfortunately this has to be here for RawRepresentable conformance, letting
// us use @AppStorage for puzzles directly, which makes things way easier.
- (nullable instancetype)initWithRawValue:(NSString *)value;

@end

NS_ASSUME_NONNULL_END
