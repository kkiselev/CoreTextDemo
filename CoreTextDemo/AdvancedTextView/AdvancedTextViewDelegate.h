//
//  AdvancedTextViewDelegate.h
//  CoreTextDemo
//
//  Created by Konstantin Kiselyov on 9/19/12.
//  Copyright (c) 2012 Any Void. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol AdvancedTextViewDelegate <NSObject>
@optional
- (void)didPressMarkedText:(NSString *)text;
@end
