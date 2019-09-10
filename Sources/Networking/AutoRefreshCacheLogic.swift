//
//  AutoRefreshCacheLogic.swift
//  UBFoundation
//
//  Created by Joseph El Mallah on 28.05.19.
//

import Foundation

/// A caching logic that will launch and refresh the data automatically when the data expires
open class UBAutoRefreshCacheLogic: UBBaseCachingLogic {
    /// The refresh cron jobs
    private let refreshJobs = NSMapTable<UBURLDataTask, UBCronJob>(keyOptions: .weakMemory, valueOptions: .strongMemory)

    /// Cancels a cron job for a given data task
    private func cancelRefreshCronJob(for task: UBURLDataTask) {
        refreshJobs.removeObject(forKey: task)
    }

    /// Schedule a refresh cron job
    private func scheduleRefreshCronJob(for task: UBURLDataTask, headers: [AnyHashable: Any], metrics: URLSessionTaskMetrics?) {
        cancelRefreshCronJob(for: task)

        guard let nextRefreshDate = cachedResponseNextRefreshDate(headers, metrics: metrics) else {
            return
        }
        // Schedule a new job
        let job = UBCronJob(fireAt: nextRefreshDate, qos: qos) { [weak task] in
            task?.start(refresh: true)
        }
        refreshJobs.setObject(job, forKey: task)
    }

    /// Computes the next refresh date for a given header fields.
    ///
    /// - Parameter allHeaderFields: The header fiealds.
    /// - Returns: The next refresh date. `nil` if no next refresh date is available
    open func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any], metrics: URLSessionTaskMetrics?) -> Date? {
        guard let responseDateHeader = allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHeader) else {
            // If we cannot find a date in the response header then we cannot comput the next refresh date
            return nil
        }
        guard let nextRefreshDateHeader = allHeaderFields[nextRefreshHeaderFieldName] as? String, let nextRefreshDate = dateFormatter.date(from: nextRefreshDateHeader) else {
            // If we cannot find the next refresh header then we return nil
            return nil
        }

        // This is the date that we are not allowed to make requests before.
        let backoffInterval: TimeInterval
        if let backoffHeader = allHeaderFields[backoffIntervalHeaderFieldName] as? String, let interval = TimeInterval(backoffHeader) {
            backoffInterval = interval
        } else {
            backoffInterval = 60
        }

        // The backoff date is the response date added to the backoff interval
        let backoffDate: Date
        if let metrics = metrics, let date = metrics.transactionMetrics.last?.connectEndDate {
            backoffDate = max(responseDate + backoffInterval, date + backoffInterval)
        } else {
            backoffDate = responseDate + backoffInterval
        }

        // Return the date that is the most in the future.
        return max(nextRefreshDate, backoffDate)
    }

    /// :nodoc:
    open override func proposeCachedResponse(for session: URLSession, dataTask: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?) -> CachedURLResponse? {
        // Get the super cached response
        let cachedURLResponse = super.proposeCachedResponse(for: session, dataTask: dataTask, ubDataTask: ubDataTask, request: request, response: response, data: data, metrics: metrics)

        // Return the super proposed cache
        return cachedURLResponse
    }

    /// :nodoc:

    public override func hasProposedCachedResponse(cachedURLResponse: CachedURLResponse?, response: HTTPURLResponse, session _: URLSession, request _: URLRequest, ubDataTask: UBURLDataTask, metrics: URLSessionTaskMetrics?) {
        if cachedURLResponse != nil ||
            response == UBStandardHTTPCode.notModified {
            // If there is a response or the response is not modified, reschedule the cron job
            scheduleRefreshCronJob(for: ubDataTask, headers: response.allHeaderFields, metrics: metrics)
        } else {
            // Otherwise cancel any current cron jobs
            cancelRefreshCronJob(for: ubDataTask)
        }
    }

    /// :nodoc:

    public override func hasMissedCache(dataTask: UBURLDataTask) {
        // If we have a miss in the cache then we cancel any cron jobs
        cancelRefreshCronJob(for: dataTask)
    }

    /// :nodoc:

    public override func hasUsed(response: HTTPURLResponse, metrics: URLSessionTaskMetrics?, request _: URLRequest, dataTask: UBURLDataTask) {
        scheduleRefreshCronJob(for: dataTask, headers: response.allHeaderFields, metrics: metrics)
    }
}
