//
//  SKPTBuyButton.m
//
//  Created by Jason Browning on 11/12/10.
//  Copyright 2010-2011 Jason Browning.
//  Licensed under the MIT license
//  http://github.com/jasonb-too/StoreKitPriceTag/blob/master/MIT-LICENSE.txt
//

#import "SKPTBuyButton.h"

#define _MAX_RESULTS_ 30

@implementation SKPTBuyButton

@synthesize price, currentDisplayedPrice, moc;

- (void)dealloc
{
	receivedData = nil;
	[currentDisplayedPrice release];
	if (spinner != nil)
		[spinner release];
	[price release];
	[prodIdent release];
	[prodRequest release];
	[super dealloc];
}

- (id)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
	id object = nil;
	if (self = [super initWithItems:[NSArray arrayWithObject: @"          "]])
	{
		self.moc = managedObjectContext;
		status = 0;
		currentDisplayedPrice = [[NSString alloc] initWithString:@" "];
		showAlerts = NO;

		/* Check the AppStore for pending transactions */
		[[SKPaymentQueue defaultQueue] addTransactionObserver: self];

		object = self;
	}
	
	return object;
}


- (void)didMoveToSuperview
{
	[super didMoveToSuperview];
	if (self.superview != nil)
	{
		NSLog(@"SKPTBuyButton: moving to superview (%@).", self.superview);
		spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		CGRect tempFrame = spinner.frame;
		tempFrame.origin.x = 22.5f;
		tempFrame.origin.y = 4.0f;
		spinner.frame = tempFrame;
		self.momentary = YES;
		self.segmentedControlStyle = UISegmentedControlStyleBar;
		self.tintColor = [UIColor colorWithRed:0.286f green:0.4f blue:0.616f alpha:1.0f];
		self.price = @" ";
		prodIdent = [[NSMutableString alloc] initWithString:@" "];
		[self performSelector:@selector(requestSaleSlip) withObject:nil afterDelay:5.0];
		[self spin: YES];
		[self addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventValueChanged];
	}
	else
	{
		NSLog(@"SKPTBuyButton: superview == nil.");
		[self removeTarget:self action:@selector(btnAction) forControlEvents:UIControlEventValueChanged];
		[spinner stopAnimating];
		[spinner removeFromSuperview];
		spinner = nil;
		[spinner release];
	}
}

- (void)spin:(BOOL)decision
{
	if (decision)
	{
		self.price = @" ";
		[self setTitle:@"          " forSegmentAtIndex: 0];
		if ([spinner superview] == nil)
			[self addSubview: spinner];
		
		[spinner startAnimating];		
	}
	else
	{
		[spinner stopAnimating];
		[spinner removeFromSuperview];		
	}	
}

- (void)getPrice
{
	NSLog(@"SKPTBuyButton(%@):\nentering `getPrice:`.", self);
	[self btnAction];
	[self performSelector:@selector(requestSaleSlip) withObject:nil afterDelay:3600.0];
}

