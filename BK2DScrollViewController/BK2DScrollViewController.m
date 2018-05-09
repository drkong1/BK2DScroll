// BK2DScrollViewController.m
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

#import "BK2DScrollViewController.h"
#import "BKHitCoverView.h"

@interface BK2DScrollViewController ()
<UIScrollViewDelegate, BKHitCoverViewDelegate>

@property (nonatomic, assign) BOOL layoutSubviews;

@property (nonatomic, strong) IBOutlet UIScrollView *horizontalPagingScrollView;

@property (nonatomic, strong) UIView *wholeHeaderView;//self.headerview + self.pageMenuView

@property (nonatomic, strong) BKHitCoverView *hitCover;

@end

@implementation BK2DScrollViewController

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder]) == nil) return nil;
    
    self.currentPage = -1;
    self.enablePaging = YES;
    self.startPage = 0;
    
    return self;
}


- (void)dealloc {
    for (UIScrollView *scroll in self.innerScrolls) {
        [scroll removeObserver:self forKeyPath:@"contentSize"];
    }
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.view.backgroundColor = [UIColor clearColor];
    self.horizontalPagingScrollView.delegate = self;
    self.view.clipsToBounds = YES;
    
    self.horizontalPagingScrollView.scrollsToTop = NO;
}


- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if (!self.layoutSubviews) {
        self.layoutSubviews = YES;
        
        // wholeHeaderView
        self.wholeHeaderView = [UIView new];
        self.wholeHeaderView.frame = CGRectMake(0, 0, self.view.frame.size.width,
                                    self.headerview.frame.size.height + self.pageMenuView.frame.size.height);
        self.wholeHeaderView.backgroundColor = [UIColor clearColor];
        
        CGRect frame = self.headerview.frame;
        frame.origin.y = 0;
        frame.size.width = self.view.frame.size.width;
        self.headerview.frame = frame;
        [self.wholeHeaderView addSubview:self.headerview];
        
        frame = self.pageMenuView.frame;
        frame.origin.y = self.headerview.frame.size.height;
        self.pageMenuView.frame = frame;
        [self.wholeHeaderView addSubview:self.pageMenuView];
        
        // innerScroll
        NSUInteger index = 0;
        for (UIScrollView *scroll in self.innerScrolls) {
            scroll.frame = CGRectMake(index * self.view.frame.size.width, 0,
                                      self.view.frame.size.width, self.view.frame.size.height);
            
            UIEdgeInsets insets = scroll.contentInset;
            insets.top = self.wholeHeaderView.frame.size.height;
            scroll.contentInset = insets;
            if (!self.scrollIndicatorOnHeader) {
                scroll.scrollIndicatorInsets = insets;
            }
            
            [self.horizontalPagingScrollView addSubview:scroll];
            [scroll setContentOffset:CGPointMake(0, -insets.top)];
            [scroll addObserver:self forKeyPath:@"contentSize" options:NSKeyValueObservingOptionNew context:NULL];
            index++;
        }
        self.horizontalPagingScrollView.contentSize = CGSizeMake(self.view.frame.size.width * self.innerScrolls.count,
                                             self.view.frame.size.height);
        self.horizontalPagingScrollView.scrollEnabled = YES;
        
        // hitCover
        _hitCover = [BKHitCoverView new];
        _hitCover.backgroundColor = [UIColor clearColor];
        _hitCover.delegate = self;
        _hitCover.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_hitCover];
        NSDictionary *viewsDictionary = @{@"hitCover":_hitCover};
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"H:|[hitCover]|"
                                   options:0
                                   metrics:nil
                                   views:viewsDictionary]];
        [self.view addConstraints:[NSLayoutConstraint
                                   constraintsWithVisualFormat:@"V:|[hitCover]|"
                                   options:0
                                   metrics:nil
                                   views:viewsDictionary]];
        
        // show first page
        if (self.innerScrolls.count > 1 && self.startPage != 0) {
            [self moveToPage:self.startPage animated:NO];
        } else {
            [self pageDidChange:0];
        }
    }
}


#pragma mark - getter / setter
- (void)setEnablePaging:(BOOL)enablePaging {
    _enablePaging = enablePaging;
    self.horizontalPagingScrollView.scrollEnabled = self.enablePaging;
}


#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([object isKindOfClass:[UIScrollView class]] && [keyPath isEqualToString:@"contentSize"]) {
        UIScrollView *scroll = (UIScrollView *)object;
        
        if ([self.innerScrolls indexOfObject:scroll] != NSNotFound) {
            CGFloat realContentHeight = scroll.contentSize.height;
            CGFloat expectedContentHeight = self.view.frame.size.height - (self.pageMenuView.frame.size.height + self.titleBarHeight);
            UIEdgeInsets inset = scroll.contentInset;
            inset.bottom = realContentHeight>expectedContentHeight?0:expectedContentHeight-realContentHeight;
            scroll.contentInset = inset;
        }
    } else {
        // Make sure to call the superclass's implementation in the else block in case it is also implementing KVO
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (scrollView != self.horizontalPagingScrollView)
        return;
    
    UIScrollView *scroll = self.innerScrolls[[self pageIndex]];
    if (scroll.contentOffset.y > 0)
        return;
    
    CGRect frame = self.wholeHeaderView.frame;
    frame.origin.y = -(scroll.contentOffset.y + frame.size.height);
    self.wholeHeaderView.frame = frame;
    [self.view addSubview:self.wholeHeaderView];
}


- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // user dragging
    if (scrollView != self.horizontalPagingScrollView)
        return;
    
    NSInteger page = [self pageIndex];
    [self pageDidChange:page];
}


- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    // by pageMenuView
    if (scrollView != self.horizontalPagingScrollView)
        return;
    
    NSInteger page = [self pageIndex];
    [self pageDidChange:page];
}


#pragma mark - BKHitCoverViewDelegate
- (void)hitPassView:(BKHitCoverView*)hitPassView didTouchPoint:(CGPoint)point {
    if (self.enablePaging == NO)
        return;
    
    UIScrollView *scroll = self.innerScrolls[[self pageIndex]];
    if (scroll.contentOffset.y > 0) {
        self.horizontalPagingScrollView.scrollEnabled = YES;
        return;
    }
    
    CGFloat shownHeaderHeight = -scroll.contentOffset.y;
    if (point.y > shownHeaderHeight) {
        self.horizontalPagingScrollView.scrollEnabled = YES;
    } else {
        self.horizontalPagingScrollView.scrollEnabled = NO;
    }
}


#pragma mark - public
- (void)innerScrollDidStopScroll:(UIScrollView *)scrollView {
    CGFloat newOffsetY = scrollView.contentOffset.y;
    CGFloat tabBarHeight = -(self.pageMenuView.frame.size.height + self.titleBarHeight);
    
    for (UIScrollView *scroll in self.innerScrolls) {
        if (scroll != scrollView) {
            CGPoint offset = scroll.contentOffset;
            if (newOffsetY < tabBarHeight) {// headerview
                offset.y = MAX(newOffsetY, -(self.wholeHeaderView.frame.size.height));
                scroll.contentOffset = offset;
            } else {
                if (offset.y < tabBarHeight) {
                    offset.y = tabBarHeight;
                    scroll.contentOffset = offset;
                } else {
                }
            }
        }
    }
}


- (void)innerScrollDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetY = scrollView.contentOffset.y;
    
    if (offsetY < - (self.pageMenuView.frame.size.height + self.titleBarHeight)) {
        if (self.pageMenuView.superview != self.wholeHeaderView) {
            CGRect frame = self.pageMenuView.frame;
            frame.origin.y = self.headerview.frame.size.height;
            self.pageMenuView.frame = frame;
            
            [self.wholeHeaderView addSubview:self.pageMenuView];
        }
    } else {
        if (self.pageMenuView.superview != self.view) {
            CGRect frame = self.pageMenuView.frame;
            frame.origin.y = self.titleBarHeight;
            self.pageMenuView.frame = frame;
            
            [self.view insertSubview:self.pageMenuView belowSubview:_hitCover];
        }
    }
}


- (void)headerHeightDidChange {
    CGRect frame = self.wholeHeaderView.frame;
    frame.size.height = self.headerview.frame.size.height + self.pageMenuView.frame.size.height;
    frame.origin.y = -frame.size.height;
    self.wholeHeaderView.frame = frame;
    
    if (self.pageMenuView.superview == self.wholeHeaderView) {
        frame = self.pageMenuView.frame;
        frame.origin.y = self.headerview.frame.size.height;
        self.pageMenuView.frame = frame;
    }
    
    for (UIScrollView *scroll in self.innerScrolls) {
        UIEdgeInsets insets = scroll.contentInset;
        insets.top = self.wholeHeaderView.frame.size.height;
        scroll.contentInset = insets;
        if (!self.scrollIndicatorOnHeader) {
            scroll.scrollIndicatorInsets = insets;
        }
    }
}


- (void)moveToPage:(NSInteger)newPage animated:(BOOL)animated {
    // stop current scroll
    NSInteger page = [self pageIndex];
    UIScrollView *scroll = self.innerScrolls[page];
    CGPoint co = scroll.contentOffset;
    [scroll setContentOffset:co animated:NO];
    
    [self scrollViewWillBeginDragging:self.horizontalPagingScrollView];
    
    [self.horizontalPagingScrollView scrollRectToVisible:CGRectMake(self.horizontalPagingScrollView.frame.size.width * newPage, 0, self.horizontalPagingScrollView.frame.size.width, self.horizontalPagingScrollView.frame.size.height) animated:animated];
    
    if (!animated) {
        [self pageDidChange:newPage];
    }
}


#pragma mark - private
- (void)pageDidChange:(NSInteger)page {
    CGFloat offsetX = self.horizontalPagingScrollView.contentOffset.x;
    
    if (0 <= offsetX && offsetX <= self.horizontalPagingScrollView.contentSize.width - self.horizontalPagingScrollView.frame.size.width) {
        [self addHeaderToTableAtIndex:page];
    } else {
        // bounce
    }
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(bk2dScroll:didChangePage:)]) {
        if (_currentPage != page) {
            [self.delegate bk2dScroll:self didChangePage:page];
        }
    }
    
    _currentPage = page;
}


- (NSInteger)pageIndex {
    NSInteger index = (self.horizontalPagingScrollView.contentOffset.x + 100) / self.horizontalPagingScrollView.frame.size.width;
    return index;
}


- (void)addHeaderToTableAtIndex:(NSInteger)index {
    CGRect frame = self.wholeHeaderView.frame;
    frame.origin.y = -frame.size.height;
    self.wholeHeaderView.frame = frame;
    [self.innerScrolls[index] addSubview:self.wholeHeaderView];
}

@end













