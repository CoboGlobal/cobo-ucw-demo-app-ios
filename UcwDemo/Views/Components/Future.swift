//
//  Future.swift
//  UcwDemo
//
//  Created by Yang.Bai on 2024/9/27.
//

import Combine
import Foundation

// extension Future {
//    convenience init(asyncFunc: @escaping () async throws -> Output,
//                     mapError: @escaping (Error) -> Failure) {
//        self.init { promise in
//            Task {
//                do {
//                    let result = try await asyncFunc()
//                    promise(.success(result))
//                } catch {
//                    promise(.failure(mapError(error)))
//                }
//            }
//        }
//    }
// }

extension Future {
    convenience init(
        asyncFunc: @escaping () async throws -> Output,
        mapError: @escaping (Error) -> Failure = { error in
            error as! Failure
        }
    ) {
        self.init { promise in
            Task {
                do {
                    let result = try await asyncFunc()
                    promise(.success(result))
                } catch {
                    promise(.failure(mapError(error)))
                }
            }
        }
    }
}

extension Future where Failure == Never {
    convenience init(asyncFunc: @escaping () async -> Output) {
        self.init { promise in
            Task {
                let result = await asyncFunc()
                promise(.success(result))
            }
        }
    }
}

class PollingManager {
    private var cancellables = Set<AnyCancellable>()
    private var isPolling = false
    private var currentPollingCancellable: AnyCancellable?

    enum PollingError: Error {
        case maxAttemptsReached
    }

    func poll<T, E: Error>(
        interval: TimeInterval,
        maxAttempts: Int? = nil,
        shouldContinue: @escaping (T) -> Bool,
        operation: @escaping () -> Future<T, E>
    ) -> AnyPublisher<T, E> {
        var attempts = 0
        let subject = PassthroughSubject<T, E>()
        let initialOperation = operation()
                .handleEvents(receiveOutput: { value in
                    subject.send(value)
                    attempts += 1
                })
                .eraseToAnyPublisher()
        let timerPublisher = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .setFailureType(to: E.self)
            .flatMap { _ -> AnyPublisher<T, E> in
                attempts += 1
                if maxAttempts == -1 || maxAttempts == nil || attempts <= maxAttempts! {
                    return operation()
                       .handleEvents(receiveOutput: { value in
                           subject.send(value)
                       })
                       .eraseToAnyPublisher()
                } else {
                    return Fail(error: PollingError.maxAttemptsReached as! E)
                        .eraseToAnyPublisher()
                }
            }
            .first(where: { !shouldContinue($0) })
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.isPolling = false
            })
            .eraseToAnyPublisher()
        
        
        let publisher = initialOperation
                .append(timerPublisher)
                .first(where: { !shouldContinue($0) })
                .handleEvents(receiveCompletion: { [weak self] completion in
                    self?.isPolling = false
                    switch completion {
                    case .finished:
                        subject.send(completion: .finished)
                    case .failure(let error):
                        subject.send(completion: .failure(error))
                    }
                })
                .eraseToAnyPublisher()
        
        currentPollingCancellable = publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { _ in }
        )
        
        return subject.eraseToAnyPublisher()
    }
    
    func stopPolling() {
        isPolling = false
        currentPollingCancellable?.cancel()
        currentPollingCancellable = nil
    }
}

extension Future where Failure: Error {
    func poll(
        interval: TimeInterval,
        maxAttempts: Int? = nil,
        shouldContinue: @escaping (Output) -> Bool
    ) -> AnyPublisher<Output, Failure> {
        let pollingManager = PollingManager()
        return pollingManager.poll(
            interval: interval,
            maxAttempts: maxAttempts,
            shouldContinue: shouldContinue,
            operation: { self }
        )
    }
}
