//
//	Copyright 2011 James Addyman (JamSoft). All rights reserved.
//	
//	Redistribution and use in source and binary forms, with or without modification, are
//	permitted provided that the following conditions are met:
//	
//		1. Redistributions of source code must retain the above copyright notice, this list of
//			conditions and the following disclaimer.
//
//		2. Redistributions in binary form must reproduce the above copyright notice, this list
//			of conditions and the following disclaimer in the documentation and/or other materials
//			provided with the distribution.
//
//	THIS SOFTWARE IS PROVIDED BY JAMES ADDYMAN (JAMSOFT) ``AS IS'' AND ANY EXPRESS OR IMPLIED
//	WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
//	FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL JAMES ADDYMAN (JAMSOFT) OR
//	CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//	CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
//	SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
//	ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//	NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//	The views and conclusions contained in the software and documentation are those of the
//	authors and should not be interpreted as representing official policies, either expressed
//	or implied, of James Addyman (JamSoft).
//

#import "JSTokenField.h"
#import "JSTokenButton.h"
#import <QuartzCore/QuartzCore.h>

NSString *const JSTokenFieldFrameDidChangeNotification = @"JSTokenFieldFrameDidChangeNotification";
NSString *const JSTokenFieldFrameKey = @"JSTokenFieldFrameKey";
NSString *const JSDeletedTokenKey = @"JSDeletedTokenKey";

#define HEIGHT_PADDING 6
#define WIDTH_PADDING 3

#define DEFAULT_HEIGHT 31

@interface JSTokenField ()
- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj;
- (void)deleteHighlightedToken;
@property (nonatomic, readwrite, assign) UIButton *addButton;
@end


@implementation JSTokenField

@synthesize contentInset = _contentInset;
@synthesize tokens = _tokens;
@synthesize textField = _textField;
@synthesize label = _label;
@synthesize addButton = _addButton;
@synthesize delegate = _delegate;
@synthesize editMode = _editMode;

- (id)initWithFrame:(CGRect)frame
{
	if (frame.size.height < DEFAULT_HEIGHT)
	{
		frame.size.height = DEFAULT_HEIGHT;
	}
	
    if ((self = [super initWithFrame:frame]))
	{
        _editMode = YES;
        
//		[self setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
//		UIView *separator = [[[UIView alloc] initWithFrame:CGRectMake(0, frame.size.height-1, frame.size.width, 1)] autorelease];
//		[separator setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin];
//		[self addSubview:separator];
//		[separator setBackgroundColor:[UIColor lightGrayColor]];
		
		_label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, frame.size.height)];
        _label.textColor = [UIColor lightGrayColor];
		[_label setBackgroundColor:[UIColor clearColor]];
		
		[self addSubview:_label];
		
//		self.layer.borderColor = [[UIColor blueColor] CGColor];
//		self.layer.borderWidth = 1.0;
		
		_tokens = [[NSMutableArray alloc] init];
		
		_hiddenTextField = [[UITextField alloc] initWithFrame:CGRectMake(0, 0 , DEFAULT_HEIGHT, DEFAULT_HEIGHT)];
		[_hiddenTextField setHidden:YES];
		[_hiddenTextField setDelegate:self];
		[self addSubview:_hiddenTextField];
		[_hiddenTextField setText:@" "];
		
		frame.origin.y += HEIGHT_PADDING;
		frame.size.height -= HEIGHT_PADDING;
		_textField = [[UITextField alloc] initWithFrame:frame];
		[_textField setDelegate:self];
		[_textField setBorderStyle:UITextBorderStyleNone];
		[_textField setBackground:nil];
		[_textField setBackgroundColor:[UIColor clearColor]];
        
		
//		[_textField.layer setBorderColor:[[UIColor redColor] CGColor]];
//		[_textField.layer setBorderWidth:1.0];
		
		[_textField setText:@" "];
		
		[self addSubview:_textField];
		
        _addButton = [UIButton buttonWithType:UIButtonTypeContactAdd];
        [self addSubview:_addButton];
        
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleTextDidChange:)
													 name:UITextFieldTextDidChangeNotification
												   object:_textField];
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(handleTextDidChange:)
													 name:UITextFieldTextDidChangeNotification
												   object:_hiddenTextField];
    }
	
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[_hiddenTextField release], _hiddenTextField = nil;
	[_textField release], _textField = nil;
	[_label release], _label = nil;
	[_tokens release], _tokens = nil;
	
	[super dealloc];
}


