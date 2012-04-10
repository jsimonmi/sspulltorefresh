//
//  SSPullToRefreshView.m
//  SSPullToRefresh
//
//  Created by Sam Soffes on 4/9/12.
//  Copyright (c) 2012 Sam Soffes. All rights reserved.
//

#import "SSPullToRefreshView.h"

@interface SSPullToRefreshView ()
@property (nonatomic, assign, readwrite) UIScrollView *scrollView;
@property (nonatomic, assign) SSPullToRefreshViewState state;
- (void)_setContentInsetTop:(CGFloat)topInset;
@end

@implementation SSPullToRefreshView {
	UIEdgeInsets _deafultContentInset;
}

@synthesize delegate = _delegate;
@synthesize scrollView = _scrollView;
@synthesize expandedHeight = _expandedHeight;
@synthesize contentView = _contentView;
@synthesize state = _state;


#pragma mark - Accessors

- (void)setState:(SSPullToRefreshViewState)state {
    _state = state;
	
	switch (_state) {
		case SSPullToRefreshViewStateReady: {
			[self _setContentInsetTop:0.0f];
			break;
		}
			
		case SSPullToRefreshViewStateNormal: {
			[self _setContentInsetTop:0.0f];
			break;
		}
			
		case SSPullToRefreshViewStateLoading: {
			[self _setContentInsetTop:self.expandedHeight];
			[self refreshLastUpdatedAt];
			break;
		}
	}
	
	// Forward to content view
	if ([self.contentView respondsToSelector:@selector(setState:withPullToRefreshView:)]) {
		[self.contentView setState:_state withPullToRefreshView:self];
	}
}


- (void)setScrollView:(UIScrollView *)scrollView {
	void *context = (__bridge void *)self;
	if ([_scrollView respondsToSelector:@selector(removeObserver:forKeyPath:context:)]) {
		[_scrollView removeObserver:self forKeyPath:@"contentOffset" context:context];
	} else if (_scrollView) {
		[_scrollView removeObserver:self forKeyPath:@"contentOffset"];
	}
	
	_scrollView = scrollView;	
	_deafultContentInset = _scrollView.contentInset;
	[_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:context];
}


#pragma mark - NSObject

- (void)dealloc {
	self.scrollView = nil;
	self.delegate = nil;
}


#pragma mark - UIView

- (void)removeFromSuperview {
	self.scrollView = nil;
	[super removeFromSuperview];
}


#pragma mark - Initializer

- (id)initWithScrollView:(UIScrollView *)scrollView {
	CGRect frame = CGRectMake(0.0f, 0.0f - scrollView.bounds.size.height, scrollView.bounds.size.width,
							  scrollView.bounds.size.height);
	if ((self = [super initWithFrame:frame])) {
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
		self.scrollView = scrollView;
		self.state = SSPullToRefreshViewStateNormal;
		self.expandedHeight = 80.0f;
		
		[self.scrollView addSubview:self];
	}
	return self;
}


#pragma mark - Loading

- (void)finishedLoading {
	// If we're not loading, this method has no effect
    if (_state != SSPullToRefreshViewStateLoading) {
		return;
	}
	
	// Animate back to the normal state
	[UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
		self.state = SSPullToRefreshViewStateNormal;
	} completion:nil];
}


- (void)refreshLastUpdatedAt {
	NSDate *date = nil;
	if ([_delegate respondsToSelector:@selector(pullToRefreshViewLastUpdatedAt:)]) {
		date = [_delegate pullToRefreshViewLastUpdatedAt:self];
	} else {
		date = [NSDate date];
	}
	
	// Forward to content view
	if ([self.contentView respondsToSelector:@selector(setLastUpdatedAt:withPullToRefreshView:)]) {
		[self.contentView setLastUpdatedAt:date withPullToRefreshView:self];
	}
}


#pragma mark - Private

- (void)_setContentInsetTop:(CGFloat)topInset {
	// Default to the scroll view's initial content inset
	UIEdgeInsets inset = _deafultContentInset;
	
	// Add the top inset
	inset.top += topInset;
	
	// Update the content inset
	_scrollView.contentInset = inset;
}


#pragma mark - NSKeyValueObserving

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
	// Call super if we didn't register for this notification
	if (context != (__bridge void *)self) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}
	
	// We don't care about this notificaiton
	if (object != _scrollView || ![keyPath isEqualToString:@"contentOffset"]) {
		return;
	}
	
	// Get the offset out of the change notification
	CGFloat y = [[change objectForKey:NSKeyValueChangeNewKey] CGPointValue].y;
	
	// Scroll view is dragging
	if (_scrollView.isDragging) {
		// Scroll view is ready
		if (_state == SSPullToRefreshViewStateReady) {
			// Dragged enough to refresh
			if (y > -_expandedHeight - 5.0f && y < 0.0f) {
				self.state = SSPullToRefreshViewStateNormal;
			}
		// Scroll view is normal
		} else if (_state == SSPullToRefreshViewStateNormal) {
			// Dragged enough to be ready
			if (y < -_expandedHeight - 5.0f) {
				self.state = SSPullToRefreshViewStateReady;
			}
		// Scroll view is loading
		} else if (_state == SSPullToRefreshViewStateLoading) {
			if (y >= 0.0f) {
				[self _setContentInsetTop:0.0f];
			} else {
				[self _setContentInsetTop:MIN(-y, _expandedHeight)];
			}
		}
		
		return;
	}
	
	// If the scroll view isn't ready, we're not interested
	if (_state != SSPullToRefreshViewStateReady) {
		return;
	}
	
	// We're ready, prepare to switch to loading. Be default, we should refresh.
	SSPullToRefreshViewState newState = SSPullToRefreshViewStateLoading;
	
	// Ask the delegate if it's cool to start loading
	if ([_delegate respondsToSelector:@selector(pullToRefreshViewShouldRefresh:)]) {
		if (![_delegate pullToRefreshViewShouldRefresh:self]) {
			// Animate back to normal since the delegate said no
			newState = SSPullToRefreshViewStateNormal;
		}
	}
	
	// Animate to the new state
	[UIView animateWithDuration:0.2 delay:0.0 options:UIViewAnimationCurveEaseInOut | UIViewAnimationOptionAllowUserInteraction animations:^{
		self.state = newState;
	} completion:nil];
}

@end