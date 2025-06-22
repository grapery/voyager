import OpenAPIRuntime
import OpenAPIURLSession
import Connect
import Foundation
import Combine

enum StreamError: Error {
    case connectionFailed
    case streamClosed
    case sendFailed
    case receiveFailed
    case invalidMessage
}

class StreamService {
    private var client: ProtocolClient?
    private var stream: BidirectionalStreamingCall<Message, Message>?
    private var isConnected: Bool = false
    private var reconnectTimer: Timer?
    private let reconnectInterval: TimeInterval = 5.0
    
    private var messageSubject = PassthroughSubject<Message, Never>()
    private var errorSubject = PassthroughSubject<Error, Never>()
    
    static let shared = StreamService()
    
    private init() {
        setupClient()
    }
    
    // MARK: - Client Setup
    private func setupClient() {
        do {
            self.client = ProtocolClient(
                httpClient: URLSessionHTTPClient(),
                config: ProtocolClientConfig(
                    host: "http://192.168.1.93:12307",
                    networkProtocol: .grpcWeb,
                    codec: ProtoCodec()
                )
            )
            connectStream()
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Stream Connection
    private func connectStream() {
        guard !isConnected, let client = client else { return }
        
        do {
            stream = try client.connect()
            isConnected = true
            
            // Start receiving messages
            Task {
                await receiveMessages()
            }
            
            // Reset reconnect timer
            reconnectTimer?.invalidate()
            reconnectTimer = nil
            
        } catch {
            handleError(error)
            scheduleReconnect()
        }
    }
    
    private func scheduleReconnect() {
        guard reconnectTimer == nil else { return }
        
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: reconnectInterval, repeats: true) { [weak self] _ in
            self?.connectStream()
        }
    }
    
    // MARK: - Message Handling
    func sendMessage(_ message: Message) async throws {
        guard let stream = stream, isConnected else {
            throw StreamError.connectionFailed
        }
        
        do {
            try await stream.send(message)
        } catch {
            handleError(error)
            throw StreamError.sendFailed
        }
    }
    
    private func receiveMessages() async {
        guard let stream = stream else { return }
        
        do {
            for try await message in stream {
                messageSubject.send(message)
            }
        } catch {
            handleError(error)
        }
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: Error) {
        errorSubject.send(error)
        isConnected = false
        
        // Clean up existing stream
        stream = nil
        
        // Schedule reconnection
        scheduleReconnect()
    }
    
    // MARK: - Public Interface
    var messagePublisher: AnyPublisher<Message, Never> {
        messageSubject.eraseToAnyPublisher()
    }
    
    var errorPublisher: AnyPublisher<Error, Never> {
        errorSubject.eraseToAnyPublisher()
    }
    
    func disconnect() {
        isConnected = false
        stream = nil
        reconnectTimer?.invalidate()
        reconnectTimer = nil
    }
    
    // MARK: - Connection Status
    var connectionStatus: AnyPublisher<Bool, Never> {
        Just(isConnected).eraseToAnyPublisher()
    }
}

// MARK: - Message Extensions
extension Message {
    // Add convenience methods for message creation
    static func createTextMessage(_ text: String) -> Message {
        // Implement message creation logic
        Message() // Placeholder implementation
    }
    
    static func createImageMessage(_ imageData: Data) -> Message {
        // Implement message creation logic
        Message() // Placeholder implementation
    }
}

// MARK: - Usage Example
extension StreamService {
    func sendTextMessage(_ text: String) async throws {
        let message = Message.createTextMessage(text)
        try await sendMessage(message)
    }
    
    func sendImageMessage(_ imageData: Data) async throws {
        let message = Message.createImageMessage(imageData)
        try await sendMessage(message)
    }
}