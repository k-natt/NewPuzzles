//
//  PuzzleFronted.h
//  NewPuzzles
//
//  Created by Kevin on 12/27/21.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface Puzzle : NSObject

@property (class, readonly) NSArray <Puzzle *> *allPuzzles;

@property (readonly) NSString *name;
@property (readonly) NSString *helpName;

- (instancetype)init NS_UNAVAILABLE;
- (nullable instancetype)initWithRawValue:(NSString *)value;

@end

@interface PuzzleFronted : NSObject

@end

NS_ASSUME_NONNULL_END
