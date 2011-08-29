//
//  TBYBStoreButton.m
//
//  Created by Jason Browning on 11/12/10.
//  Copyright 2010-2011 Jason Browning.
//  Licensed under the MIT license
//  http://github.com/jasonb-too/StoreKitPriceTag/blob/master/MIT-LICENSE.txt
//
//  Fork this file and insert an appropriate Managed Object Context (or other
//  such) implementation to record customer purchases.

#import "TBYBStoreButton.h"

@implementation TBYBStoreButton

@synthesize price, prodIdent;

- (void)dealloc
{
	if (storeObs != nil)
		[storeObs release];
	[currentDisplayedPrice release];
	if (spinner != nil)
		[spinner release];
	[price release];
	[prodIdent release];
	[super dealloc];
}

/* I N I T  W I T H  M O C
 * MOC = Managed Object Context (see Apple's CoreData documentation).
 */
- (id)initWithMoc:(NSManagedObjectContext *)moc
{
	id object = nil;
	if (self = [super initWithItems:[NSArray arrayWithObject: @"          "]])
	{
		storeObs = [[CjbStoreObserver alloc] initWithMoc: moc];
		[storeObs setButtonObj: self];
		status = 0;
		currentDisplayedPrice = [[NSString alloc] initWithString:@" "];

		object = self;
	}
	
	return object;
}


- (void)didMoveToSuperview
{
	[super didMoveToSuperview];
	if (self.superview != nil)
	{
		//NSLog(@"TBYBStoreButton: moving to superview (%@).", self.superview);
		spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		CGRect tempFrame = spinner.frame;
		tempFrame.origin.x = 22.5f;
		tempFrame.origin.y = 4.0f;
		spinner.frame = tempFrame;
		self.momentary = YES;
		self.segmentedControlStyle = UISegmentedControlStyleBar;
		self.tintColor = [UIColor colorWithRed:0.286f green:0.4f blue:0.616f alpha:1.0f];
		price = [[NSString alloc] initWithString:@" "];
		prodIdent = [[NSString alloc] initWithString:@" "];
		[storeObs performSelector:@selector(requestSaleSlip) withObject:nil afterDelay:5.0];
		[self spin: YES];
		[self addTarget:self action:@selector(btnAction) forControlEvents:UIControlEventValueChanged];
	}
	else
	{
		//NSLog(@"TBYBStoreButton: superview == nil.");
		[self removeTarget:self action:@selector(btnAction) forControlEvents:UIControlEventValueChanged];
		[storeObs setButtonObj: nil];
		[storeObs release];
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
		price = @" ";
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
	//NSLog(@"TBYBStoreButton(%@):\nentering `getPrice:`.", self);
	[self btnAction];
	[storeObs performSelector:@selector(requestSaleSlip) withObject:nil afterDelay:3600.0];
}

- (void)btnAction
{	
	//NSLog(@"TBYBStoreButton(%@):\ncalling btnAction.", self);
	if ([price isEqualToString:@" "])
	{
		//NSLog(@"TBYBStoreButton(%@):\nPrice == nil!", self);
		[storeObs requestSaleSlip];
		return;
	}
	
	if (status == 0) // replace current btn content with the price.
	{
		//NSLog(@"TBYBStoreButton(%@):\nreplacing current btn content with the price and changing to status = 1.", self);
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
			//NSLog(@"TBYBStoreButton (%@):\ngetting a fresh price.", self);
			currentDisplayedPrice = [NSString stringWithString: price];
			[storeObs requestSaleSlip];
			[self spin: YES];
		}
		else if (![price isEqualToString: currentDisplayedPrice])
		{
			//NSLog(@"TBYBStoreButton: currently displayed price is stale; changing to status = 0");
			[self spin: NO];
			[self setTitle: price forSegmentAtIndex: 0];
			currentDisplayedPrice = @" ";
			status = 0;
		}
		else // the updated price is the same as what is displayed -- good!
		{
			currentDisplayedPrice = @" ";
			[self setTitle: @"BUY" forSegmentAtIndex: 0]; // TODO: internationalize (localize) "BUY".
			self.tintColor = [UIColor colorWithRed:0.49f green:0.737f blue:0.392f alpha:1.0f];
			//NSLog(@"TBYBStoreButton: Adding BUY target to button.");
			[self removeTarget:self action:_cmd forControlEvents:UIControlEventValueChanged];
			[self addTarget:self action:@selector(doSomething) forControlEvents:UIControlEventValueChanged];
			// The button now reads "BUY"; if the user ignores it for some time, reset to the price. //
			[self performSelector:_cmd withObject:nil afterDelay:30.0];
			//NSLog(@"TBYBStoreButton: Changing to status = 2.");
			status = 2;
		}
		[[NSNotificationCenter defaultCenter] postNotificationName:@"TBYB1stPush" object:nil];
	}
	else if (status == 2) // revert to status == 0;
	{
		//NSLog(@"TBYBStoreButton: Reverting to status = 0.");
		[self removeTarget:self action:@selector(doSomething) forControlEvents:UIControlEventValueChanged];
		[self addTarget:self action:_cmd forControlEvents:UIControlEventValueChanged];
		status = 0;
		[self performSelector:_cmd]; // re-run this method with the new status.
	}
}

- (void)doSomething
{
	//NSLog(@"TBYBStoreButton: User's purchase request (%@) will be sent to Apple.", prodIdent);
	SKPayment *payment = [SKPayment paymentWithProductIdentifier:prodIdent];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}
@end
