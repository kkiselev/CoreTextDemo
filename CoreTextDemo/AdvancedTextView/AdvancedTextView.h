//
//  AdvancedTextView.h
//  CoreTextDemo
//
//  Created by Konstantin Kiselyov on 9/18/12.
//  Copyright (c) 2012 Any Void. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>
#import "AdvancedTextViewDelegate.h"

#define kFontNameMetaNormal     @"MetaPro-Norm"
#define kFontNameMetaBook       @"MetaPro-Book"
#define kFontNameMetaMedium     @"MetaPro-Medi"
#define kFontNameMetaBold       @"MetaPro-Bold"

@interface AdvancedTextView : UIView

@property (assign, nonatomic) NSInteger columnsNumber;
@property (assign, nonatomic) CGFloat columnPadding;
@property (strong, nonatomic) NSArray* clippingPaths;
@property (assign, nonatomic) id<AdvancedTextViewDelegate> delegate;

- (void)selectTextWithPattern:(NSString *)pattern;
- (void)updateWithAttributedString:(NSAttributedString *)attrText;

@end
