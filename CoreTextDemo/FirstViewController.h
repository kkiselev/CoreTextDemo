//
//  FirstViewController.h
//  CoreTextDemo
//
//  Created by Konstantin Kiselyov on 9/18/12.
//  Copyright (c) 2012 Any Void. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AdvancedTextViewDelegate.h"

@interface FirstViewController : UIViewController<UIGestureRecognizerDelegate, AdvancedTextViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *containerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchField;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *searchButton;
- (IBAction)searchButtonTouchUpInside:(id)sender;

@end
