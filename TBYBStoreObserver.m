//
//  CjbStoreObserver.m
//  Intention+ally
//
//  Created by Jason Browning on 11/12/10.
//  Copyright 2010-2011 Jason Browning.
//  Licensed under the MIT license
//  http://github.com/jasonb-too/StoreKitPriceTag/blob/master/MIT-LICENSE.txt
//
//
//  Fork this file and insert an appropriate Managed Object Context (or other
//  such) implementation to record customer purchases.

#define _MAX_RESULTS_ 30

#import "TBYBStoreObserver.h"

@class Intention_allyAppDelegate;
@implementation TBYBStoreObserver

@synthesize moc, buttonObj;

- (void)dealloc
{
	receivedData = nil;
	[prodRequest release];
	[super dealloc];
}

- (id)initWithMoc:(NSManagedObjectContext *)moc
{
	id object = nil;
	if (self = [super init])
	{
		self.moc = moc;
		showAlerts = NO;

		/* Check the AppStore for pending transactions */
		[[SKPaymentQueue defaultQueue] addTransactionObserver: self];
		object = self;
	}
	
	return object;
}

- (void)requestSaleSlip
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
	NSString *URLString = @"https://store.[server].[tld]/path/to/query/script";
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: [URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
	[request setHTTPBody: [@"[BUY]" dataUsingEncoding: NSISOLatin1StringEncoding]];
	[request setHTTPMethod: @"POST"];
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (theConnection) {
		// Create an NSMutableData object for the received data.
		receivedData = [[NSMutableData data] retain];
		//NSLog(@"TBYBStoreObserver: connection: %@ method: %@, encoded body: %@, body: %@", theConnection, [request HTTPMethod], [request HTTPBody], @"Yub");
	} else {
		// Inform the user that the connection failed.
		NSLog(@"TBYBStoreObserver: NSURLConnection did not initiate.");
		[self sorryMsg:@"Unable to establish a connection."];
	}
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    //NSLog(@"TBYBStoreObserver: Calling `connection:didReceiveResponse`.");
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
	
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
	
    // receivedData is an instance variable declared elsewhere.
    [receivedData setLength:0];
    //NSLog(@"TBYBStoreObserver: Exiting `connection:didReceiveResponse`.");
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    //NSLog(@"TBYBStoreObserver: Calling `connection:didReceiveData`.");
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [receivedData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    //NSLog(@"TBYBStoreObserver: Calling `connection:didFailWithError`.");
    // release the connection, and the data object
    [connection release];
    receivedData = nil;
    // inform the user
    [self sorryMsg: [error localizedDescription]];
    NSLog(@"TBYBStoreObserver: Connection failed! Error - %@ %@",[error localizedDescription],[[error userInfo] objectForKey: NSURLErrorFailingURLStringErrorKey]);
    [self performSelector:@selector(requestSaleSlip) withObject:nil afterDelay:30.0]; // try again in 30 sec.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    //NSLog(@"TBYBStoreObserver: Calling `connectionDidFinishLoading`.");
    //NSLog(@"TBYBStoreObserver: Succeeded! Received %d bytes of data",[receivedData length]);
    // do something with the data
	
    [self requestProductsFromITunesWithSet: [self storeParser: receivedData]];
	
    // release the connection, and the data object
    [connection release];
}

- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace {
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	[challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];	
    
    [challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}

- (void)sorryMsg:(NSString *)msg
{
    if (showAlerts)
    {
	// Alert the user to the lack of results.
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry..." message:msg delegate:nil cancelButtonTitle:@"Close" otherButtonTitles:nil];
	[alert show];

	[alert release];
    }
}

/* Your Apple App must have a Product ID String registered via the	*
 * iTunesConnect.apple.com web site.  `storeParser` will parse the	*
 * response from your server for this identifier and return			*
 * its result as an NSSet object (for feeding to Apple's supplied	*
 * `requestProductsFromITunesWithSet` method (below).				*/
- (NSSet *)storeParser:(NSData *)data
{
	NSMutableSet *resultSet = [NSMutableSet setWithCapacity:0];
	static NSString *RE = @"\\b^([A-Za-z0-9 ]+).*$\\b";
	
	// Encode the data argument into an NSString object.
	NSString *dataReceived = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	//NSLog(@"TBYBStoreObserver: Response:\n%@", dataReceived);
	// Encode the regular expression.
	NSError *error = NULL;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: RE 
																		   options: NSRegularExpressionCaseInsensitive
																			 error: &error];	
	// Separate matched results into an array of NSTextCheckingResult objects.
	NSMutableArray *matches = [NSMutableArray arrayWithCapacity: 0];
	__block NSUInteger count = 0;
	[regex enumerateMatchesInString: dataReceived 
							options:NSMatchingReportCompletion 
							  range:NSMakeRange(0, [dataReceived length]) 
						 usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop)
	 {
		 if (match == nil)
			 *stop = YES;
		 else
		 {
			 //NSLog(@"\nTBYBStoreObserver: MATCH:\n(1)%@",[dataReceived substringWithRange: [match rangeAtIndex: 1]]);
			 [matches addObject: match];
			 if (++count >= _MAX_RESULTS_) *stop = YES;			
		 }
	 }];
	
	// Interpret the results.
	NSUInteger numResults = [matches count];
	if (numResults == 0)
		[self sorryMsg:@"The Store is unavailable at the moment.\nPlease try back later."];
	else
	{
		for (NSTextCheckingResult *match in matches) 
		{
			NSString *item = [dataReceived substringWithRange: [match rangeAtIndex: 1]];
			//NSLog(@"TBYBStoreObserver: found item %@", item);
			[resultSet addObject: item];
		}
	}
	return [NSSet setWithSet: resultSet];
}

