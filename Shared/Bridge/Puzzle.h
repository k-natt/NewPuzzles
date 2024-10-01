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
+ (instancetype)new NS_UNAVAILABLE;

+ (nullable Puzzle *)puzzleForName:(NSString *)name NS_SWIFT_NAME(init(named:));

@end

NS_ASSUME_NONNULL_END