- (void)btnAction
{	
	NSLog(@"SKPTBuyButton(%@):\ncalling btnAction.", self);
	if ([price isEqualToString:@" "])
	{
		NSLog(@"SKPTBuyButton(%@):\nPrice == nil!", self);
		[self requestSaleSlip];
		return;
	}
	
	if (status == 0) // replace current btn content with the price.
	{
		NSLog(@"SKPTBuyButton(%@):\nreplacing current btn content with the price and changing to status = 1.", self);
		[self spin: NO];
		[self setTitle: price forSegmentAtIndex: 0];
		self.momentary = YES;
		self.segmentedControlStyle = UISegmentedControlStyleBar;
		self.tintColor = [UIColor colorWithRed:0.286f green:0.4f blue:0.616f alpha:1.0f];
		[self setEnabled: YES forSegmentAtIndex: 0];
		status = 1;
	}
	else if (status == 1)
	{	// First, get an updated price.
		if ([currentDisplayedPrice isEqualToString:@" "])
		{
			NSLog(@"SKPTBuyButton (%@):\ngetting a fresh price.", self);
			self.currentDisplayedPrice = [NSString stringWithString: price];
			[self requestSaleSlip];
			[self spin: YES];
		}
		else if (![price isEqualToString: currentDisplayedPrice])
		{
			NSLog(@"SKPTBuyButton: currently displayed price is stale; changing to status = 0");
			[self spin: NO];
			[self setTitle: price forSegmentAtIndex: 0];
			self.currentDisplayedPrice = @" ";
			status = 0;
		}
		else // the updated price is the same as what is displayed -- good!
		{
			self.currentDisplayedPrice = @" ";
			[self setTitle: @"BUY" forSegmentAtIndex: 0]; // TODO: internationalize (localize) "BUY".
			self.tintColor = [UIColor colorWithRed:0.49f green:0.737f blue:0.392f alpha:1.0f];
			NSLog(@"SKPTBuyButton: Adding BUY target to button.");
			[self removeTarget:self action:_cmd forControlEvents:UIControlEventValueChanged];
			[self addTarget:self action:@selector(doSomething) forControlEvents:UIControlEventValueChanged];
			// The button now reads "BUY"; if the user ignores it for some time, reset to the price. //
			[self performSelector:_cmd withObject:nil afterDelay:30.0];
			NSLog(@"SKPTBuyButton: Changing to status = 2.");
			status = 2;
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TBYB1stPush" object:nil];
	}
	else if (status == 2) // revert to status == 0;
	{
		NSLog(@"SKPTBuyButton: Reverting to status = 0.");
		[self removeTarget:self action:@selector(doSomething) forControlEvents:UIControlEventValueChanged];
		[self addTarget:self action:_cmd forControlEvents:UIControlEventValueChanged];
		status = 0;
		[self performSelector:_cmd]; // re-run this method with the new status.
	}
}

- (void)doSomething
{
	NSLog(@"SKPTBuyButton: User's purchase request (%@) will be sent to Apple.", prodIdent);
	SKPayment *payment = [SKPayment paymentWithProductIdentifier:prodIdent];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)requestSaleSlip
{	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
	NSString *URLString = @"https://your.[server].[tld]/path/to/resource";
	
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: [URLString stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
	[request setHTTPBody: [@"Yub" dataUsingEncoding: NSISOLatin1StringEncoding]];
	[request setHTTPMethod: @"POST"];
	NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:request delegate:self];
	if (theConnection) {
		// Create the NSMutableData to hold the received data.
		// receivedData is an instance variable declared elsewhere.
		receivedData = [[NSMutableData data] retain];
		NSLog(@"connection: %@ method: %@, encoded body: %@, body: %@", theConnection, [request HTTPMethod], [request HTTPBody], @"Yub");
	} else {
		// Inform the user that the connection failed.
		NSLog(@"SKPTBuyButton: NSURLConnection did not initiate.");
		[self sorryMsg:@"Unable to establish a connection."];
	}	
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"SKPTBuyButton: Calling `connection:didReceiveResponse`.");
    // This method is called when the server has determined that it
    // has enough information to create the NSURLResponse.
	
    // It can be called multiple times, for example in the case of a
    // redirect, so each time we reset the data.
	
    // receivedData is an instance variable declared elsewhere.
    [receivedData setLength:0];
    NSLog(@"SKPTBuyButton: Exiting `connection:didReceiveResponse`.");
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    NSLog(@"SKPTBuyButton: Calling `connection:didReceiveData`.");
    // Append the new data to receivedData.
    // receivedData is an instance variable declared elsewhere.
    [receivedData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    NSLog(@"SKPTBuyButton: Calling `connection:didFailWithError`.");
    // release the connection, and the data object
    [connection release];
    receivedData = nil;
    // inform the user
    [self sorryMsg: [error localizedDescription]];
    NSLog(@"SKPTBuyButton: Connection failed! Error - %@ %@",[error localizedDescription],[[error userInfo] objectForKey: NSURLErrorFailingURLStringErrorKey]);
    [self performSelector:@selector(requestSaleSlip) withObject:nil afterDelay:30.0]; // try again in 30 sec.
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"SKPTBuyButton: Calling `connectionDidFinishLoading`.");
    NSLog(@"SKPTBuyButton: Succeeded! Received %d bytes of data",[receivedData length]);
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
 * response from your server for this identifier and return		*
 * its result as an NSSet object (for feeding to Apple's supplied	*
 * `requestProductsFromITunesWithSet` method (below).			*/
- (NSSet *)storeParser:(NSData *)data
{
	NSMutableSet *resultSet = [NSMutableSet setWithCapacity:0];
	static NSString *RE = @"\\b^([A-Za-z0-9 ]+).*$\\b";
	
	// Encode the data argument into an NSString object.
	NSString *dataReceived = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
	
	NSLog(@"SKPTBuyButton: Response:\n%@", dataReceived);
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
			 NSLog(@"\nSKPTBuyButton: MATCH:\n(1)%@",[dataReceived substringWithRange: [match rangeAtIndex: 1]]);
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
			NSLog(@"SKPTBuyButton: found item %@", item);
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
 * which we will graft onto the button (UISegmentedControl).			*/
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response
{	
	NSLog(@"SKPTBuyButton: Got productRequest Response: %@", response.products);

	if ([response.products count] > 0)
	{
		SKProduct *product = [response.products objectAtIndex: 0];
		NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc] init];
		
		[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[numberFormatter setLocale:product.priceLocale];
		self.price = [numberFormatter stringFromNumber:product.price];
		
		[prodIdent setString: product.productIdentifier];
		[self getPrice];

		[numberFormatter release];
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
		NSLog(@"SKPTBuyButton: completed transaction (%@).", transaction);
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
    NSLog(@"SKPTBuyButton: TODO: Implement code to *record* successful purchases!");
}

/* P R O V I D E  P U R C H A S E D  C O N T E N T				*
 * Here is where code for providing the purchased context to	*
 * the customer should go...  Remeber to thank the customer!	*/
- (void)providePurchasedContent:(NSString *)prodIdent
{
    NSLog(@"SKPTBuyButton: TODO: Implement code to *provide purchased content*!");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"Cjbtob" object:nil];
	NSString *msg = @"Intention+ally will now operate without restrictions.";
	UIAlertView *thanks = [[[UIAlertView alloc] initWithTitle:@"Thank You!"
							  message:msg
							 delegate:nil
						cancelButtonTitle:@"Close"
						otherButtonTitles:nil] autorelease];
	[thanks show];
}
@end
