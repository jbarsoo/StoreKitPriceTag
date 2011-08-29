//
//  TBYBStoreObserver.h
//
//  Created by Jason Browning on 11/12/10.
//  Copyright 2010-2011 Jason Browning.
//  Licensed under the MIT license
//  http://github.com/jasonb-too/StoreKitPriceTag/blob/master/MIT-LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>
#import <UIKit/UIKit.h>
#import "Intent.h"
@class TBYBStoreButton;

@interface TBYBStoreObserver : NSObject <SKPaymentTransactionObserver, SKProductsRequestDelegate>
{
	NSMutableData		*receivedData;
	BOOL			showAlerts;
	NSManagedObjectContext	*moc;
	SKProductsRequest	*prodRequest;
	TBYBStoreButton		*buttonObj;
}

@property (nonatomic, retain) TBYBStoreButton *buttonObj;
@property (nonatomic, retain) NSManagedObjectContext *moc;

- (id)initWithMoc:(NSManagedObjectContext *)moc;
- (void)requestSaleSlip;

@end
