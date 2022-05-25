//
//  SwiftUIView.swift
//  
//
//  Created by Nicolas Märki on 22.05.22.
//

#if canImport(SwiftUI) && (!os(iOS) || arch(arm64))

import SwiftUI
import UBFoundation


@available(iOS 13.0, *)
@propertyWrapper
public struct UBTaskLoader<T>: DynamicProperty {

    public enum LoadingState {
        case idle
        case loading
        case success(T)
        case failure(UBNetworkingError)
        case reloading(T)
        case reloadFailure(T, UBNetworkingError)

        var value: T? {
            switch self {
                case .success(let t): return t
                case .reloading(let t): return t
                case .reloadFailure(let t, _): return t
                default: return nil
            }
        }

        var error: UBNetworkingError? {
            switch self {
                case .failure(let e): return e
                case .reloadFailure(_, let e): return e
                default: return nil
            }
        }
    }

    let decoder: UBURLDataTaskDecoder<T>
    let errorDecoder: UBURLDataTaskDecoder<Error>?

    var task: UBURLDataTask? {
        didSet {
            self.loadingState = .idle
            self.setupTask(decoder: decoder, errorDecoder: errorDecoder)
        }
    }

    init(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>? = nil) {
        self.decoder = decoder
        self.errorDecoder = errorDecoder
    }

    init(_ task: UBURLDataTask, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>? = nil) {
        self.init(decoder: decoder, errorDecoder: errorDecoder)
        defer {
            self.task = task
        }
    }

    init(_ request: UBURLRequest, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>? = nil) {
        self.init(UBURLDataTask(request: request), decoder: decoder, errorDecoder: errorDecoder)
    }

    init(_ url: URL, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>? = nil) {
        self.init(UBURLRequest(url: url), decoder: decoder, errorDecoder: errorDecoder)
    }



    private func setupTask(decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>?) {
        guard let task = self.task else {
            return
        }
        task.addStateTransitionObserver { _, to, _ in
            if to == .fetching {
                if let t = self.loadingState.value {
                    self.loadingState = .reloading(t)
                }
                else {
                    self.loadingState = .loading
                }
            }
        }
        task.addCompletionHandler(decoder: decoder, errorDecoder: errorDecoder) { res, info ,b,c  in
            switch (loadingState.value, res) {
                case (_, .success(let t)):
                    loadingState = .success(t)
                case (.some(let previous), .failure(let e)):
                    loadingState = .reloadFailure(previous, e)
                case (nil, .failure(let e)):
                    loadingState = .failure(e)
            }
        }

        task.start()
    }

    @State var loadingState: LoadingState = .loading

    public var wrappedValue: LoadingState {
        loadingState
    }

}


@available(iOS 15.0, *)
public extension View {
    func dataTask<T>(_ request: UBURLRequest, prepare: ((inout UBURLDataTask)->Void)? = nil, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>? = nil, update: @escaping (Result<T, UBNetworkingError>)->Void) -> some View {
        self.task(id: request) {
            var task = UBURLDataTask(request: request)
            prepare?(&task)
            do {
                for try await res: (T, UBURLDataTask.MetaData) in task
                    .startCronStream(decoder: decoder, errorDecoder: errorDecoder)
                {
                    update(.success(res.0))
                }
            }
            catch {
                if let error = error as? UBNetworkingError {
                    update(.failure(error))
                }
            }
        }
    }

    func dataTask<T>(_ url: URL, prepare: ((inout UBURLDataTask)->Void)? = nil, decoder: UBURLDataTaskDecoder<T>, errorDecoder: UBURLDataTaskDecoder<Error>? = nil, update: @escaping (Result<T, UBNetworkingError>)->Void) -> some View {
        self.dataTask(UBURLRequest(url: url), prepare: prepare, decoder: decoder, errorDecoder: errorDecoder, update: update)
    }

}

@available(iOS 13.0, *)
struct UBDataTaskView: View {

    @UBTaskLoader(
        URL(string: "https://www.ubique.ch")!,
        decoder: .string)
    var loader

    var body: some View {
        Text(loader.value ?? "")
    }
}

@available(iOS 13.0, *)
struct LoadingView: View {

    @UBTaskLoader(
        URL(string: "https://www.ubique.ch")!,
        decoder: .string)
    var loader

    var body: some View {
        Text(loader.value ?? "")
    }
}

@available(iOS 15.0.0, *)
struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingView()

            EmptyView()
                .dataTask(UBURLRequest(url: URL(string: "https://www.ubique.ch")!), decoder: .string) { result in
                    print(result)
                }
        }
    }
}

#endif
