
// D for Xcode: Comment Scanner for Xcode 3
// Copyright (C) 2008  Michel Fortin
//
// D for Xcode is free software; you can redistribute it and/or modify it 
// under the terms of the GNU General Public License as published by the Free 
// Software Foundation; either version 2 of the License, or (at your option) 
// any later version.
//
// D for Xcode is distributed in the hope that it will be useful, but WITHOUT 
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
// FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for 
// more details.
//
// You should have received a copy of the GNU General Public License
// along with D for Xcode; if not, write to the Free Software Foundation, 
// Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA.

#import "DXDCommentScanner.h"
#import "DXScannerTools.h"
#import "XCSourceModelItem.h"
#import "XCCharStream.h"
#import "XCPSupport.h"

enum Response { notoken = -1, token = 65542 };

@implementation DXDCommentScanner

- (id)parse:(id)a withContext:(id)b initialToken:(int)c inputStream:(XCCharStream *)d range:(NSRange)e dirtyRange:(NSRange *)f {
	
	NSString *str = [d stringWithRange:e];
	str = [str stringByDeletingLeadingWhitespace];
	size_t cutLength = e.length - [str length];
	
	// Skip if not a ddoc comment.
	if ([self ddocOnly]) {
		if ([str length] < 5)
			return nil;
		if ([str characterAtIndex:1] != [str characterAtIndex:2])
			return nil;
	}
	
	size_t foundCommentLength = commentLength(str);
	if (foundCommentLength) {
		e.length = foundCommentLength;

//		NSLog(@"comment -> a %@", a);
//		NSLog(@"comment -> range = %d:%d", e.location, e.length);
//		NSLog(@"comment -> dirtyRange = %d:%d", f->location, f->length);

		size_t oldLoc = [d location];

		XCSourceModelItem *r = [super parse:a withContext:b initialToken:c inputStream:d range:e dirtyRange:f];

//		NSLog(@"comment -> dirtyRange' = %d:%d", f->location, f->length);
//		NSLog(@"comment -> location = %d -> %d", oldLoc, [d location]);
//		NSLog(@"comment -> %@", r);

		return r;
	}
	return nil;
}

- (BOOL)predictsRule:(int)tokenType inputStream:(XCCharStream *)stream {
	size_t location = [stream location]-1;
	BOOL result = location < [stream length] ? [[stream string] characterAtIndex:location] == '/' : NO;
//	NSLog(@"comment -> predict rule (%d) = %d", tokenType, result);
	return result;
}

- (BOOL)ddocOnly {
	return NO;
}

- (BOOL)canTokenize {
	return YES;
}

@end

@implementation DXDDdocCommentScanner

- (BOOL)ddocOnly {
	return YES;
}

@end