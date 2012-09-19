//
//  AdvancedTextView.m
//  CoreTextDemo
//
//  Created by Konstantin Kiselyov on 9/18/12.
//  Copyright (c) 2012 Any Void. All rights reserved.
//

#import "AdvancedTextView.h"
#import "MarkedTextButton.h"

@interface AdvancedTextView()
@property (strong, nonatomic) NSAttributedString* initialAttrText;
@property (strong, nonatomic) NSAttributedString* attrText;
@property (strong, nonatomic) NSArray* selectionRanges;

- (CFDictionaryRef)createClippingPathWithPath:(CGPathRef)pathRef;
- (void)markedTextButtonTouchUpInside:(id)sender;
- (NSValue *)parentForRange:(NSRange)range;
@end

@implementation AdvancedTextView
@synthesize attrText, columnsNumber, columnPadding, clippingPaths, initialAttrText;

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if ( !self ) {
        return nil;
    }
    self.attrText = nil;
    self.columnsNumber = 1;
    self.columnPadding = 10.0f;
    self.clippingPaths = [NSArray array];
    self.selectionRanges = nil;
    self.userInteractionEnabled = YES;
    return self;
}

- (CFDictionaryRef)createClippingPathWithPath:(CGPathRef)pathRef {
    CFStringRef keys[] = {kCTFramePathClippingPathAttributeName};
    CFTypeRef values[] = {pathRef};
    CFDictionaryRef clippingPathDict = CFDictionaryCreate(NULL, (const void **)&keys, (const void **)&values,  sizeof(keys)/sizeof(keys[0]), &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    return clippingPathDict;
}

- (void)markedTextButtonTouchUpInside:(id)sender {
    MarkedTextButton* button = (MarkedTextButton *)sender;
    if ( self.delegate && [self.delegate respondsToSelector: @selector(didPressMarkedText:)] ) {
        [self.delegate performSelector: @selector(didPressMarkedText:) withObject: button.text];
    }
}

- (NSValue *)parentForRange:(NSRange)range {
    if ( self.selectionRanges ) {
        for ( NSValue* rangeValue in self.selectionRanges ) {
            NSRange parentRange = [rangeValue rangeValue];
            if ( parentRange.location <= range.location &&
                 parentRange.location + parentRange.length >= range.location + range.length ) {
                // OK
                return rangeValue;
            }
        }
    }
    return nil;
}

- (void)drawRect:(CGRect)rect {
    if ( !self.attrText ) {
        [super drawRect: rect];
    }
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSetTextMatrix( context, CGAffineTransformIdentity );
    CGContextTranslateCTM( context, 0, rect.size.height );
    CGContextScaleCTM( context, 1, -1 );

    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString( (__bridge CFAttributedStringRef)self.attrText );
    
    CGFloat overallTextWidth = rect.size.width;
    CGFloat overallTextHeight = rect.size.height;
    
    CGFloat colWidth = (overallTextWidth - self.columnPadding*(self.columnsNumber-1))/self.columnsNumber;
    CGFloat colHeight = overallTextHeight;
    
    CGMutablePathRef columnRectPaths[self.columnsNumber];
    
    for ( NSInteger columnIdx = 0; columnIdx < MAX(self.columnsNumber, 1); ++columnIdx ) {
        CGMutablePathRef rectPath = CGPathCreateMutable();;
        CGFloat originX = (colWidth + self.columnPadding)*columnIdx;
        CGFloat originY = 0;
        
        CGPathAddRect(rectPath, NULL, CGRectMake(originX, originY, colWidth, colHeight));
        columnRectPaths[columnIdx] = rectPath;
    }
    
    NSDictionary* frameOptionsDict = nil;
    NSMutableArray* clippingPathDicts = [[NSMutableArray alloc] initWithCapacity: 0];
    
    if ( self.clippingPaths ) {
        for ( int i = 0; i < self.clippingPaths.count; ++i ) {
            CGPathRef path = (__bridge CGPathRef)([self.clippingPaths objectAtIndex: i]);
            [clippingPathDicts addObject: (__bridge NSDictionary *)[self createClippingPathWithPath: path]];
        }
        frameOptionsDict = [NSDictionary dictionaryWithObject: clippingPaths forKey: (NSString *)kCTFrameClippingPathsAttributeName];
    }
    
    CTFrameRef colFrames[self.columnsNumber];
    
    for ( NSInteger columnIdx = 0; columnIdx < MAX(self.columnsNumber, 1); ++columnIdx ) {
        CFRange colTextRange = CFRangeMake(0, self.attrText.length);
        if ( columnIdx > 0 ) {
            CFRange prevColTextRange = CTFrameGetVisibleStringRange(colFrames[columnIdx - 1]);
            NSInteger prevLastPos = prevColTextRange.location + prevColTextRange.length - 1;
            colTextRange = CFRangeMake(prevLastPos + 1, self.attrText.length - prevLastPos - 1);
        }
        colFrames[columnIdx] = CTFramesetterCreateFrame(frameSetter, colTextRange, columnRectPaths[columnIdx], (__bridge CFDictionaryRef)(frameOptionsDict));
    }
    
    for ( NSInteger columnIdx = 0; columnIdx < self.columnsNumber; ++columnIdx ) {
        CTFrameDraw(colFrames[columnIdx], context);
    }
    
    for ( UIView* v in self.subviews ) {
        if ( [v isKindOfClass: [MarkedTextButton class]] ) {
            [v removeFromSuperview];
        }
    }
    
    for ( NSInteger columnIdx = 0; columnIdx < self.columnsNumber; ++columnIdx ) {
        CTFrameRef frame = colFrames[columnIdx];

        NSArray* lines = (__bridge NSArray *)CTFrameGetLines( frame );

        CGFloat frameHeight = 0;

        CGPoint lineOrigins[lines.count];
        CTFrameGetLineOrigins( frame, CFRangeMake(0, (NSInteger)lines.count), lineOrigins );

        for ( NSUInteger lineIndex = 0; lineIndex < lines.count; ++lineIndex ) {
            CTLineRef line = (__bridge CTLineRef)[lines objectAtIndex: lineIndex];

            CGFloat ascent = 0;
            CGFloat descent = 0;
            CGFloat leading = 0;
            CTLineGetTypographicBounds( line, &ascent, &descent, &leading);

            frameHeight += (ascent + descent + leading);

            NSArray* runs = (__bridge NSArray *)CTLineGetGlyphRuns( line );
            for ( NSUInteger runIndex = 0; runIndex < runs.count; ++runIndex ) {
                CTRunRef run = (__bridge CTRunRef)[runs objectAtIndex: runIndex];
                CFRange runCFRange = CTRunGetStringRange( run );
                NSRange runRange = (NSRange){(NSUInteger)runCFRange.location, (NSUInteger)runCFRange.length};

                NSValue* parentRangeValue = [self parentForRange: runRange];
                if ( parentRangeValue ) {
                    NSRange parentRange = [parentRangeValue rangeValue];
                    CGFloat runAscent = 0;
                    CGFloat runDescent = 0;
                    CGFloat runLeading = 0;
                    
                    double runWidth = CTRunGetTypographicBounds( run, CFRangeMake(0, runCFRange.length), &runAscent, &runDescent, &runLeading );

                    CGFloat topY = lineOrigins[lineIndex].y;
                    CGFloat leftX = CTLineGetOffsetForStringIndex( line, (NSInteger)runRange.location, NULL );
                    CGFloat runHeight = runAscent + runDescent + runLeading;

                    CGFloat colOriginX = (colWidth + self.columnPadding) * columnIdx;
                    CGRect buttonFrame = CGRectMake( colOriginX + leftX - 5, rect.size.height - (topY - runDescent + runHeight) - 5, (CGFloat)runWidth + 10, runHeight + 7 );

                    UIImage* selImage = [UIImage imageNamed: @"searchSelection.png"];
                    selImage = [selImage stretchableImageWithLeftCapWidth: (int)(selImage.size.width/2) topCapHeight: (int)(selImage.size.height/2)];

                    MarkedTextButton* textButton = [[MarkedTextButton alloc] initWithFrame: buttonFrame];
                    [textButton addTarget: self action: @selector(markedTextButtonTouchUpInside:) forControlEvents: UIControlEventTouchUpInside];
                    
                    textButton.backgroundColor = [UIColor clearColor];
                    textButton.userInteractionEnabled = YES;
                    [textButton setTitleColor: [UIColor blackColor] forState: UIControlStateNormal];
                    [textButton setTitleShadowColor: [UIColor colorWithWhite: 1 alpha: 0.5] forState: UIControlStateNormal];
                    [textButton.titleLabel setShadowOffset: CGSizeMake(0, 1)];
                    
                    [textButton setTitle: [[attrText string] substringWithRange: runRange] forState: UIControlStateNormal];
                    [textButton setText: [[attrText string] substringWithRange: parentRange]];
                    [textButton setBackgroundImage: selImage forState: UIControlStateNormal];
                    
                    [self addSubview: textButton];
                    [self bringSubviewToFront: textButton];
                }
            }
        }
    }

    for ( NSInteger columnIdx = 0; columnIdx < self.columnsNumber; ++columnIdx ) {
        CFRelease(colFrames[columnIdx]);
        CFRelease(columnRectPaths[columnIdx]);
    }
    CFRelease( frameSetter );
}

// Public methods

- (void)selectTextWithPattern:(NSString *)pattern {
    if ( !self.attrText ) {
        return;
    }
    self.attrText = self.initialAttrText;
    NSMutableArray* ranges = [[NSMutableArray alloc] initWithCapacity: 0];
    __autoreleasing NSError* error = nil;
    
    NSRegularExpression* regexp = [NSRegularExpression regularExpressionWithPattern: pattern options: NSRegularExpressionCaseInsensitive error: &error];
    
    NSMutableAttributedString* attrTextMutable = [[NSMutableAttributedString alloc] initWithAttributedString: self.attrText];
    
    [regexp enumerateMatchesInString: [self.attrText string] options: 0 range: (NSRange){0,self.attrText.length} usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
        // On match
        [ranges addObject: [NSValue valueWithRange: [result range]]];
        [attrTextMutable addAttribute: (__bridge id)kCTForegroundColorAttributeName value: (__bridge id)[UIColor redColor].CGColor range: [result range]];
    }];
    
    self.attrText = [[NSAttributedString alloc] initWithAttributedString: attrTextMutable];
    self.selectionRanges = [NSArray arrayWithArray: ranges];
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

- (void)updateWithAttributedString:(NSAttributedString *)attrText_ {
    self.attrText = attrText_;
    self.initialAttrText = attrText_;
    [self setNeedsDisplay];
    [self setNeedsLayout];
}

@end
