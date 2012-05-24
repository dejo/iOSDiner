//
//  IODViewController.m
//  iOSDiner
//
//  Created by Adam Burkepile on 1/29/12.
//  Copyright (c) 2012 Adam Burkepile. All rights reserved.
//

#import "IODViewController.h"
#import "IODItem.h"     // <---- #1
#import "IODOrder.h"     // <---- #1

@implementation IODViewController
@synthesize ibRemoveItemButton;
@synthesize ibAddItemButton;
@synthesize ibPreviousItemButton;
@synthesize ibNextItemButton;
@synthesize ibTotalOrderButton;
@synthesize ibChalkboardLabel;
@synthesize ibCurrentItemScrollView;
@synthesize ibCurrentItemLabel;
@synthesize inventory;     // <---- #2
@synthesize order;     // <---- #2

dispatch_queue_t queue; 
UIImageView *previousItemImageView;
UIImageView *currentItemImageView;
UIImageView *nextItemImageView;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

-(void)dealloc {
    dispatch_release(queue);
}

#pragma mark - View lifecycle

#define CURRENT_ITEM_IMAGE_WIDTH 109
#define CURRENT_ITEM_IMAGE_HEIGHT 80

- (void)viewDidLoad
{
    [super viewDidLoad];

    currentItemIndex = 0;     // <---- #3
    [self setOrder:[IODOrder new]];     // <---- #4
    
    queue = dispatch_queue_create("com.adamburkepile.queue",nil); // <======

	previousItemImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, CURRENT_ITEM_IMAGE_WIDTH, CURRENT_ITEM_IMAGE_HEIGHT)];
	currentItemImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CURRENT_ITEM_IMAGE_WIDTH, 0, CURRENT_ITEM_IMAGE_WIDTH, CURRENT_ITEM_IMAGE_HEIGHT)];
	nextItemImageView = [[UIImageView alloc] initWithFrame:CGRectMake(CURRENT_ITEM_IMAGE_WIDTH*2, 0, CURRENT_ITEM_IMAGE_WIDTH, CURRENT_ITEM_IMAGE_HEIGHT)];
	previousItemImageView.contentMode = UIViewContentModeScaleAspectFit;
	currentItemImageView.contentMode = UIViewContentModeScaleAspectFit;
	nextItemImageView.contentMode = UIViewContentModeScaleAspectFit;
	[ibCurrentItemScrollView addSubview:previousItemImageView];
	[ibCurrentItemScrollView addSubview:currentItemImageView];
	[ibCurrentItemScrollView addSubview:nextItemImageView];
	ibCurrentItemScrollView.contentSize = CGSizeMake(CURRENT_ITEM_IMAGE_WIDTH*3, CURRENT_ITEM_IMAGE_HEIGHT);
	ibCurrentItemScrollView.contentOffset = CGPointMake(CURRENT_ITEM_IMAGE_WIDTH, 0);
}

- (void)viewDidUnload
{
    [self setIbRemoveItemButton:nil];
    [self setIbAddItemButton:nil];
    [self setIbPreviousItemButton:nil];
    [self setIbNextItemButton:nil];
    [self setIbTotalOrderButton:nil];
    [self setIbChalkboardLabel:nil];
    [self setIbCurrentItemLabel:nil];
    [self setIbCurrentItemScrollView:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self updateInventoryButtons]; // <---- Add

    [ibChalkboardLabel setText:@"Loading Inventory..."];
    
    dispatch_async(queue, ^{
        [self setInventory:[[IODItem retrieveInventoryItems] mutableCopy]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self updateOrderBoard]; // <---- Add
            [self updateInventoryButtons]; // <---- Add
            [self updateCurrentInventoryItem]; // <---- Add

            [ibChalkboardLabel setText:@"Inventory Loaded\n\nHow can I help you?"];
        });
    });}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)ibaRemoveItem:(id)sender {
    IODItem* currentItem = [[self inventory] objectAtIndex:currentItemIndex];
    
    [order removeItemFromOrder:currentItem];
    [self updateOrderBoard];
    [self updateCurrentInventoryItem];
    [self updateInventoryButtons];
    
    UILabel* removeItemDisplay = [[UILabel alloc] initWithFrame:[ibCurrentItemScrollView frame]];
    [removeItemDisplay setCenter:[ibChalkboardLabel center]];
    [removeItemDisplay setText:@"-1"];
    [removeItemDisplay setTextAlignment:UITextAlignmentCenter];
    [removeItemDisplay setTextColor:[UIColor redColor]];
    [removeItemDisplay setBackgroundColor:[UIColor clearColor]];
    [removeItemDisplay setFont:[UIFont boldSystemFontOfSize:32.0]];
    [[self view] addSubview:removeItemDisplay];
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         [removeItemDisplay setCenter:[ibCurrentItemScrollView center]];
                         [removeItemDisplay setAlpha:0.0];
                     } completion:^(BOOL finished) {
                         [removeItemDisplay removeFromSuperview];
                     }];

}

