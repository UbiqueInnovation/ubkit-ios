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
    private func scheduleRefreshCronJob(for task: UBURLDataTask, headers: [AnyHashable: Any]) {
        cancelRefreshCronJob(for: task)

        guard let nextRefreshDate = cachedResponseNextRefreshDate(headers) else {
            return
        }
        // Schedule a new job
        let job = UBCronJob(fireAt: nextRefreshDate, qos: qos) { [weak task] in
            task?.start()
        }
        refreshJobs.setObject(job, forKey: task)
    }

    /// Computes the next refresh date for a given header fields.
    ///
    /// - Parameter allHeaderFields: The header fiealds.
    /// - Returns: The next refresh date. `nil` if no next refresh date is available
    open func cachedResponseNextRefreshDate(_ allHeaderFields: [AnyHashable: Any]) -> Date? {
        guard let responseDateHeader = allHeaderFields[dateHeaderFieldName] as? String, let responseDate = dateFormatter.date(from: responseDateHeader) else {
            // If we cannot find a date in the response header then we cannot comput the next refresh date
            return nil
        }
        guard let nextRefreshDateHeader = allHeaderFields[nextRefreshHeaderFieldName] as? String, let nextRefreshDate = dateFormatter.date(from: nextRefreshDateHeader) else {
            // If we cannot find the next refresh header then we return nil
            return nil
        }

        // This is the date that we are not allowed to make requests before.
        let backoffDate: Date
        if let backoffHeader = allHeaderFields[backoffIntervalHeaderFieldName] as? String, let backoffInterval = TimeInterval(backoffHeader) {
            // The backoff date is the response date added to the backoff interval
            backoffDate = responseDate + backoffInterval
        } else {
            // If none is specified then we can assume it is always allowed to make requests
            backoffDate = Date(timeIntervalSinceNow: 60)
        }

        // Return the date that is the most in the future.
        return max(nextRefreshDate, backoffDate)
    }

    /// :nodoc:
    open override func proposeCachedResponse(for session: URLSession, dataTask: URLSessionDataTask, ubDataTask: UBURLDataTask, request: URLRequest, response: HTTPURLResponse, data: Data?, metrics: URLSessionTaskMetrics?) -> CachedURLResponse? {
        guard let cacheControlHeader = response.allHeaderFields[cacheControlHeaderFieldName] as? String, let cacheControlDirectives = UBCacheResponseDirectives(cacheControlHeader: cacheControlHeader), cacheControlDirectives.cachingAllowed else {
            return nil
        }

        // Get the super cached response
        let cachedURLResponse = super.proposeCachedResponse(for: session, dataTask: dataTask, ubDataTask: ubDataTask, request: request, response: response, data: data, metrics: metrics)

        if cachedURLResponse != nil ||
            response == UBStandardHTTPCode.notModified {
            // If there is a response or the response is not modified, reschedule the cron job
            scheduleRefreshCronJob(for: ubDataTask, headers: response.allHeaderFields)
        } else {
            // Otherwise cancel any current cron jobs
            cancelRefreshCronJob(for: ubDataTask)
        }

        // Return the super proposed cache
        return cachedURLResponse
    }

    /// :nodoc:
    open override func cachedResponse(_ session: URLSession, request: URLRequest, dataTask: UBURLDataTask) -> UBCacheResult {
        let cachedResult = super.cachedResponse(session, request: request, dataTask: dataTask)
        switch cachedResult {
        case .miss:
            // If we have a miss in the cache then we cancel any cron jobs
            cancelRefreshCronJob(for: dataTask)
		case let .expired(cachedResponse: cachedResponse, reloadHeaders: _, metrics: _),
             let .hit(cachedResponse: cachedResponse, reloadHeaders: _, metrics: _):
            // if we hit or we found out the cron is expired, then we schedule a cron job
            guard let response = cachedResponse.response as? HTTPURLResponse else {
                // Cancel cron jobs if the response is not HTTP
                cancelRefreshCronJob(for: dataTask)
                break
            }
            scheduleRefreshCronJob(for: dataTask, headers: response.allHeaderFields)
        }

        // Return the super cache result
        return cachedResult
    }
}
