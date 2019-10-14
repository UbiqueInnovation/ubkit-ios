//
//  Date+UBHelpers.swift
//  UBFoundation iOS
//
//  Created by Marco Zimmermann on 23.09.19.
//

import UIKit

// MARK: - Date Helpers
extension Date
{
    /// Returns a date from a string in the format of dateFormat with optional timeZone and locale
    public func ub_dateString(with dateFormat: String, timeZone: TimeZone? = nil, locale: Locale? = nil) -> String
    {
        return Date.ub_formatter(dateFormat: dateFormat, timeZone: timeZone, locale: locale).string(from: self)
    }

    /// Returns a date from a string in the format of dateFormat
    public static func ub_date(from string: String, with dateFormat: String) -> Date?
    {
        return Date.ub_formatter(dateFormat: dateFormat).date(from: string)
    }

    /// Returns the Date of the start of the day
    public func ub_startOfDay() -> Date?
    {
        var components = self.ub_components()

        components.hour = 0
        components.minute = 0
        components.second = 0

        return Calendar.current.date(from: components)
    }

    /// Return the Date of the start of the hour
    public func ub_startOfHour() -> Date?
    {
        var components = self.ub_components()

        components.minute = 0
        components.second = 0

        return Calendar.current.date(from: components)
    }

    /// Checks whether date is on same day as self
    public func ub_isSameDay(as date: Date) -> Bool
    {
        guard let start = self.ub_startOfDay(),
              let other = date.ub_startOfDay()
        else
        {
            return false
        }

        return start == other
    }

    /// Checks whether date is on same day, same hour as self
    public func ub_isSameHourAndDay(as date: Date) -> Bool
    {
        guard let start = self.ub_startOfHour(),
            let other = date.ub_startOfHour()
        else
        {
            return false
        }

        return start == other
    }

    /// Returns date from string in classic dayDate format
    public func ub_dateWithDayDateString(_ dateString: String) -> Date?
    {
        return Date.ub_formatter(dateFormat: "yyyy-MM-dd").date(from: dateString)
    }

    /// Returns date from string in RFC1123 format
    public func ub_dateWithRFC1123(_ dateString: String) -> Date?
    {
        let format = "EEE, dd MMM yyyy HH:mm:ss zzz"
        let timeZone : TimeZone = NSTimeZone(forSecondsFromGMT: 0) as TimeZone
        let locale : Locale = Locale(identifier: "en_US")

        return Date.ub_formatter(dateFormat: format, timeZone: timeZone, locale: locale).date(from: dateString)
    }

    /// :nodoc:
    private func ub_components() -> DateComponents
    {
        let calendar = Calendar.current

        return calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .weekOfYear, .weekday], from: self)
    }

    /// :nodoc:
    private func ub_date(from string: String, with dateFormat: String, timeZone: TimeZone, locale: Locale) -> Date?
    {
        let formatter = Date.ub_formatter(dateFormat: dateFormat, timeZone: timeZone, locale: locale)

        return formatter.date(from: string)
    }

    /// :nodoc:
    private static func ub_formatter(dateFormat: String, timeZone: TimeZone? = nil, locale: Locale? = nil) -> DateFormatter
    {
        // DateFormatter is not thread-safe, so we use a dictionary for
        // each thread that is formatting dates.
        let threadDictionary = Thread.current.threadDictionary

        var dict = threadDictionary.object(forKey: Date.ub_cachedDateFormatterDictionaryKey) as? NSMutableDictionary

        if dict == nil
        {
            dict = NSMutableDictionary()
            threadDictionary.setValue(dict, forKeyPath: Date.ub_cachedDateFormatterDictionaryKey)
        }

        let key = Date.ub_formatterKey(dateFormat: dateFormat, timeZone: timeZone, locale: locale)

        var formatter = dict?.object(forKey: key) as? DateFormatter

        if formatter == nil
        {
            formatter = DateFormatter()

            // !: always set.
            formatter!.dateFormat = dateFormat
            formatter!.timeZone = timeZone
            formatter!.locale = locale

            dict?[key] = formatter
        }

        // !: always set.
        return formatter!
    }

    /// :nodoc:
    private static func ub_formatterKey(dateFormat: String, timeZone: TimeZone? = nil, locale : Locale? = nil) -> String
    {
        var components : [String] = []
        components.append(dateFormat)

        if let tz = timeZone
        {
            components.append(tz.identifier)
        }

        if let l = locale
        {
            components.append(l.identifier)
        }

        return components.joined(separator: "|")
    }

    /// :nodoc:
    private static let ub_cachedDateFormatterDictionaryKey = "CachedDateFormatterDictionaryKey"
}
