# NetworkKit

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9-orange?logo=swift" alt="Swift 5.9"/>
  <img src="https://img.shields.io/badge/iOS-16%2B-blue?logo=apple" alt="iOS 16+"/>
  <img src="https://img.shields.io/badge/macOS-13%2B-blue?logo=apple" alt="macOS 13+"/>
  <img src="https://img.shields.io/badge/SPM-compatible-green" alt="SPM compatible"/>
  <img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT License"/>
</p>

<p align="center">
  Clean async/await HTTP client for Swift. URLSession without the boilerplate.
</p>

---

<p align="center">
  The Keychain, finally made simple. One property wrapper. Zero boilerplate.
</p>


---

## The Problem

```swift
// 😭 Native URLSession — 20 lines for a simple GET
guard let url = URL(string: "https://api.example.com/users") else { return }
var request = URLRequest(url: url)
request.setValue("application/json", forHTTPHeaderField: "Accept")
request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
let (data, response) = try await URLSession.shared.data(for: request)
guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
let users = try JSONDecoder().decode([User].self, from: data)
```

## The Solution

```swift
// 😍 NetworkKit — 1 line
let users: [User] = try await Network.get("https://api.example.com/users")
```

---

## Features

- ✅ `async/await` native — no callbacks, no Combine
- ✅ One-liners for GET, POST, PUT, PATCH, DELETE
- ✅ Automatic JSON encoding/decoding
- ✅ Smart error mapping — `.unauthorized`, `.notFound`, `.noConnection`
- ✅ Fluent request builder — `.header().body().query().timeout()`
- ✅ Configurable `NetworkClient` with base URL + default headers
- ✅ Full `NetworkResponse` access when needed
- ✅ Zero dependencies — wraps native `URLSession`
- ✅ iOS 16+, macOS 13+, tvOS, watchOS, visionOS

---

## Installation

```
https://github.com/ErsanQ/NetworkKit
```

```swift
.package(url: "https://github.com/ErsanQ/NetworkKit", from: "1.0.0")
```

---

## Usage

### Quick Requests

```swift
import NetworkKit

// GET
let users: [User] = try await Network.get("https://api.example.com/users")

// GET with query params
let results: SearchResult = try await Network.get(
    "https://api.example.com/search",
    query: ["q": "swift", "page": "1"]
)

// POST
let created: Post = try await Network.post("https://api.example.com/posts", body: newPost)

// PUT
let updated: User = try await Network.put("https://api.example.com/users/1", body: updatedUser)

// PATCH
let patched: User = try await Network.patch("https://api.example.com/users/1", body: changes)

// DELETE
try await Network.delete("https://api.example.com/posts/42")
```

### Dedicated Client (Recommended for APIs)

```swift
// Configure once
let api = NetworkClient(baseURL: "https://api.example.com")
api.defaultHeaders["Authorization"] = "Bearer \(token)"
api.defaultHeaders["X-App-Version"] = "2.0"

// Use everywhere
let me: User           = try await api.get("/me")
let posts: [Post]      = try await api.get("/posts", query: ["page": "1"])
let new: Post          = try await api.post("/posts", body: newPost)
try await api.delete("/posts/42")
```

### Error Handling

```swift
do {
    let user: User = try await api.get("/me")
} catch NetworkError.unauthorized {
    refreshToken()
} catch NetworkError.noConnection {
    showOfflineBanner()
} catch NetworkError.notFound {
    show404()
} catch NetworkError.serverError(let code) {
    logError(code)
} catch NetworkError.decodingFailed(let error) {
    print("Decode error:", error)
}
```

### Custom Requests

```swift
let response = try await Network.response(for:
    NetworkRequest(url: "https://api.example.com/upload")
        .method(.post)
        .header("Authorization", value: "Bearer \(token)")
        .body(imageData)
        .timeout(120)
)

print(response.statusCode)
print(response.headers["ETag"] ?? "")
let result = try response.decode(UploadResult.self)
```

---

## API Reference

### `Network` (static)

| Method | Description |
|--------|-------------|
| `get(_:query:)` | GET + decode |
| `post(_:body:)` | POST + decode or discard |
| `put(_:body:)` | PUT + decode |
| `patch(_:body:)` | PATCH + decode |
| `delete(_:)` | DELETE |
| `response(for:)` | Raw `NetworkResponse` |

### `NetworkClient`

| Property | Description |
|----------|-------------|
| `baseURL` | Prepended to all relative paths |
| `defaultHeaders` | Sent with every request |
| `defaultTimeout` | Default: `30` seconds |

### `NetworkRequest` (fluent builder)

`.method()` · `.header()` · `.headers()` · `.body()` · `.query()` · `.timeout()`

### `NetworkError`

`.noConnection` · `.unauthorized` · `.forbidden` · `.notFound` · `.serverError(statusCode:)` · `.decodingFailed(_:)` · `.timeout` · `.invalidURL(_:)`

---

## Requirements

- iOS 16.0+ / macOS 13.0+ / tvOS 16.0+ / watchOS 9.0+ / visionOS 1.0+
- Swift 5.9+
- Xcode 15.0+

---

## License

MIT License. See [LICENSE](LICENSE).

---

## Author

Built by **Ersan Q Abo Esha** — [@ErsanQ](https://github.com/ErsanQ)

If NetworkKit saved you time, consider giving it a ⭐️ on [GitHub](https://github.com/ErsanQ/NetworkKit).
