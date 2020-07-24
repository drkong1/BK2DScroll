// ViewController.m
//
// Copyright (c) 2018 Hunjong Bong
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "ViewController.h"
#import "BK2DScrollViewController.h"

@interface ViewController ()
<UIScrollViewDelegate, BK2DScrollDelegate, BK2DScrollProtocol>

@property (nonatomic, strong) IBOutlet UIImageView *backImageView;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bgTopConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *bgHeightConstraint;
@property (nonatomic, strong) IBOutlet UIView *titleView;

@property (nonatomic, strong) IBOutlet UIView *headerView;
@property (nonatomic, strong) IBOutlet UIButton *headerButton;

@property (nonatomic, strong) IBOutlet UIView *pageContainerView;
@property (nonatomic, strong) IBOutlet UIButton *page1Button;
@property (nonatomic, strong) IBOutlet UIButton *page2Button;

@property (nonatomic, strong) UIScrollView *scroll1;
@property (nonatomic, strong) UIScrollView *scroll2;
@property (nonatomic, strong) NSMutableArray <UIScrollView *> *contents;

@property (nonatomic, strong) BK2DScrollViewController *bk2d;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    _contents = [NSMutableArray new];
    _page1Button.enabled = NO;
    _page2Button.enabled = YES;
    
    _pageContainerView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, _pageContainerView.frame.size.height);
    
    [self add2DScroll];
    
    [self titleColorForAlpha:0];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    NSInteger currentPage = _bk2d.currentPage;
    UIScrollView *scorllView = _contents[currentPage];
    if (scorllView && scorllView.decelerating) {
        [_bk2d innerScrollDidStopScroll:scorllView];
    }
}

- (IBAction)pageButton:(id)sender {
    if (sender == _headerButton) {
        NSLog(@"headerButton");
    } else if (sender == _page1Button) {
        _page1Button.enabled = NO;
        _page2Button.enabled = YES;
        
        [_bk2d moveToPage:0 animated:NO];
    } else if (sender == _page2Button) {
        _page1Button.enabled = YES;
        _page2Button.enabled = NO;
        
        [_bk2d moveToPage:1 animated:NO];
    }
}

- (void)loadData1 {
    static BOOL loaded1 = NO;
    if (loaded1) {
        return;
    }
    
    for (NSInteger i=0 ; i<10 ; i++) {
        UILabel *lbl = [UILabel new];
        lbl.frame = CGRectMake(0, i*100, 200, 90);
        lbl.backgroundColor = [UIColor redColor];
        lbl.text = [NSString stringWithFormat:@"page1: %ld", (long)i];
        [_scroll1 addSubview:lbl];
    }
    _scroll1.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 1000);
    
    loaded1 = YES;
}

- (void)loadData2 {
    static BOOL loaded2 = NO;
    if (loaded2) {
        return;
    }
    
    for (NSInteger i=0 ; i<15 ; i++) {
        UILabel *lbl = [UILabel new];
        lbl.frame = CGRectMake(0, i*100, 200, 90);
        lbl.backgroundColor = [UIColor blueColor];
        lbl.text = [NSString stringWithFormat:@"page2: %ld", (long)i];
        lbl.textColor = [UIColor yellowColor];
        [_scroll2 addSubview:lbl];
    }
    _scroll2.contentSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 1500);
    
    loaded2 = YES;
}

