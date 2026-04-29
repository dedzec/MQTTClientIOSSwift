//
//  ContentView.swift
//  MQTTClientIOSSwift
//
//  Created by Project on 28/04/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var mqttManager = MQTTManager()

    @State private var brokerURL = MQTTDefaults.brokerURL
    @State private var clientId = MQTTDefaults.clientId
    @State private var username = MQTTDefaults.username
    @State private var password = MQTTDefaults.password
    @State private var publishTopic = MQTTDefaults.topic
    @State private var publishMessage = MQTTDefaults.message
    @State private var subscribeTopic = MQTTDefaults.topic

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statusCard
                    connectionCard
                    actionsCard
                    activityCard
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("MQTT Client")
        }
    }

    private var statusCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Status")
                .font(.headline)

            HStack {
                Circle()
                    .fill(mqttManager.isConnected ? Color.green : Color.orange)
                    .frame(width: 12, height: 12)

                Text(mqttManager.connectionStatus)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var connectionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connection")
                .font(.headline)

            Group {
                labeledField(title: "Broker URL", text: $brokerURL, prompt: "tcp://broker.emqx.io:1883")
                labeledField(title: "Client ID", text: $clientId, prompt: MQTTDefaults.clientId)
                labeledField(title: "Username", text: $username, prompt: "test")
                labeledSecureField(title: "Password", text: $password, prompt: "test")
            }

            HStack(spacing: 12) {
                Button("Prefill") {
                    brokerURL = MQTTDefaults.brokerURL
                    clientId = MQTTDefaults.clientId
                    username = MQTTDefaults.username
                    password = MQTTDefaults.password
                }
                .buttonStyle(.bordered)

                Button("Clear") {
                    brokerURL = ""
                    clientId = ""
                    username = ""
                    password = ""
                }
                .buttonStyle(.bordered)

                Button("Connect") {
                    mqttManager.connect(
                        brokerURL: brokerURL,
                        clientId: clientId,
                        username: username,
                        password: password
                    )
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Messaging")
                .font(.headline)

            labeledField(title: "Publish Topic", text: $publishTopic, prompt: MQTTDefaults.topic)
            labeledField(title: "Message", text: $publishMessage, prompt: MQTTDefaults.message)

            HStack(spacing: 12) {
                Button("Publish") {
                    mqttManager.publish(topic: publishTopic, message: publishMessage)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!mqttManager.isConnected)

                Button("Prefill") {
                    publishTopic = MQTTDefaults.topic
                    publishMessage = MQTTDefaults.message
                    subscribeTopic = MQTTDefaults.topic
                }
                .buttonStyle(.bordered)

                Button("Clear") {
                    publishTopic = ""
                    publishMessage = ""
                    subscribeTopic = ""
                }
                .buttonStyle(.bordered)
            }

            labeledField(title: "Subscribe Topic", text: $subscribeTopic, prompt: MQTTDefaults.topic)

            HStack(spacing: 12) {
                Button("Subscribe") {
                    mqttManager.subscribe(topic: subscribeTopic)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!mqttManager.isConnected)

                Button("Unsubscribe") {
                    mqttManager.unsubscribe(topic: subscribeTopic)
                }
                .buttonStyle(.bordered)
                .disabled(!mqttManager.isConnected)

                Button("Disconnect") {
                    mqttManager.disconnect()
                }
                .buttonStyle(.bordered)
                .disabled(!mqttManager.isConnected)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var activityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Activity")
                    .font(.headline)

                Spacer()

                Button("Clear Log") {
                    mqttManager.clearLog()
                }
                .buttonStyle(.borderless)
            }

            if mqttManager.activityLog.isEmpty {
                Text("No MQTT activity yet.")
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(mqttManager.activityLog.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(.caption.monospaced())
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func labeledField(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
            TextField(prompt, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private func labeledSecureField(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.medium))
            SecureField(prompt, text: text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(12)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}

#Preview {
    ContentView()
}
