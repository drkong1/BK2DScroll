// BK2DScrollViewController.h
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

#import <UIKit/UIKit.h>

@protocol BK2DScrollDelegate;

@interface BK2DScrollViewController : UIViewController
@property (nonatomic, weak) id<BK2DScrollDelegate> delegate;

@property (nonatomic, strong) UIView *headerview;

@property (nonatomic, strong) UIView *pageMenuView;

@property (nonatomic, assign) BOOL scrollIndicatorOnHeader;

@property (nonatomic, assign) CGFloat titleBarHeight;

@property (nonatomic, strong) NSArray<UIScrollView *> *innerScrolls;

@property (nonatomic, assign) BOOL enablePaging;//default is YES

@property (nonatomic, assign) NSInteger startPage;//default is 0

@property (nonatomic, assign) NSInteger currentPage;

- (void)innerScrollDidStopScroll:(UIScrollView *)scrollView;
- (void)innerScrollDidScroll:(UIScrollView *)scrollView;

- (void)moveToPage:(NSInteger)newPage animated:(BOOL)animated;

- (void)headerHeightDidChange;

@end

@protocol BK2DScrollProtocol <NSObject>

@required
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView;
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate;
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView;
- (void)scrollViewDidScrollToTop:(UIScrollView *)scrollView;
- (void)scrollViewDidScroll:(UIScrollView *)scrollView;

@end

@protocol BK2DScrollDelegate <NSObject>

@optional
- (void)bk2dScroll:(BK2DScrollViewController *)bk2dScroll didChangePage:(NSInteger)page;

@end








