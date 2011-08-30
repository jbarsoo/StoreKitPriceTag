//
//  SKPTBuyButton.h
//
//  Created by Jason Browning on 11/12/10.
//  Copyright 2010-2011 Jason Browning.
//  Licensed under the MIT license
//  http://github.com/jasonb-too/StoreKitPriceTag/blob/master/MIT-LICENSE.txt
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface SKPTBuyButton : UISegmentedControl <SKPaymentTransactionObserver, SKProductsRequestDelegate>
{
	UIActivityIndicatorView	*spinner;
	NSString		*price;
	NSMutableString		*prodIdent;
	NSString		*currentDisplayedPrice;
	NSUInteger		status;

	NSMutableData		*receivedData;
	SKProductsRequest	*prodRequest;
	NSManagedObjectContext	*moc;
	BOOL			showAlerts;
}

@property (nonatomic, retain) NSManagedObjectContext *moc;
@property (nonatomic, retain) NSString *price;
@property (nonatomic, retain) NSString *currentDisplayedPrice;

- (id)initWithMoc:(NSManagedObjectContext *)moc;

@end
