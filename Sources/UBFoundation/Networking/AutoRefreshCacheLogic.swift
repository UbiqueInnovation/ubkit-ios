//
//  AutoRefreshCacheLogic.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 28.05.19.
//

import Foundation
import OSLog

@available(iOS 14.0, watchOS 7.0, *)
private struct Log {
    static let logger = Logger(subsystem: "UBKit", category: "AutoRefreshCacheLogic")
}

/// A caching logic that will launch and refresh the data automatically when the data expires
open class UBAutoRefreshCacheLogic: UBBaseCachingLogic {
    /// The refresh cron jobs
    private let refreshJobs = NSMapTable<UBURLDataTask, UBCronJob>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    private let refreshJobsAccess = DispatchQueue(label: "refresh-jobs", qos: .default)

    /// Cancels a cron job for a given data task
    private func cancelRefreshCronJob(for task: UBURLDataTask) {
        refreshJobsAccess.sync {
            refreshJobs.removeObject(forKey: task)
        }
    }

    /// Schedule a refresh cron job
    private func scheduleRefreshCronJob(for task: UBURLDataTask, headers: [AnyHashable: Any], metrics: URLSessionTaskMetrics?, referenceDate: Date?) {
        cancelRefreshCronJob(for: task)

        guard let nextRefreshDate = cachedResponseNextRefreshDate(headers, metrics: metrics, referenceDate: referenceDate) else {
            if #available(iOS 14.0, watchOS 7.0, *) {
                Log.logger.trace("No refresh date for task \(task)")
            }
            return
        }

        if #available(iOS 14.0, watchOS 7.0, *) {
            Log.logger.trace("Schedule refresh for \(task) at \(nextRefreshDate) (\(round(nextRefreshDate.timeIntervalSinceNow))s)")
        }

        // Schedule a new job
        let job = UBCronJob(fireAt: nextRefreshDate, qos: qos) { [weak task] in
            if #available(iOS 14.0, watchOS 7.0, *) {
                if let task {
                    Log.logger.trace("Start cron refresh for task \(task)")
                } else {
                    Log.logger.trace("Not start cron refresh, task doesn't exist anymore.")
                }
            }
            task?.start(flags: [.systemTriggered, .refresh])
        }
        refreshJobsAccess.sync {
            refreshJobs.setObject(job, forKey: task)
        }
    }

    /// Computes the next refresh date for a given header fields.
    ///
    /// - Parameter allHeaderFields: The header fiealds.
    /// - Returns: The next refresh date. `nil` if no next refresh date is available
    open func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any], metrics: URLSessionTaskMetrics?, referenceDate: Date?) -> Date? {
        guard let responseDateHeader = allHeaderFields.getCaseInsensitiveValue(key: dateHeaderFieldName) as? String, var responseDate = dateFormatter.date(from: responseDateHeader) else {
            // If we cannot find a date in the response header then we cannot comput the next refresh date
            return nil
        }
        guard let nextRefreshDateHeader = allHeaderFields.getCaseInsensitiveValue(key: nextRefreshHeaderFieldName) as? String, let nextRefreshDate = dateFormatter.date(from: nextRefreshDateHeader) else {
            // If we cannot find the next refresh header then we return nil
            return nil
        }

        // This is the date that we are not allowed to make requests before.
        let backoffInterval: TimeInterval = if let backoffHeader = allHeaderFields.getCaseInsensitiveValue(key: backoffIntervalHeaderFieldName) as? String, let interval = TimeInterval(backoffHeader) {
            interval
        } else {
            60
        }

        let age: TimeInterval = if let ageHeader = allHeaderFields.getCaseInsensitiveValue(key: ageHeaderFieldName) as? String, let interval = TimeInterval(ageHeader) {
            interval
        } else {
            0
        }
        responseDate = referenceDate ?? responseDate + age

        // The backoff date is the response date added to the backoff interval
        let backoffDate: Date = if let metrics, let date = metrics.transactionMetrics.last?.connectEndDate {
            max(responseDate + backoffInterval, date + backoffInterval)
        } else {
            responseDate + backoffInterval
        }

        // Return the date that is the most in the future.
        return max(nextRefreshDate, backoffDate)
    }

    /// :nodoc:
    override open func proposeCachedResponse(for session: URLSession, dataTask: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?, error: Error?) -> CachedURLResponse? {
        // Get the super cached response
        let cachedURLResponse = super.proposeCachedResponse(for: session, dataTask: dataTask, ubDataTask: ubDataTask, request: request, response: response, data: data, metrics: metrics, error: error)

        // Return the super proposed cache
        return cachedURLResponse
    }

    /// :nodoc:

    override public func hasProposedCachedResponse(cachedURLResponse: CachedURLResponse?, response: HTTPURLResponse, session _: URLSession, request _: URLRequest, ubDataTask: UBURLDataTask, metrics: URLSessionTaskMetrics?) {
        if cachedURLResponse != nil ||
            response == UBStandardHTTPCode.notModified {
            // If there is a response or the response is not modified, reschedule the cron job
            let referenceDate = ubDataTask.flags.contains(.refresh) ? Date() : nil
            scheduleRefreshCronJob(for: ubDataTask, headers: response.allHeaderFields, metrics: metrics, referenceDate: referenceDate)
        } else {
            // Otherwise cancel any current cron jobs
            cancelRefreshCronJob(for: ubDataTask)
        }
    }

    /// :nodoc:

    override public func hasMissedCache(dataTask: UBURLDataTask) {
        // If we have a miss in the cache then we cancel any cron jobs
        cancelRefreshCronJob(for: dataTask)
    }

    /// :nodoc:

    override public func hasUsed(cachedResponse: HTTPURLResponse, nonModifiedResponse: HTTPURLResponse?, metrics: URLSessionTaskMetrics?, request _: URLRequest, dataTask: UBURLDataTask) {
        let referenceDate = dataTask.flags.contains(.refresh) ? Date() : nil
        scheduleRefreshCronJob(for: dataTask, headers: (nonModifiedResponse ?? cachedResponse).allHeaderFields, metrics: metrics, referenceDate: referenceDate)
    }
}
