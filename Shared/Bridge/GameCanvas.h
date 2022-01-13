//
//  GameCanvas.h
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

@import UIKit;

struct drawing_api;
extern struct drawing_api game_canvas_dapi;

NS_ASSUME_NONNULL_BEGIN

void pack(NSString *name, float *out);
UIColor *unpack(float *in);

@protocol GameCanvasDelegate <NSObject>

// Should call canvasSizeUpdated with the new canvas size.
- (void)resize:(CGSize)maxSize;
- (void)redraw;

- (void)interaction:(int)type at:(CGPoint)point;
- (void)updateStatusText:(nullable NSString *)text;

- (NSArray<UIColor *> *)gameColorList;

@end

@interface GameCanvas : UIView

@property (NS_NONATOMIC_IOSONLY, readonly) struct drawing_api dapi;
@property (NS_NONATOMIC_IOSONLY, readonly) void *drawing_context;
@property (NS_NONATOMIC_IOSONLY, weak) id<GameCanvasDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithDelegate:(id<GameCanvasDelegate>)delegate;

- (void)canvasSizeUpdated:(CGSize)size;

@end

NS_ASSUME_NONNULL_END
