# MQTTClientIOSSwift

SwiftUI sample app for connecting to an MQTT broker on iOS, publishing messages, subscribing to topics, and inspecting activity logs in real time.

## Features

- Connect to an MQTT broker using host, port, client ID, username, and password
- Publish messages to a topic
- Subscribe and unsubscribe from a topic
- Inspect connection state and MQTT activity logs in the UI
- Prefill the screen with default broker and topic values for quick testing

## Tech Stack

- SwiftUI
- CocoaMQTT `2.2.4`
- Swift Package Manager

## Default Demo Values

- Broker URL: `tcp://broker.emqx.io:1883`
- Client ID: `kotlin_client_03`
- Username: `test`
- Password: `test`
- Topic: `A3/test/logs`
- Message: `Hello!`

## Project Structure

- `MQTTClientIOSSwift/ContentView.swift`: main SwiftUI screen
- `MQTTClientIOSSwift/MQTTManager.swift`: MQTT connection, publish, subscribe, and log handling
- `MQTTClientIOSSwiftTests/`: unit test target
- `MQTTClientIOSSwiftUITests/`: UI test target

## How to Run

1. Open `MQTTClientIOSSwift.xcodeproj` in Xcode.
2. Wait for Swift Package Manager to resolve dependencies.
3. Select an iOS simulator or device.
4. Build and run the app.
5. Use the form to connect to a broker, publish a message, and subscribe to a topic.

## Notes

- The project uses `CocoaMQTT` for MQTT communication.
- The current test targets are the default template targets and can be expanded as the app evolves.