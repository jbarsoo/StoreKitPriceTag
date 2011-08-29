//
//  TBYBStoreButton.h
//
//  Created by Jason Browning on 11/12/10.
//  Copyright 2010-2011 Jason Browning.
//  Licensed under the MIT license
//  http://github.com/jasonb-too/StoreKitPriceTag/blob/master/MIT-LICENSE.txt
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>
@class TBYBStoreObserver;

@interface TBYBStoreButton : UISegmentedControl 
{
	UIActivityIndicatorView	*spinner;
	NSString		*price;
	TBYBStoreObserver	*storeObs;
	NSString		*prodIdent;
	NSString		*currentDisplayedPrice;
	NSUInteger		status;
}

@property (nonatomic, copy) NSString *price;
@property (nonatomic, copy) NSString *prodIdent;

- (void)getPrice;

@end
