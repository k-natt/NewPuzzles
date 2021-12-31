//
//  GameCanvas.m
//  NewPuzzles
//
//  Created by Kevin on 12/28/21.
//

#import "GameCanvas.h"
#import "puzzles.h"

@interface GameCanvas ()

// Cache color list from the delegate/frontend
@property (readonly, strong) NSArray<UIColor *> *colors;

@property (NS_NONATOMIC_IOSONLY, strong) UIImage *currentCanvas;
@property (NS_NONATOMIC_IOSONLY, readwrite, strong) NSString *statusText;
@property (NS_NONATOMIC_IOSONLY, assign) CGSize canvasSize;
@property (NS_NONATOMIC_IOSONLY, strong) NSTimer *touchTimer;
@property (NS_NONATOMIC_IOSONLY, strong) BOOL pressIsLong;
@property (NS_NONATOMIC_IOSONLY, assign) CGPoint mouseDownPoint;

@property (readonly) UIPanGestureRecognizer *dragGR;
@property (readonly) UITapGestureRecognizer *tapGR;
@property (readonly) UILongPressGestureRecognizer *lpGR;
@property (readonly) UITapGestureRecognizer *doubleTapGR;
@end

struct blitter {
    // TODO: Make sure ARC handles this as expected
    UIGraphicsImageRenderer *renderer;
    UIImage *savedImage;
    CGPoint savedOrigin;
    CGSize size;
};

@implementation GameCanvas

- (instancetype)initWithDelegate:(id<GameCanvasDelegate>)delegate {
    if (!(self = [super init])) return self;

    _delegate = delegate;
    _drawing_context = (__bridge void *)self;

    self.backgroundColor = UIColor.blueColor;
    self.contentMode = UIViewContentModeCenter;

//    _dragGR = [[UIPanGestureRecognizer alloc] initWithTarget:self action:<#(nullable SEL)#>]
    return self;
}

@synthesize colors = _colors;
- (NSArray<UIColor *> *)colors {
    if (!_colors) _colors = self.delegate.gameColorList;
    return _colors;
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [self resized:frame.size];
}

- (void)setBounds:(CGRect)bounds {
    [super setBounds:bounds];
    [self resized:bounds.size];
}

- (void)resized:(CGSize)newSize {
    if (newSize.width > 0 && newSize.height > 0) {
        self.canvasSize = [self.delegate resize:newSize];
    } else {
        self.canvasSize = CGSizeZero;
    }
    self.currentCanvas = nil;
    [self.delegate redraw];
}

- (void)tap:(UITapGestureRecognizer *)gr {

}

- (void)drag:(UIPanGestureRecognizer *)gr {

}

- (void)longPress:(UITapGestureRecognizer *)gr {

}

- (void)doubleTap:(UITapGestureRecognizer *)gr {

}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [super touchesBegan:touches withEvent:event];
//
//    self.pressIsLong = false;
//    self.
//}

@end

void pack(NSString *name, float *out) {
    if (!out) return;
    CGFloat r, g, b;
    if ([[UIColor colorNamed:name] getRed:&r green:&g blue:&b alpha:nil]) {
        out[0] = r;
        out[1] = g;
        out[2] = b;
    } else {
        NSLog(@"Missing color or could not get RGB for %@", name);
        out[0] = 0.5;
        out[1] = 0.5;
        out[2] = 0.5;
    }
}

UIColor *unpack(float *in) {
    CGFloat r = in[0];
    CGFloat g = in[1];
    CGFloat b = in[2];
    return [UIColor colorWithRed:r green:g blue:b alpha:1];
}

