//
//  FirstViewController.m
//  CoreTextDemo
//
//  Created by Konstantin Kiselyov on 9/18/12.
//  Copyright (c) 2012 Any Void. All rights reserved.
//

#import "FirstViewController.h"
#import "AdvancedTextView.h"
#import <QuartzCore/QuartzCore.h>

@interface FirstViewController ()
@property (strong, nonatomic) AdvancedTextView* textView;
@property (strong, nonatomic) NSArray* clippingViews;

- (NSAttributedString *)getAttributedText;
- (UIView *)createClipingViewIndex:(NSInteger)index;
- (NSArray *)clipingPathsWithViews:(NSArray *)views;
- (void)didPanWithRecognizer:(UIPanGestureRecognizer *)recognizer;
@end

@implementation FirstViewController
@synthesize textView, clippingViews;

- (UIView *)createClipingViewIndex:(NSInteger)index {
    const NSInteger rowCount = 3;
    CGFloat width = self.view.frame.size.width / rowCount;
    
    UIView* ret = [[UIView alloc] initWithFrame: CGRectMake(index % rowCount * width, index / rowCount * width, width, width)];
    [ret setTag: index];
    
    if (index % 2 == 0 ) {
        ret.backgroundColor = [UIColor redColor];
        
        CAShapeLayer* maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.path = [UIBezierPath bezierPathWithRoundedRect: ret.bounds cornerRadius: floorf(width/2.0)].CGPath;
        
        [ret.layer setMasksToBounds: YES];
        [ret.layer setMask: maskLayer];
        
    }
    else {
        ret.backgroundColor = [UIColor blueColor];
    }
    
    UIPanGestureRecognizer* panRec = [[UIPanGestureRecognizer alloc] initWithTarget: self action: @selector(didPanWithRecognizer:)];
    [ret addGestureRecognizer: panRec];
    return ret;
}

- (NSArray *)clipingPathsWithViews:(NSArray *)views {
    NSMutableArray* ret = [[NSMutableArray alloc] initWithCapacity: 0];
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, self.textView.frame.size.height);
    transform = CGAffineTransformScale(transform, 1, -1);
    
    for ( UIView* v in views ) {
        NSInteger tag = v.tag;
        CGMutablePathRef path = CGPathCreateMutable();
        
        if ( tag % 2 == 0 ) {
            CGPathAddPath(path, &transform, [UIBezierPath bezierPathWithRoundedRect: v.frame cornerRadius: floorf(v.bounds.size.width/2.0)].CGPath);
        }
        else {
            CGPathAddRect(path, &transform, v.frame);
        }
        [ret addObject: (__bridge id)(path)];
    }
    return [NSArray arrayWithArray: ret];
}

- (void)didPanWithRecognizer:(UIPanGestureRecognizer *)recognizer {
    CGPoint translation = [recognizer translationInView: recognizer.view];

    if ( recognizer.state == UIGestureRecognizerStateChanged ) {
        UIView* recView = recognizer.view;
        CGRect newFrame = recView.frame;
        newFrame.origin.x += translation.x;
        newFrame.origin.y += translation.y;
        recView.frame = newFrame;

        self.textView.clippingPaths = [self clipingPathsWithViews: self.clippingViews];
        [self.textView setNeedsDisplay];
        [self.textView setNeedsLayout];
    }
    [recognizer setTranslation: CGPointZero inView: recognizer.view];
}

- (NSAttributedString *)getAttributedText {
    NSString* plainText = @"Самосогласованная модель предсказывает, что при определенных условиях вещество трансформирует межядерный фонон - все дальнейшее далеко выходит за рамки текущего исследования и не будет здесь рассматриваться. Плазменное образование ненаблюдаемо. Ударная волна, несмотря на внешние воздействия, выталкивает квантово-механический пульсар, что лишний раз подтверждает правоту Эйнштейна. Не только в вакууме, но и в любой нейтральной среде относительно низкой плотности колебание случайно. Экситон концентрирует тангенциальный лептон одинаково по всем направлениям. Вещество мономолекулярно вращает изобарический фронт как при нагреве, так и при охлаждении. Вещество притягивает изобарический гидродинамический удар, и это неудивительно, если вспомнить квантовый характер явления. Линза наблюдаема. В соответствии с принципом неопределенности, солитон усиливает ускоряющийся электрон - все дальнейшее далеко выходит за рамки текущего исследования и не будет здесь рассматриваться. Суспензия едва ли квантуема. Фотон сжимает сверхпроводник, но никакие ухищрения экспериментаторов не позволят наблюдать этот эффект в видимом диапазоне. Возмущение плотности непрозрачно. Гамма-квант, как и везде в пределах наблюдаемой вселенной, искажает короткоживущий лептон вне зависимости от предсказаний самосогласованной теоретической модели явления. В соответствии с принципом неопределенности, среда расщепляет экситон, что лишний раз подтверждает правоту Эйнштейна.";
    
    NSMutableAttributedString* ret = [[NSMutableAttributedString alloc] initWithString: plainText];
    
    CTFontRef fontRef = CTFontCreateWithName( (__bridge CFStringRef)kFontNameMetaNormal, 20, NULL );
    [ret addAttribute: (id)kCTFontAttributeName value: (__bridge id)(fontRef) range: (NSRange){0, plainText.length}];
    [ret addAttribute: (id)kCTForegroundColorAttributeName value: (__bridge id)[UIColor colorWithRed: 40/255.0 green: 56/255.0 blue: 72/255.0 alpha: 1.0].CGColor range: (NSRange){0, plainText.length}];
    
    return [[NSAttributedString alloc] initWithAttributedString: ret];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear: animated];

    if ( self.textView ) {
        [self.textView removeFromSuperview];
    }
    
    self.textView = [[AdvancedTextView alloc] initWithFrame: self.containerView.bounds];
    self.textView.clipsToBounds = YES;

    NSMutableArray* clippingViewsMutable = [[NSMutableArray alloc] initWithCapacity: 0];
    for ( int i = 0; i < 1; ++i ) {
        UIView* v = [self createClipingViewIndex: i];
        [clippingViewsMutable addObject: v];
        [self.textView addSubview: v];
    }
    self.clippingViews = [NSArray arrayWithArray: clippingViewsMutable];
    [self.textView setDelegate: self];
    [self.textView setClippingPaths: [self clipingPathsWithViews: self.clippingViews]];
    [self.textView setColumnsNumber: 1];
    [self.textView setColumnPadding: 20.0f];
    [self.textView updateWithAttributedString: [self getAttributedText]];
    [self.textView setBackgroundColor: [UIColor whiteColor]];
    
    [self.containerView addSubview: self.textView];
    [self.containerView bringSubviewToFront: self.textView];
}

- (void)didPressMarkedText:(NSString *)text {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Search result" message: text delegate: nil cancelButtonTitle: @"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)searchButtonTouchUpInside:(id)sender {
    UITextField* searchTextField = (UITextField *)self.searchField.customView;
    if ( searchTextField.text.length > 0 ) {
        [self.textView selectTextWithPattern: searchTextField.text];
    }
}
@end
