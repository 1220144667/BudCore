//
//  Connection.swift
//  TinodeSDK
//
//  Copyright © 2019-2022 BudChat LLC. All rights reserved.
//

import Foundation
import UIKit
import Kit

public class Connection: WebSocketConnectionDelegate {
    private class ExpBackoffSteps {
        private let kBaseSleepMs = 500
        private let kMaxShift = 11
        private var attempt: Int = 0

        func getNextDelay() -> Int {
            if attempt > kMaxShift {
                attempt = kMaxShift
            }
            let half = UInt32(kBaseSleepMs * (1 << attempt))
            let delay = half + arc4random_uniform(half)
            attempt += 1
            return Int(delay)
        }

        func reset() {
            attempt = 0
        }
    }

    // Connection timeout in seconds.
    fileprivate let kConnectionTimeout: TimeInterval = 60.0

    var isConnected: Bool {
        guard let conn = webSocketConnection else { return false }
        return conn.state == .open
    }

    var isWaitingToConnect: Bool {
        guard let conn = webSocketConnection else { return false }
        return conn.state == .connecting
    }

    private var webSocketConnection: WebSocket?
    private var connectionListener: ConnectionListener?
    private var endpointComponenets: URLComponents
    private var apiKey: String
    private var useTLS = false
    private var connectQueue = DispatchQueue(label: "co.tinode.connection")
    private var autoreconnect: Bool = false
    private var reconnecting: Bool = false
    private var backoffSteps = ExpBackoffSteps()
    private var reconnectClosure: DispatchWorkItem?
    // Opaque parameter passed to onConnect. Used once then discarded.
    private var param: Any?

    init(open url: URL, with apiKey: String, notify listener: ConnectionListener?) {
        self.apiKey = apiKey
        // TODO: apply necessary URL modifications.
        endpointComponenets = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        connectionListener = listener
        if let scheme = endpointComponenets.scheme, scheme == "wss" || scheme == "https" {
            endpointComponenets.scheme = "wss"
            useTLS = true
        } else {
            endpointComponenets.scheme = "ws"
        }
        if endpointComponenets.port == nil {
            endpointComponenets.port = useTLS ? 443 : 80
        }
        webSocketConnection = WebSocket(timeout: kConnectionTimeout, delegate: self)
        maybeInitReconnectClosure()
    }

    func onConnected(connection _: WebSocket) {
        backoffSteps.reset()
        let r = reconnecting
        reconnecting = false
        let p = param
        param = nil
        connectionListener?.onConnect(reconnecting: r, param: p)
    }

    func onDisconnected(connection _: WebSocket, isServerOriginated clean: Bool, closeCode: URLSessionWebSocketTask.CloseCode, reason: String) {
        connectionListener?.onDisconnect(isServerOriginated: clean, code: closeCode, reason: reason)
        guard !reconnecting else {
            return
        }
        reconnecting = autoreconnect
        if autoreconnect {
            connectWithBackoffAsync()
        }
    }

    func onError(connection _: WebSocket, error: Error) {
        connectionListener?.onError(error: error)
    }

    func onMessage(connection _: WebSocket, text: String) {
        connectionListener?.onMessage(with: text)
    }

    func onMessage(connection _: WebSocket, data _: Data) {
        // Unexpected data message.
    }

    private func maybeInitReconnectClosure() {
        if reconnectClosure?.isCancelled ?? true {
            reconnectClosure = DispatchWorkItem {
                self.connectSocket()
                if self.isConnected {
                    self.reconnecting = false
                    return
                }
                self.connectWithBackoffAsync()
            }
        }
    }

    private func createUrlRequest() throws -> URLRequest {
        // ----------- request -----------
        var request = URLRequest(url: endpointComponenets.url!)
        // ----------- APIKey -----------
        request.addValue(apiKey, forHTTPHeaderField: "X-BudChat-APIKey")
        // ----------- 设备ID -----------
        let deviceId = UIDevice.deviceUUID()
        request.addValue(deviceId, forHTTPHeaderField: "X-BudChat-ID")
        // ----------- 时间戳（毫秒级） -----------
        let timestamp = getTimestamp()
        print("请求服务器时间：-\(timestamp)")
        request.addValue(String(timestamp), forHTTPHeaderField: "X-BudChat-TS")
        // ----------- 加密结果 -----------
        let sign = KitGenWsKey(apiKey, deviceId, Int64(timestamp))
        request.addValue(sign, forHTTPHeaderField: "X-WebSocket-Key")
        return request
    }

    private func getTimestamp() -> Int {
        // ----------- 时间差 -----------
        let diff = UserDefaults.standard.integer(forKey: "SYSTEM_TIME_DIFF")
        print("当前时间和服务器时间差:\(diff)")
        // ----------- 本地时间 -----------
        let now = Int(Date().timeIntervalSince1970 * 1000)
        return now - diff
    }

    private func openConnection(with urlRequest: URLRequest) {
        webSocketConnection?.connect(req: urlRequest)
    }

    private func connectSocket() {
        guard !isConnected else { return }
        let request = try! createUrlRequest()
        openConnection(with: request)
    }

    private func connectWithBackoffAsync() {
        let delay = Double(backoffSteps.getNextDelay()) / 1000
        maybeInitReconnectClosure()
        connectQueue.asyncAfter(deadline: .now() + delay, execute: reconnectClosure!)
    }

    @discardableResult
    func connect(reconnectAutomatically: Bool = true, withParam param: Any?) throws -> Bool {
        autoreconnect = reconnectAutomatically
        self.param = param
        if autoreconnect && reconnecting {
            // If we are trying to reconnect, do it now
            // (we simply reset the exp backoff steps).
            reconnectClosure!.cancel()
            backoffSteps.reset()
            connectWithBackoffAsync()
        } else {
            connectSocket()
        }
        return true
    }

    func disconnect() {
        webSocketConnection?.close()
        if autoreconnect {
            autoreconnect = false
            reconnectClosure!.cancel()
        }
    }

    func send(payload data: Data) {
        webSocketConnection?.send(data: data)
    }
}

protocol ConnectionListener {
    func onConnect(reconnecting: Bool, param: Any?)
    func onMessage(with message: String)
    func onDisconnect(isServerOriginated: Bool, code: URLSessionWebSocketTask.CloseCode, reason: String)
    func onError(error: Error)
}