static void canvas_draw_text(void *handle, int x, int y, int fonttype, int fontsize, int align, int colour, const char *text) {
    NSLog(@"Text %s at (%d, %d) color %d", text, x, y, colour);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(fonttype == FONT_FIXED || fonttype == FONT_VARIABLE);
    assert(fontsize > 0);
    assert(colour >= 0);
    assert(colour < canvas.colors.count);
    assert(text);

    NSString *string = [NSString stringWithUTF8String:text];

    UIFont *font;
    switch (fonttype) {
        case FONT_FIXED:
            font = [UIFont monospacedSystemFontOfSize:fontsize weight:UIFontWeightRegular];
            break;
        case FONT_VARIABLE:
        default:
            font = [UIFont systemFontOfSize:fontsize];
            break;
    }

    NSDictionary *attributes = @{
        NSFontAttributeName: font,
        NSForegroundColorAttributeName: canvas.colors[colour],
    };

    CGSize size = [string sizeWithAttributes:attributes];
    CGPoint origin = CGPointMake(x, y);

    if (align & ALIGN_VCENTRE) {
        origin.y -= size.height / 2;
    } else {
        // Baseline
        origin.y -= font.ascender;
    }

    if (align & ALIGN_HLEFT) {
        // x is correct
    }

    if (align & ALIGN_HCENTRE) {
        origin.x -= size.width / 2;
    }

    if (align & ALIGN_HRIGHT) {
        origin.x -= size.width;
    }

    UIImage *before = UIGraphicsGetImageFromCurrentImageContext();

    [string drawAtPoint:origin withAttributes:attributes];

    UIImage *after = UIGraphicsGetImageFromCurrentImageContext();
    after = after;
}

static void canvas_draw_rect(void *handle, int x, int y, int w, int h, int colour) {
    NSLog(@"rect(%d, %d, %d, %d) c %d", x, y, w, h, colour);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(colour >= 0);
    assert(colour < canvas.colors.count);

    UIImage *before = UIGraphicsGetImageFromCurrentImageContext();

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    [canvas.colors[colour] setFill];
    CGContextFillRect(context, CGRectMake(x, y, w, h));

    UIImage *after = UIGraphicsGetImageFromCurrentImageContext();
    after = after;
}

static void canvas_draw_line(void *handle, int x1, int y1, int x2, int y2, int colour) {
    NSLog(@"line(%d, %d -> %d, %d) c %d", x1, y1, x2, y2, colour);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(colour >= 0);
    assert(colour < canvas.colors.count);

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    UIImage *before = UIGraphicsGetImageFromCurrentImageContext();

    [canvas.colors[colour] setStroke];
//    CGContextSetLineWidth(context, 1/UIScreen.mainScreen.nativeScale);
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y2);
    CGContextStrokePath(context);

    UIImage *after = UIGraphicsGetImageFromCurrentImageContext();
    after = after;
}

static void canvas_draw_poly(void *handle, const int *coords, int npoints, int fillcolour, int outlinecolour) {
    NSLog(@"poly(%d points/ %d, %d)", npoints, fillcolour, outlinecolour);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(coords);
    assert(npoints >= 2);
    assert(fillcolour == -1 || fillcolour < canvas.colors.count);
    assert(outlinecolour >= 0);
    assert(outlinecolour < canvas.colors.count);

    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, NULL, coords[0], coords[1]);
    for (int i = 1; i < npoints; i++) {
        CGPathAddLineToPoint(path, NULL, coords[2*i], coords[2*i+1]);
    }
    CGPathCloseSubpath(path);

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    UIImage *before = UIGraphicsGetImageFromCurrentImageContext();

    CGContextSetLineWidth(context, 1);
    CGContextAddPath(context, path);

    if (fillcolour >= 0) {
        [canvas.colors[fillcolour] setFill];
        CGContextFillPath(context);
    }

    [canvas.colors[outlinecolour] setStroke];
    CGContextAddPath(context, path);
    CGContextStrokePath(context);

    CGPathRelease(path);

    UIImage *after = UIGraphicsGetImageFromCurrentImageContext();
    after = after;
}

static void canvas_draw_circle(void *handle, int cx, int cy, int radius, int fillcolour, int outlinecolour) {
    NSLog(@"circle(%d, %d, %d)", cx, cy, radius);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(fillcolour < 0 || fillcolour < canvas.colors.count);
    assert(outlinecolour >= 0);
    assert(outlinecolour < canvas.colors.count);

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    CGRect bounds = CGRectMake(cx - radius, cy - radius, 2 * radius, 2 * radius);

    UIImage *before = UIGraphicsGetImageFromCurrentImageContext();

   CGContextSetLineWidth(context, 1);

    if (fillcolour >= 0) {
        [canvas.colors[fillcolour] setFill];
        CGContextFillEllipseInRect(context, bounds);
    }

    [canvas.colors[outlinecolour] setStroke];
    CGContextStrokeEllipseInRect(context, bounds);

    UIImage *after = UIGraphicsGetImageFromCurrentImageContext();
    after = after;
}