- (IBAction)ibaAddItem:(id)sender {
    IODItem* currentItem = [[self inventory] objectAtIndex:currentItemIndex];
    
    [order addItemToOrder:currentItem];
    [self updateOrderBoard];
    [self updateCurrentInventoryItem];
    [self updateInventoryButtons];
    
    UILabel* addItemDisplay = [[UILabel alloc] initWithFrame:[ibCurrentItemScrollView frame]];
    [addItemDisplay setText:@"+1"];
    [addItemDisplay setTextColor:[UIColor whiteColor]];
    [addItemDisplay setBackgroundColor:[UIColor clearColor]];
    [addItemDisplay setTextAlignment:UITextAlignmentCenter];
    [addItemDisplay setFont:[UIFont boldSystemFontOfSize:32.0]];
    [[self view] addSubview:addItemDisplay];
    
    [UIView animateWithDuration:1.0
                     animations:^{
                         [addItemDisplay setCenter:[ibChalkboardLabel center]];
                         [addItemDisplay setAlpha:0.0];
                     } completion:^(BOOL finished) {
                         [addItemDisplay removeFromSuperview];
                     }];
}

- (IBAction)ibaLoadPreviousItem:(id)sender {
    currentItemIndex--;
	[UIView animateWithDuration:0.25
					 animations:^{
						 [ibCurrentItemScrollView setContentOffset:CGPointMake(0, 0)];
					 }
					 completion:^(BOOL finished) {
						 [self updateCurrentInventoryItem];
						 [self updateInventoryButtons];
					 }
	 ];
}

- (IBAction)ibaLoadNextItem:(id)sender {
    currentItemIndex++;
	[UIView animateWithDuration:0.25
					 animations:^{
						 [ibCurrentItemScrollView setContentOffset:CGPointMake(CURRENT_ITEM_IMAGE_WIDTH*2, 0)];
					 }
					 completion:^(BOOL finished) {
						 // reload image views, via helper method
						 [self updateCurrentInventoryItem];
						 [self updateInventoryButtons];
					 }
	 ];
}

- (IBAction)ibaCalculateTotal:(id)sender {
    float total = [order totalOrder];
    
    UIAlertView* totalAlert = [[UIAlertView alloc] initWithTitle:@"Total" 
                                                         message:[NSString stringWithFormat:@"$%0.2f",total] 
                                                        delegate:nil
                                               cancelButtonTitle:@"Close" 
                                               otherButtonTitles:nil];
    [totalAlert show];
}

#pragma mark - Helper Methods

- (void)updateCurrentInventoryItem {
    if (currentItemIndex >= 0 && currentItemIndex < [[self inventory] count]) {
        IODItem* currentItem = [[self inventory] objectAtIndex:currentItemIndex];
        [ibCurrentItemLabel setText:[currentItem name]];
		currentItemImageView.image = [UIImage imageNamed:[currentItem pictureFile]];
		if (currentItemIndex > 0) {
			IODItem* previousItem = [self.inventory objectAtIndex:currentItemIndex-1];
			previousItemImageView.image = [UIImage imageNamed:[previousItem pictureFile]];
		}
		else {
			previousItemImageView.image = nil;
		}
		if (currentItemIndex < self.inventory.count-1) {
			IODItem* nextItem = [self.inventory objectAtIndex:currentItemIndex+1];
			nextItemImageView.image = [UIImage imageNamed:[nextItem pictureFile]];
		}
		else {
			nextItemImageView.image = nil;
		}
		[ibCurrentItemScrollView setContentOffset:CGPointMake(CURRENT_ITEM_IMAGE_WIDTH, 0)];
    }
}

- (void)updateInventoryButtons {
    if (![self inventory] || [[self inventory] count] == 0) {
        [ibAddItemButton setEnabled:NO];
        [ibRemoveItemButton setEnabled:NO];
        [ibNextItemButton setEnabled:NO];
        [ibPreviousItemButton setEnabled:NO];
        [ibTotalOrderButton setEnabled:NO];
    }
    else {
        if (currentItemIndex <= 0) {
            [ibPreviousItemButton setEnabled:NO];
        }
        else {
            [ibPreviousItemButton setEnabled:YES];
        }
        
        if (currentItemIndex >= [[self inventory] count]-1) {
            [ibNextItemButton setEnabled:NO];
        }
        else {
            [ibNextItemButton setEnabled:YES];
        }
        
        IODItem* currentItem = [[self inventory] objectAtIndex:currentItemIndex];
        if (currentItem) {
            [ibAddItemButton setEnabled:YES];
        }
        else {
            [ibAddItemButton setEnabled:NO];
        }
        
        if (![[self order] findKeyForOrderItem:currentItem]) {
            [ibRemoveItemButton setEnabled:NO];
        }
        else {
            [ibRemoveItemButton setEnabled:YES];
        }
        
        if ([[order orderItems] count] == 0) {
            [ibTotalOrderButton setEnabled:NO];
        }
        else {
            [ibTotalOrderButton setEnabled:YES];
        }
    }
}

- (void)updateOrderBoard {
    if ([[order orderItems] count] == 0) {
        [ibChalkboardLabel setText:@"No Items. Please order something!"];
    }
    else {
        [ibChalkboardLabel setText:[order orderDescription]];
    }
}
@end
