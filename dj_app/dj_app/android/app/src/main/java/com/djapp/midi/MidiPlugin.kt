// android/app/src/main/java/com/djapp/midi/MidiPlugin.kt
package com.djapp.midi

import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbDeviceConnection
import android.hardware.usb.UsbInterface
import android.hardware.usb.UsbManager
import android.os.Build
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MidiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler {

    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null

    private lateinit var context: Context
    private var usbManager: UsbManager? = null
    private var deviceConnection: UsbDeviceConnection? = null
    private var midiInterface: UsbInterface? = null

    // Hercules Inpulse 300 USB Vendor/Product IDs
    private val HERCULES_VENDOR_ID = 0x06F8
    private val INPULSE_300_PRODUCT_ID = 0xB105

    private val ACTION_USB_PERMISSION = "com.djapp.USB_PERMISSION"

    private var readerThread: Thread? = null
    private var running = false

    // ─────────────────────────────────────────
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        usbManager = context.getSystemService(Context.USB_SERVICE) as UsbManager

        methodChannel = MethodChannel(binding.binaryMessenger, "com.djapp/midi")
        methodChannel.setMethodCallHandler(this)

        eventChannel = EventChannel(binding.binaryMessenger, "com.djapp/midi_events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }
            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        stopReaderThread()
    }

    // ─────────────────────────────────────────
    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "connectUSBMidi" -> connectUSB(result)
            "disconnectMidi" -> disconnect(result)
            "sendMidi" -> {
                val status = call.argument<Int>("status") ?: 0
                val data1 = call.argument<Int>("data1") ?: 0
                val data2 = call.argument<Int>("data2") ?: 0
                sendMidi(status, data1, data2, result)
            }
            else -> result.notImplemented()
        }
    }

    // ─────────────────────────────────────────
    // Connect to Hercules Inpulse 300 via USB
    // ─────────────────────────────────────────
    private fun connectUSB(result: MethodChannel.Result) {
        val deviceList = usbManager?.deviceList ?: run {
            result.success(mapOf("connected" to false, "deviceName" to ""))
            return
        }

        // Find Hercules device
        val herculesDevice = deviceList.values.find { device ->
            device.vendorId == HERCULES_VENDOR_ID
        } ?: deviceList.values.firstOrNull { device ->
            // Fallback: any MIDI device
            device.deviceClass == 1 // USB_CLASS_AUDIO
        }

        if (herculesDevice == null) {
            result.success(mapOf("connected" to false, "deviceName" to ""))
            return
        }

        // Request permission if needed
        if (usbManager?.hasPermission(herculesDevice) == false) {
            requestPermission(herculesDevice, result)
            return
        }

        openDevice(herculesDevice, result)
    }

    private fun requestPermission(device: UsbDevice, result: MethodChannel.Result) {
        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_IMMUTABLE
        } else 0

        val permissionIntent = PendingIntent.getBroadcast(
            context, 0, Intent(ACTION_USB_PERMISSION), flags
        )

        val filter = IntentFilter(ACTION_USB_PERMISSION)
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(ctx: Context, intent: Intent) {
                if (intent.action == ACTION_USB_PERMISSION) {
                    val granted = intent.getBooleanExtra(
                        UsbManager.EXTRA_PERMISSION_GRANTED, false
                    )
                    context.unregisterReceiver(this)
                    if (granted) {
                        openDevice(device, result)
                    } else {
                        result.success(mapOf("connected" to false, "deviceName" to ""))
                    }
                }
            }
        }
        context.registerReceiver(receiver, filter)
        usbManager?.requestPermission(device, permissionIntent)
    }

    private fun openDevice(device: UsbDevice, result: MethodChannel.Result) {
        val connection = usbManager?.openDevice(device) ?: run {
            result.success(mapOf("connected" to false, "deviceName" to ""))
            return
        }

        // Find MIDI interface (typically interface 0 or 1 for MIDI class)
        var midiIface: UsbInterface? = null
        for (i in 0 until device.interfaceCount) {
            val iface = device.getInterface(i)
            if (iface.interfaceClass == 1 && iface.interfaceSubclass == 3) {
                // USB Audio MIDI Streaming
                midiIface = iface
                break
            }
        }

        // Fallback to first interface
        if (midiIface == null && device.interfaceCount > 0) {
            midiIface = device.getInterface(0)
        }

        if (midiIface == null) {
            result.success(mapOf("connected" to false, "deviceName" to ""))
            return
        }

        connection.claimInterface(midiIface, true)
        deviceConnection = connection
        midiInterface = midiIface

        startReaderThread(connection, midiIface)

        result.success(mapOf(
            "connected" to true,
            "deviceName" to (device.productName ?: "Hercules Controller")
        ))
    }

    // ─────────────────────────────────────────
    // Read MIDI data from USB
    // ─────────────────────────────────────────
    private fun startReaderThread(
        connection: UsbDeviceConnection,
        iface: UsbInterface
    ) {
        running = true
        readerThread = Thread {
            val buffer = ByteArray(64)
            var endpoint = iface.getEndpoint(0)

            // Find bulk-in endpoint
            for (i in 0 until iface.endpointCount) {
                val ep = iface.getEndpoint(i)
                if (ep.direction == android.hardware.usb.UsbConstants.USB_DIR_IN) {
                    endpoint = ep
                    break
                }
            }

            while (running) {
                val bytesRead = connection.bulkTransfer(endpoint, buffer, buffer.size, 100)
                if (bytesRead > 0) {
                    // USB MIDI packets are 4 bytes: [cable+code, status, data1, data2]
                    var i = 0
                    while (i + 3 < bytesRead) {
                        val status = buffer[i + 1].toInt() and 0xFF
                        val data1 = buffer[i + 2].toInt() and 0xFF
                        val data2 = buffer[i + 3].toInt() and 0xFF

                        if (status != 0) {
                            val midiEvent = listOf(status, data1, data2)
                            android.os.Handler(android.os.Looper.getMainLooper()).post {
                                eventSink?.success(midiEvent)
                            }
                        }
                        i += 4
                    }
                }
            }
        }
        readerThread?.start()
    }

    private fun stopReaderThread() {
        running = false
        readerThread?.interrupt()
        readerThread = null
    }

    // ─────────────────────────────────────────
    // Send MIDI (for LED control)
    // ─────────────────────────────────────────
    private fun sendMidi(
        status: Int, data1: Int, data2: Int,
        result: MethodChannel.Result
    ) {
        val connection = deviceConnection ?: run {
            result.success(false)
            return
        }
        val iface = midiInterface ?: run {
            result.success(false)
            return
        }

        // Find bulk-out endpoint
        var outEndpoint = iface.getEndpoint(0)
        for (i in 0 until iface.endpointCount) {
            val ep = iface.getEndpoint(i)
            if (ep.direction == android.hardware.usb.UsbConstants.USB_DIR_OUT) {
                outEndpoint = ep
                break
            }
        }

        // USB MIDI packet format: [cable<<4|code, status, data1, data2]
        val codeIndex = when {
            status and 0xF0 == 0x90 -> 0x09  // Note On
            status and 0xF0 == 0x80 -> 0x08  // Note Off
            status and 0xF0 == 0xB0 -> 0x0B  // Control Change
            else -> 0x0F
        }
        val packet = byteArrayOf(
            codeIndex.toByte(),
            status.toByte(),
            data1.toByte(),
            data2.toByte()
        )

        Thread {
            connection.bulkTransfer(outEndpoint, packet, packet.size, 100)
        }.start()

        result.success(true)
    }

    private fun disconnect(result: MethodChannel.Result) {
        stopReaderThread()
        midiInterface?.let { deviceConnection?.releaseInterface(it) }
        deviceConnection?.close()
        deviceConnection = null
        midiInterface = null
        result.success(true)
    }
}
