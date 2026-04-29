import Combine
import Foundation
import CocoaMQTT

enum MQTTManagerError: LocalizedError {
    case invalidBrokerURL
    case invalidClientId
    case invalidTopic
    case notConnected

    var errorDescription: String? {
        switch self {
        case .invalidBrokerURL:
            return "Enter a valid broker URL such as tcp://broker.emqx.io:1883."
        case .invalidClientId:
            return "Client ID is required."
        case .invalidTopic:
            return "Topic is required."
        case .notConnected:
            return "Connect to the broker before sending MQTT commands."
        }
    }
}

struct MQTTDefaults {
    static let brokerURL = "tcp://broker.emqx.io:1883"
    static let clientId = "kotlin_client_03"
    static let username = "test"
    static let password = "test"
    static let topic = "A3/test/logs"
    static let message = "Hello!"
}

private struct BrokerConfiguration {
    let host: String
    let port: UInt16
    let clientId: String
    let username: String
    let password: String
    let displayURL: String

    init(rawBrokerURL: String, clientId: String, username: String, password: String) throws {
        let trimmedBrokerURL = rawBrokerURL.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedClientId.isEmpty else {
            throw MQTTManagerError.invalidClientId
        }

        let normalizedBrokerURL = trimmedBrokerURL.contains("://") ? trimmedBrokerURL : "tcp://\(trimmedBrokerURL)"
        guard let components = URLComponents(string: normalizedBrokerURL),
              let scheme = components.scheme?.lowercased(),
              ["tcp", "mqtt"].contains(scheme),
              let resolvedHost = components.host,
              !resolvedHost.isEmpty else {
            throw MQTTManagerError.invalidBrokerURL
        }

        let resolvedPort = UInt16(components.port ?? 1883)

        host = resolvedHost
        port = resolvedPort
        self.clientId = trimmedClientId
        self.username = username.trimmingCharacters(in: .whitespacesAndNewlines)
        self.password = password.trimmingCharacters(in: .whitespacesAndNewlines)
        displayURL = "\(scheme)://\(resolvedHost):\(resolvedPort)"
    }
}

@MainActor
final class MQTTManager: ObservableObject {
    @Published private(set) var isConnected = false
    @Published private(set) var connectionStatus = "Disconnected"
    @Published private(set) var activityLog: [String] = []

    private var mqttClient: CocoaMQTT?

    func connect(brokerURL: String, clientId: String, username: String, password: String) {
        do {
            let configuration = try BrokerConfiguration(
                rawBrokerURL: brokerURL,
                clientId: clientId,
                username: username,
                password: password
            )

            if mqttClient != nil {
                mqttClient?.disconnect()
            }

            let client = CocoaMQTT(clientID: configuration.clientId, host: configuration.host, port: configuration.port)
            client.username = configuration.username.isEmpty ? nil : configuration.username
            client.password = configuration.password.isEmpty ? nil : configuration.password
            client.keepAlive = 60
            client.autoReconnect = false
            bindCallbacks(for: client)

            mqttClient = client
            connectionStatus = "Connecting"
            appendLog("Connecting to \(configuration.displayURL) with client ID \(configuration.clientId).")

            if !client.connect() {
                connectionStatus = "Disconnected"
                appendLog("Socket connection could not be started.")
            }
        } catch {
            appendLog(error.localizedDescription)
        }
    }

    func disconnect() {
        guard let mqttClient else {
            appendLog("No active MQTT client to disconnect.")
            return
        }

        appendLog("Disconnect requested.")
        mqttClient.disconnect()
    }

    func subscribe(topic: String) {
        do {
            let topic = try validatedTopic(topic)
            let mqttClient = try validatedConnectedClient()

            mqttClient.subscribe(topic, qos: .qos1)
            appendLog("Subscribe requested for \(topic).")
        } catch {
            appendLog(error.localizedDescription)
        }
    }

    func unsubscribe(topic: String) {
        do {
            let topic = try validatedTopic(topic)
            let mqttClient = try validatedConnectedClient()

            mqttClient.unsubscribe(topic)
            appendLog("Unsubscribe requested for \(topic).")
        } catch {
            appendLog(error.localizedDescription)
        }
    }

    func publish(topic: String, message: String) {
        do {
            let topic = try validatedTopic(topic)
            let mqttClient = try validatedConnectedClient()
            let payload = message.trimmingCharacters(in: .whitespacesAndNewlines)

            let messageId = mqttClient.publish(topic, withString: payload, qos: .qos1, retained: false)
            appendLog("Publish queued to \(topic) with message ID \(messageId).")
        } catch {
            appendLog(error.localizedDescription)
        }
    }

    func clearLog() {
        activityLog.removeAll()
    }

    private func bindCallbacks(for client: CocoaMQTT) {
        client.didConnectAck = { [weak self] _, ack in
            Task { @MainActor in
                guard let self else { return }

                if ack == .accept {
                    self.isConnected = true
                    self.connectionStatus = "Connected"
                    self.appendLog("Connection success.")
                } else {
                    self.isConnected = false
                    self.connectionStatus = "Disconnected"
                    self.appendLog("Connection rejected: \(ack.description).")
                }
            }
        }

        client.didChangeState = { [weak self] _, state in
            Task { @MainActor in
                self?.connectionStatus = state.description.capitalized
            }
        }

        client.didReceiveMessage = { [weak self] _, message, _ in
            Task { @MainActor in
                let payload = message.string ?? String(data: Data(message.payload), encoding: .utf8) ?? ""
                self?.appendLog("Received from \(message.topic): \(payload)")
            }
        }

        client.didPublishMessage = { [weak self] _, message, id in
            Task { @MainActor in
                self?.appendLog("Published \(message.string ?? "") to \(message.topic) with ID \(id).")
            }
        }

        client.didPublishAck = { [weak self] _, id in
            Task { @MainActor in
                self?.appendLog("Delivery completed for message ID \(id).")
            }
        }

        client.didSubscribeTopics = { [weak self] _, success, failed in
            Task { @MainActor in
                let subscribedTopics = (success.allKeys as? [String]) ?? []
                if !subscribedTopics.isEmpty {
                    self?.appendLog("Subscribed to: \(subscribedTopics.joined(separator: ", ")).")
                }
                if !failed.isEmpty {
                    self?.appendLog("Failed to subscribe: \(failed.joined(separator: ", ")).")
                }
            }
        }

        client.didUnsubscribeTopics = { [weak self] _, topics in
            Task { @MainActor in
                self?.appendLog("Unsubscribed from: \(topics.joined(separator: ", ")).")
            }
        }

        client.didDisconnect = { [weak self] _, error in
            Task { @MainActor in
                guard let self else { return }

                self.isConnected = false
                self.connectionStatus = "Disconnected"
                self.appendLog(error.map { "Disconnected with error: \($0.localizedDescription)" } ?? "Disconnected.")
            }
        }
    }

    private func validatedConnectedClient() throws -> CocoaMQTT {
        guard let mqttClient, isConnected else {
            throw MQTTManagerError.notConnected
        }
        return mqttClient
    }

    private func validatedTopic(_ topic: String) throws -> String {
        let trimmedTopic = topic.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTopic.isEmpty else {
            throw MQTTManagerError.invalidTopic
        }
        return trimmedTopic
    }

    private func appendLog(_ message: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        activityLog.insert("[\(formatter.string(from: Date()))] \(message)", at: 0)

        if activityLog.count > 100 {
            activityLog.removeLast(activityLog.count - 100)
        }
    }
}