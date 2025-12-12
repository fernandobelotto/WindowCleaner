# Create Service

Generate a service class for business logic, networking, or other non-UI operations.

## User Input
Describe what the service should do.

## Service Templates

### Basic Service
```swift
import Foundation
import os

actor MyService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "MyService"
    )
    
    // MARK: - Properties
    private var cache: [String: Data] = [:]
    
    // MARK: - Public API
    func performOperation() async throws -> Result {
        logger.info("Starting operation")
        
        do {
            let result = try await doWork()
            logger.info("Operation completed successfully")
            return result
        } catch {
            logger.error("Operation failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Helpers
    private func doWork() async throws -> Result {
        // Implementation
    }
}
```

### Network Service
```swift
import Foundation
import os

actor NetworkService {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "NetworkService"
    )
    private let session: URLSession
    private let decoder = JSONDecoder()
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        logger.debug("Fetching \(url.absoluteString)")
        
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            logger.error("HTTP error: \(httpResponse.statusCode)")
            throw NetworkError.httpError(httpResponse.statusCode)
        }
        
        return try decoder.decode(T.self, from: data)
    }
}

enum NetworkError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .httpError(let code):
            return "Server error (code: \(code))"
        }
    }
}
```

### Data Processing Service (nonisolated)
```swift
import Foundation
import os

// Use struct for stateless services
struct DataProcessor {
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "DataProcessor"
    )
    
    // nonisolated - can run on any thread
    nonisolated func process(data: Data) throws -> ProcessedResult {
        // CPU-intensive work that doesn't need main actor
        let parsed = try parse(data)
        let transformed = transform(parsed)
        return transformed
    }
    
    private func parse(_ data: Data) throws -> ParsedData { ... }
    private func transform(_ data: ParsedData) -> ProcessedResult { ... }
}
```

## Instructions

1. **Choose Service Type**
   - `actor` for services with mutable state
   - `struct` for stateless utilities
   - Use `nonisolated` for CPU-intensive work

2. **Create the File**
   - Location: `WindowCleaner/Services/[ServiceName].swift`

3. **Add Logging**
   - Use `os.Logger` for debugging
   - Log errors at `.error` level
   - Log success at `.info` level
   - Log verbose info at `.debug` level

4. **Define Errors**
   - Create service-specific error enum
   - Conform to `LocalizedError`
   - Provide user-friendly descriptions

5. **Integration**
   - Inject service into views/view models
   - Use `@Environment` for app-wide services
   - Consider dependency injection for testing

## Environment Integration
```swift
// Define environment key
struct MyServiceKey: EnvironmentKey {
    static let defaultValue = MyService()
}

extension EnvironmentValues {
    var myService: MyService {
        get { self[MyServiceKey.self] }
        set { self[MyServiceKey.self] = newValue }
    }
}

// Use in view
@Environment(\.myService) private var myService
```










