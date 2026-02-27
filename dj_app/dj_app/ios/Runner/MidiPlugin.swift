// ios/Runner/MidiPlugin.swift
import Flutter
import UIKit
import CoreMIDI

public class MidiPlugin: NSObject, FlutterPlugin {

    private var methodChannel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?

    private var midiClient: MIDIClientRef = 0
    private var midiInputPort: MIDIPortRef = 0
    private var midiOutputPort: MIDIPortRef = 0
    private var sourceEndpoint: MIDIEndpointRef = 0
    private var destEndpoint: MIDIEndpointRef = 0

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MidiPlugin()

        let methodChannel = FlutterMethodChannel(
            name: "com.djapp/midi",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.djapp/midi_events",
            binaryMessenger: registrar.messenger()
        )

        instance.methodChannel = methodChannel
        instance.eventChannel = eventChannel

        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "connectCoreMidi":
            connectCoreMIDI(result: result)
        case "disconnectMidi":
            disconnect(result: result)
        case "sendMidi":
            if let args = call.arguments as? [String: Int],
               let status = args["status"],
               let data1 = args["data1"],
               let data2 = args["data2"] {
                sendMidi(status: status, data1: data1, data2: data2, result: result)
            } else {
                result(false)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ─────────────────────────────────────────
    // Connect via CoreMIDI
    // ─────────────────────────────────────────
    private func connectCoreMIDI(result: @escaping FlutterResult) {
        // Create MIDI client
        let clientStatus = MIDIClientCreate("DJController" as CFString, { notif, refCon in
            // MIDI notifications (device connect/disconnect)
        }, nil, &midiClient)

        guard clientStatus == noErr else {
            result(["connected": false, "deviceName": ""])
            return
        }

        // Create input port
        let inputStatus = MIDIInputPortCreate(midiClient, "Input" as CFString,
            { pktList, readProcRefCon, srcConnRefCon in
                let plugin = Unmanaged<MidiPlugin>
                    .fromOpaque(readProcRefCon!).takeUnretainedValue()
                plugin.receiveMIDI(pktList: pktList)
            },
            Unmanaged.passUnretained(self).toOpaque(),
            &midiInputPort
        )

        // Create output port
        MIDIOutputPortCreate(midiClient, "Output" as CFString, &midiOutputPort)

        // Find Hercules device
        let sourceCount = MIDIGetNumberOfSources()
        var deviceName = "Unknown"
        var found = false

        for i in 0..<sourceCount {
            let src = MIDIGetSource(i)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(src, kMIDIPropertyName, &name)
            let srcName = name?.takeRetainedValue() as String? ?? ""

            if srcName.lowercased().contains("inpulse") ||
               srcName.lowercased().contains("hercules") {
                sourceEndpoint = src
                deviceName = srcName
                found = true
                break
            }
        }

        // Fallback: use first available source
        if !found && sourceCount > 0 {
            sourceEndpoint = MIDIGetSource(0)
            var name: Unmanaged<CFString>?
            MIDIObjectGetStringProperty(sourceEndpoint, kMIDIPropertyName, &name)
            deviceName = name?.takeRetainedValue() as String? ?? "MIDI Device"
            found = true
        }

        if found {
            MIDIPortConnectSource(midiInputPort, sourceEndpoint, nil)

            // Find destination for output (LEDs)
            let destCount = MIDIGetNumberOfDestinations()
            for i in 0..<destCount {
                let dest = MIDIGetDestination(i)
                var name: Unmanaged<CFString>?
                MIDIObjectGetStringProperty(dest, kMIDIPropertyName, &name)
                let destName = name?.takeRetainedValue() as String? ?? ""
                if destName.lowercased().contains("inpulse") ||
                   destName.lowercased().contains("hercules") {
                    destEndpoint = dest
                    break
                }
            }
            if destEndpoint == 0 && destCount > 0 {
                destEndpoint = MIDIGetDestination(0)
            }
        }

        result(["connected": found, "deviceName": deviceName])
    }

    // ─────────────────────────────────────────
    // Receive MIDI packets
    // ─────────────────────────────────────────
    private func receiveMIDI(pktList: UnsafePointer<MIDIPacketList>) {
        let numPackets = Int(pktList.pointee.numPackets)
        var packet = pktList.pointee.packet

        for _ in 0..<numPackets {
            let bytes = withUnsafeBytes(of: packet.data) { Array($0) }
            let length = Int(packet.length)

            if length >= 3 {
                let status = Int(bytes[0])
                let data1 = Int(bytes[1])
                let data2 = Int(bytes[2])

                DispatchQueue.main.async {
                    self.eventSink?([status, data1, data2])
                }
            }
            packet = MIDIPacketNext(&packet).pointee
        }
    }

    // ─────────────────────────────────────────
    // Send MIDI (LEDs)
    // ─────────────────────────────────────────
    private func sendMidi(status: Int, data1: Int, data2: Int,
                          result: FlutterResult) {
        guard destEndpoint != 0 else { result(false); return }

        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length = 3
        packet.data.0 = UInt8(status)
        packet.data.1 = UInt8(data1)
        packet.data.2 = UInt8(data2)

        var pktList = MIDIPacketList(numPackets: 1, packet: packet)
        MIDISend(midiOutputPort, destEndpoint, &pktList)
        result(true)
    }

    private func disconnect(result: FlutterResult) {
        if midiInputPort != 0 && sourceEndpoint != 0 {
            MIDIPortDisconnectSource(midiInputPort, sourceEndpoint)
        }
        result(true)
    }
}

// MARK: - FlutterStreamHandler
extension MidiPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?,
                         eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