- (NSMutableArray *)addContentScrollView {
    NSMutableArray *scrolls = [NSMutableArray new];
    
    _scroll1 = [UIScrollView new];
    _scroll1.frame = [UIScreen mainScreen].bounds;
    _scroll1.backgroundColor = [UIColor clearColor];
    _scroll1.delegate = self;
    if (@available(iOS 11.0, *)) {
        _scroll1.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [scrolls addObject:_scroll1];
    [_contents addObject:_scroll1];
    
    _scroll2 = [UIScrollView new];
    _scroll2.frame = [UIScreen mainScreen].bounds;
    _scroll2.backgroundColor = [UIColor clearColor];
    _scroll2.delegate = self;
    if (@available(iOS 11.0, *)) {
        _scroll2.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [scrolls addObject:_scroll2];
    [_contents addObject:_scroll2];
    
    return scrolls;
}


- (void)add2DScroll {
    NSArray *scrolls = [self addContentScrollView];
    
    UIStoryboard *storyBoard = [UIStoryboard storyboardWithName:@"BK2DScrollViewController" bundle:[NSBundle mainBundle]];
    _bk2d = [storyBoard instantiateViewControllerWithIdentifier:@"BK2DScrollViewController"];
    _bk2d.headerview = _headerView;
    _bk2d.pageMenuView = _pageContainerView;
    _bk2d.innerScrolls = scrolls;
    _bk2d.scrollIndicatorOnHeader = NO;
    _bk2d.titleBarHeight = _titleView.frame.size.height;
    _bk2d.delegate = self;
    _bk2d.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view insertSubview:_bk2d.view belowSubview:_titleView];
    [self addChildViewController:_bk2d];
    [_bk2d didMoveToParentViewController:self];
    
    UIView *subView = _bk2d.view;
    id<UILayoutSupport> bottomLayoutGuide = self.bottomLayoutGuide;
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(subView, bottomLayoutGuide);
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"H:|[subView]|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
    [self.view addConstraints:[NSLayoutConstraint
                               constraintsWithVisualFormat:@"V:|[subView]-0-[bottomLayoutGuide]|"
                               options:0
                               metrics:nil
                               views:viewsDictionary]];
}

- (void)titleColorForAlpha:(CGFloat)alpha {
    //0.0 ~ 1.0
    if (alpha < 0.0)
        alpha = 0.0;
    if (alpha > 1.0)
        alpha = 1.0;
    
    _titleView.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:alpha];
}

- (CGFloat)headerHeight {
    return _headerView.frame.size.height;
}

#pragma mark - UIScrollViewDelegate && BK2DScrollProtocol
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [_bk2d innerScrollDidStopScroll:scrollView];// @required
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [_bk2d innerScrollDidScroll:scrollView];// @required
    
    CGPoint offset = scrollView.contentOffset;
    
    // title
    CGFloat alpha;
    if (offset.y < - [self headerHeight]/2)
        alpha = 0;
    else if (offset.y > -_pageContainerView.frame.size.height)
        alpha = 1.0;
    else {
        alpha = MIN((offset.y+[self headerHeight]/2)/([self headerHeight]/2 - _pageContainerView.frame.size.height - _titleView.frame.size.height), 1.0);
    }
    
    [self titleColorForAlpha:alpha];
    
    // bg
    CGFloat totalHeaderHeight = [self headerHeight] + _pageContainerView.frame.size.height;
    if (offset.y < -totalHeaderHeight) {
        _bgTopConstraint.constant = 0;
        _bgHeightConstraint.constant = [self headerHeight] + -offset.y - totalHeaderHeight;
    } else {
        _bgTopConstraint.constant = 0;
        _bgHeightConstraint.constant = MAX(0, [self headerHeight] + -offset.y - totalHeaderHeight);
    }
    [self.view layoutIfNeeded];
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [_bk2d innerScrollDidStopScroll:scrollView];// @required
}

- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView {
    [_bk2d innerScrollDidStopScroll:scrollView];// @required
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        [_bk2d innerScrollDidStopScroll:scrollView];// @required
    }
}


#pragma mark - BK2DScrollDelegate
- (void)bk2dScroll:(BK2DScrollViewController*)bk2dScroll didChangePage:(NSInteger)page {
    NSInteger index = 0;
    for (UIScrollView *scrollView in _contents) {
        if (index == page) {
            scrollView.scrollsToTop = YES;
        } else {
            scrollView.scrollsToTop = NO;
        }
        index++;
    }
    
    if (page == 0) {
        _page1Button.enabled = NO;
        _page2Button.enabled = YES;
        
        [self loadData1];
    } else {
        _page1Button.enabled = YES;
        _page2Button.enabled = NO;
        
        [self loadData2];
    }
}

@end