static void canvas_draw_update(void *handle, int x, int y, int w, int h) {
    NSLog(@"update %d, %d, %d, %d", x, y, w, h);
    // Shouldn't need to do anything here, we always update the screen
}

static void canvas_clip(void *handle, int x, int y, int w, int h) {
    NSLog(@"clip(%d, %d, %d, %d)", x, y, w, h);

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    CGContextClipToRect(context, CGRectMake(x, y, w, h));
}
static void canvas_unclip(void *handle) {
    NSLog(@"unclip");

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    CGContextResetClip(context);
}

static void canvas_start_draw(void *handle) {
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);

    UIGraphicsBeginImageContextWithOptions(canvas.canvasSize, true, 0);
    [canvas.currentCanvas drawAtPoint:CGPointZero];
}

static void canvas_end_draw(void *handle) {
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);

    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    canvas.image = canvas.currentCanvas = newImage;
}

static void canvas_status_bar(void *handle, const char *text) {
    NSLog(@"status %s", text);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);

    if (text) {
        canvas.statusText = [NSString stringWithUTF8String:text];
    } else {
        canvas.statusText = nil;
    }
}

static blitter *canvas_blitter_new(void *handle, int w, int h) {
    blitter *bl = calloc(1, sizeof(blitter));
    bl->size = CGSizeMake(w, h);
    bl->renderer = [[UIGraphicsImageRenderer alloc] initWithSize:bl->size];
    return bl;
}

static void canvas_blitter_free(void *handle, blitter *bl) {
    bl->renderer = nil;
    bl->savedImage = nil;
    free(bl);
}

static void canvas_blitter_save(void *handle, blitter *bl, int x, int y) {
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(bl);

    bl->savedImage = [bl->renderer imageWithActions:^(UIGraphicsImageRendererContext *rendererContext) {
        [canvas.currentCanvas drawAtPoint:CGPointMake(-x, -y)];
    }];
    bl->savedOrigin = CGPointMake(x, y);
}

static void canvas_blitter_load(void *handle, blitter *bl, int x, int y) {
    assert(bl);
    assert(bl->savedImage);

    CGPoint destination;
    if (x == BLITTER_FROMSAVED && y == BLITTER_FROMSAVED) {
        destination = bl->savedOrigin;
    } else {
        destination = CGPointMake(x, y);
    }

    [bl->savedImage drawAtPoint:destination];
}

void canvas_draw_thick_line(void *handle, float thickness, float x1, float y1, float x2, float y2, int colour) {
    NSLog(@"thick line (%f, %f) -> (%f, %f) @ %f px", x1, y1, x2, y2, thickness);
    GameCanvas *canvas = (__bridge GameCanvas *)handle;

    assert(handle);
    assert(thickness > 0);
    assert(colour >= 0);
    assert(colour < canvas.colors.count);

    CGContextRef context = UIGraphicsGetCurrentContext();
    assert(context);

    CGContextSetLineWidth(context, thickness);
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, x1, y1);
    CGContextAddLineToPoint(context, x2, y2);
    CGContextStrokePath(context);
}

char *canvas_text_fallback(void *handle, const char *const *strings, int nstrings) {
    assert(nstrings);
    assert(strings);
    assert(*strings);
    return strdup(*strings);
}

struct drawing_api game_canvas_dapi = {
    canvas_draw_text,
    canvas_draw_rect,
    canvas_draw_line,
    canvas_draw_poly,
    canvas_draw_circle,
    canvas_draw_update,
    canvas_clip,
    canvas_unclip,
    canvas_start_draw,
    canvas_end_draw,
    canvas_status_bar,
    canvas_blitter_new,
    canvas_blitter_free,
    canvas_blitter_save,
    canvas_blitter_load,
    // TODO: We could probably add printing at some point.
    NULL, //    void (*begin_doc)(void *handle, int pages);
    NULL, //    void (*begin_page)(void *handle, int number);
    NULL, //    void (*begin_puzzle)(void *handle, float xm, float xc,
          //             float ym, float yc, int pw, int ph, float wmm);
    NULL, //    void (*end_puzzle)(void *handle);
    NULL, //    void (*end_page)(void *handle, int number);
    NULL, //    void (*end_doc)(void *handle);
    NULL, //    void (*line_width)(void *handle, float width);
    NULL, //    void (*line_dotted)(void *handle, bool dotted);
    canvas_text_fallback,
    canvas_draw_thick_line,
};