- (void)addTokenWithTitle:(NSString *)string representedObject:(id)obj
{
	NSString *aString = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
	NSMutableString *recipient = [NSMutableString string];
	
	NSMutableCharacterSet *charSet = [[[NSCharacterSet whitespaceCharacterSet] mutableCopy] autorelease];
	[charSet formUnionWithCharacterSet:[NSCharacterSet punctuationCharacterSet]];
	
	for (int i = 0; i < [(NSString *)obj length]; i++)
	{
		if (![charSet characterIsMember:[(NSString *)obj characterAtIndex:i]])
		{
			[recipient appendFormat:@"%@",[NSString stringWithFormat:@"%c", [(NSString *)obj characterAtIndex:i]]];
		}
	}
	
	if ([aString length])
	{
		JSTokenButton *token = [self tokenWithString:aString representedObject:recipient];
		[_tokens addObject:token];
		
		if ([self.delegate respondsToSelector:@selector(tokenField:didAddToken:representedObject:)])
		{
			[self.delegate tokenField:self didAddToken:aString representedObject:recipient];
		}
		
		[self setNeedsLayout];
	}
}

- (void)removeTokenForString:(NSString *)string
{
	for (int i = 0; i < [_tokens count]; i++)
	{
		JSTokenButton *token = [_tokens objectAtIndex:i];
		if ([[token titleForState:UIControlStateNormal] isEqualToString:string])
		{
			[token removeFromSuperview];
			[[token retain] autorelease]; // removing it from the array will dealloc the object, but we want to keep it around for the delegate method below
			[_tokens removeObject:token];
			if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveTokenAtIndex:)])
			{
				[self.delegate tokenField:self didRemoveTokenAtIndex:i];
			}
		}
	}
	
	[self setNeedsLayout];
}

- (void)deleteHighlightedToken
{
	for (int i = 0; i < [_tokens count]; i++)
	{
		_deletedToken = [[_tokens objectAtIndex:i] retain];
		if ([_deletedToken isToggled])
		{
			[_deletedToken removeFromSuperview];
			[_tokens removeObject:_deletedToken];
			
			if ([self.delegate respondsToSelector:@selector(tokenField:didRemoveTokenAtIndex:)])
			{
				[self.delegate tokenField:self didRemoveTokenAtIndex:i];
			}
			
			[self setNeedsLayout];	
		}
	}
}

- (JSTokenButton *)tokenWithString:(NSString *)string representedObject:(id)obj
{
	JSTokenButton *token = [JSTokenButton tokenWithString:string representedObject:obj];
	CGRect frame = [token frame];
	
	if (frame.size.width > self.frame.size.width)
	{
		frame.size.width = self.frame.size.width - (WIDTH_PADDING * 2);
	}
	
	[token setFrame:frame];
	
	[token addTarget:self
			  action:@selector(toggle:)
	forControlEvents:UIControlEventTouchUpInside];
	
	return token;
}

- (void)layoutSubviews
{
	CGRect currentRect = CGRectZero;
	
	[_label sizeToFit];
	[_label setFrame:CGRectMake(self.contentInset.left,
                                self.contentInset.top,
                                [_label frame].size.width,
                                [_label frame].size.height)];
	
	currentRect.origin.x += _label.frame.size.width + _label.frame.origin.x + WIDTH_PADDING;
	currentRect.origin.y = self.contentInset.top;
    
    if (_editMode) {
        for (UIButton *token in _tokens) {
            
            token.hidden = NO;
            [token sizeToFit];
            CGRect frame = [token frame];
            
            if ((currentRect.origin.x + frame.size.width) > self.frame.size.width)
            {
                currentRect.origin = CGPointMake(self.contentInset.left,
                                                 (currentRect.origin.y + frame.size.height + HEIGHT_PADDING));
            }
            
            frame.origin = currentRect.origin;
            
            [token setFrame:frame];
            
            if (![token superview])
            {
                [self addSubview:token];
            }
            
            currentRect.origin.x += frame.size.width + WIDTH_PADDING;
            currentRect.size = frame.size;
        }
    } else {
        NSMutableArray *tokenLabels = [NSMutableArray array];
        for (UIButton *token in _tokens) {
            token.hidden = YES;
            [tokenLabels addObject:[token titleForState:UIControlStateNormal]];
        }
        _textField.text = [tokenLabels componentsJoinedByString:@", "];
    }
	
	
	CGRect textFieldFrame = [_textField frame];
	
	textFieldFrame.origin = currentRect.origin;
    
    [self.addButton sizeToFit];
    
	if ((self.frame.size.width - textFieldFrame.origin.x - CGRectGetWidth(self.addButton.frame) - WIDTH_PADDING) >= 60) {
		textFieldFrame.size.width = self.bounds.size.width - textFieldFrame.origin.x - WIDTH_PADDING - CGRectGetWidth(self.addButton.frame) - self.contentInset.right;
	} else {
		textFieldFrame.size.width = self.bounds.size.width - self.contentInset.left - WIDTH_PADDING - CGRectGetWidth(self.addButton.frame) - self.contentInset.right;
		textFieldFrame.origin = CGPointMake(self.contentInset.left,
                                            (currentRect.origin.y + currentRect.size.height + HEIGHT_PADDING));
	}
	
	[_textField setFrame:textFieldFrame];
    
    CGRect buttonFrame = self.addButton.frame;
    buttonFrame.origin.x = textFieldFrame.origin.x + textFieldFrame.size.width + WIDTH_PADDING;
    buttonFrame.origin.y = textFieldFrame.origin.y;
    self.addButton.frame = buttonFrame;
    
	CGRect selfFrame = [self frame];
	selfFrame.size.height = buttonFrame.origin.y + buttonFrame.size.height + self.contentInset.bottom;
	
    if ([self.delegate respondsToSelector:@selector(tokenFieldFrameWillChange:)]) {
        [self.delegate tokenFieldFrameWillChange:self];
    }
    
    [self setFrame:selfFrame];
    
    
    if ([self.delegate respondsToSelector:@selector(tokenField:frameDidChange:)]) {
        [self.delegate tokenField:self frameDidChange:self.frame];
    }
}

