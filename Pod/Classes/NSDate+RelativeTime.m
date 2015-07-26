//
//  NSDate+RelativeTime.m
//  SBCategories
//
//  Created by Elliot Schrock on 10/2/14.
//  Copyright (c) 2014 Elliot. All rights reserved.
//

#import "NSDate+RelativeTime.h"

@implementation NSDate (RelativeTime)

- (BOOL)isBefore:(NSDate *)date
{
    return [self compare:date] == NSOrderedAscending;
}

- (BOOL)isAfter:(NSDate *)date
{
    return [self compare:date] == NSOrderedDescending;
}

- (NSDate *)incrementUnit:(NSCalendarUnit)unit by:(int)increment
{
    NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
    [calendar setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en-US"]];
    
    NSDateComponents *components = [[NSDateComponents alloc] init];
    
    switch (unit) {
        case NSCalendarUnitYear:
            [components setYear:increment];
            break;
        case NSCalendarUnitWeekOfYear:
            [components setWeekOfYear:increment];
            break;
        case NSCalendarUnitMonth:
            [components setMonth:increment];
            break;
        case NSCalendarUnitDay:
            [components setDay:increment];
            break;
        case NSCalendarUnitHour:
            [components setHour:increment];
            break;
        case NSCalendarUnitMinute:
            [components setMinute:increment];
            break;
        case NSCalendarUnitSecond:
            [components setSecond:increment];
            break;
        case NSCalendarUnitEra:
            [components setEra:increment];
            break;
        case NSCalendarUnitQuarter:
            [components setQuarter:increment];
            break;
        case NSCalendarUnitWeekdayOrdinal:
            [components setWeekdayOrdinal:increment];
            break;
        case NSCalendarUnitYearForWeekOfYear:
            [components setYearForWeekOfYear:increment];
            break;
        case NSCalendarUnitWeekday:
            [components setWeekday:increment];
            break;
        case NSCalendarUnitWeekOfMonth:
            [components setWeekOfMonth:increment];
            break;
    }
    
    return [calendar dateByAddingComponents:components toDate:self options:0];
}

@end
