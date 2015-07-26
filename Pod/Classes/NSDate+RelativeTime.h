//
//  NSDate+RelativeTime.h
//  SBCategories
//
//  Created by Elliot Schrock on 10/2/14.
//  Copyright (c) 2014 Elliot. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (RelativeTime)

- (BOOL)isBefore:(NSDate *)date;
- (BOOL)isAfter:(NSDate *)date;
- (NSDate *)incrementUnit:(NSCalendarUnit)unit by:(int)increment;
@end