- (void)requestProductsFromITunesWithSet:(NSSet *)productSet
{
	prodRequest = [[SKProductsRequest alloc] initWithProductIdentifiers: productSet];
	prodRequest.delegate = self;		
	[prodRequest start];
}

/* P R O D U C T S  R E Q U E S T : D I D  R E C E I V E  R E S P O N S E	*
 * If Apple likes your Product ID String, it will reply with a bunch of		*
 * product information; we just want the price (in its localized format)	*
 * which we will graft onto the `buttonObj`.								*/
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{	
	//NSLog(@"TBYBStoreObserver: Got productRequest Response: %@", response.products);

	if ([response.products count] > 0)
	{
		SKProduct *product = [response.products objectAtIndex: 0];
		if (buttonObj != nil)
		{
			NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
			
			[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
			[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
			[numberFormatter setLocale:product.priceLocale];
			NSString *price = [numberFormatter stringFromNumber:product.price];
			
			[buttonObj setPrice: price];
			[buttonObj setProdIdent: product.productIdentifier];
			[buttonObj getPrice];			

			[numberFormatter release];
		}
	}
	[request release];
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions)
    {
        switch (transaction.transactionState)
        {
            case SKPaymentTransactionStatePurchased:
                [self completePurchaseTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedPurchaseTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restorePurchaseTransaction:transaction];
            default:
                break;
        }
    }
}

- (void) completePurchaseTransaction: (SKPaymentTransaction *)transaction
{
	/* Record the transaction */
	{
		//NSLog(@"TBYBStoreObserver: completed transaction (%@).", transaction);
		[self recordPurchase: transaction];
	}
	[self providePurchasedContent: transaction.payment.productIdentifier];
	// Remove the transaction from the payment queue.
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) restorePurchaseTransaction: (SKPaymentTransaction *)transaction
{
	[self recordPurchase: transaction];
    [self providePurchasedContent: transaction.originalTransaction.payment.productIdentifier];
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

- (void) failedPurchaseTransaction: (SKPaymentTransaction *)transaction
{
    if (transaction.error.code != SKErrorPaymentCancelled)
    {
        // Optionally, display an error here.
    }
    [[SKPaymentQueue defaultQueue] finishTransaction: transaction];
}

/* R E C O R D  P U R C H A S E									*
 * Having successfully conducted a transaction, the customer	*
 * will want his/her product to always be available; make a		*
 * record of this purchase somewhere within your App's record	*
 * keeping aparatus.											*/
- (void)recordPurchase:(SKPaymentTransaction *)transaction
{
	// Do something on your App to record this successful purchase!
}

/* P R O V I D E  P U R C H A S E D  C O N T E N T				*
 * Here is where code for providing the purchased context to	*
 * the customer should go...  Remeber to thank the customer!	*/
- (void)providePurchasedContent:(NSString *)prodIdent
{
	//NSLog(@"TBYBStoreObserver: Providing Purchased Content.");

	NSString *msg = @"No really, thanks you very very very much!";
	UIAlertView *thanks = [[UIAlertView alloc] initWithTitle:@"Thank You!"
													message:msg
													delegate:nil
											cancelButtonTitle:@"Close"
											otherButtonTitles:nil];
	[thanks show];
	[thanks release];
}
@end