- (void)toggle:(id)sender
{
	for (JSTokenButton *token in _tokens)
	{
		[token setToggled:NO];
	}
	
	JSTokenButton *token = (JSTokenButton *)sender;
	[token setToggled:YES];
	[_hiddenTextField becomeFirstResponder];
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
	
	NSMutableDictionary *userInfo = [NSMutableDictionary dictionaryWithObject:[NSValue valueWithCGRect:frame] forKey:JSTokenFieldFrameKey];
	if (_deletedToken)
	{
		[userInfo setObject:_deletedToken forKey:JSDeletedTokenKey]; 
		[_deletedToken release], _deletedToken = nil;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:JSTokenFieldFrameDidChangeNotification object:self userInfo:[[userInfo copy] autorelease]];
}

- (void)setEditMode:(BOOL)value;
{
    if (_editMode != value) {
        _editMode = value;
        
        if (_editMode) {
            [_textField becomeFirstResponder];
            if ([self.delegate respondsToSelector:@selector(tokenFieldDidBeginEditing:)]) {
                [self.delegate tokenFieldDidBeginEditing:self];
            }
        } else {
            [_hiddenTextField becomeFirstResponder];
            if ([self.delegate respondsToSelector:@selector(tokenFieldDidEndEditing:)]) {
                [self.delegate tokenFieldDidEndEditing:self];
            }
        }
        
        [self setNeedsLayout];
    }
}

#pragma mark -
#pragma mark UITextFieldDelegate

- (void)handleTextDidChange:(NSNotification *)note
{
	// ensure there's always a space at the beginning
	NSMutableString *text = [[[_textField text] mutableCopy] autorelease];
	if (![text hasPrefix:@" "])
	{
		[text insertString:@" " atIndex:0];
		[_textField setText:text];
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
	if ([[textField text] isEqualToString:@" "] && [string isEqualToString:@""])
	{
		for (JSTokenButton *token in _tokens)
		{
			if ([token isToggled])
			{
				[self deleteHighlightedToken];
				[_textField becomeFirstResponder];
				return NO;
			}
		}
		
		if ([_tokens count] > 0)
		{
			if ([[_tokens lastObject] isToggled] == NO)
			{
				[[_tokens lastObject] setToggled:YES];
				[_hiddenTextField becomeFirstResponder];
				return NO;
			}
		}
		
		[self deleteHighlightedToken];
		[_textField becomeFirstResponder];
		return NO;
	}
	else if (textField == _hiddenTextField)
		return NO;
	else
	{
		if ([_tokens count] > 0)
		{
			if ([[_tokens lastObject] isHighlighted] == YES)
			{
				[[_tokens lastObject] setHighlighted:NO];
			}
		}
	}
	
	// if attempting to enter text before the intial space, disallow it, and move cursor to the end (all we can do)
	if (range.location == 0 && range.length == 0)
	{
		[_textField setText:[_textField text]];
		return NO;
	}
	
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
	if ([[textField text] length])
	{
		[self addTokenWithTitle:[textField text] representedObject:[textField text]];
		
		if (textField == _textField)
			[textField setText:nil];
	}
	
	return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField;
{
    if (textField == _textField) {
        textField.text = @"";
        [self setEditMode:YES];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
	if (textField == _textField) {
		if ([[textField text] length] > 1)
		{
			[self addTokenWithTitle:[textField text] representedObject:[textField text]];
			[textField setText:@" "];
		}
	} else if (textField == _hiddenTextField) {
		for (JSTokenButton *token in _tokens)
		{
			[token setToggled:NO];
		}
	}
}

@end
