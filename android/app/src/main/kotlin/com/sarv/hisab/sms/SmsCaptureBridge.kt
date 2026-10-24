package com.sarv.hisab.sms

import io.flutter.plugin.common.EventChannel

/**
 * Process-wide link between [SmsReceiver] and a running Flutter UI. All
 * access happens on the main thread (receivers and channel handlers both
 * run there), so plain fields are enough.
 */
object SmsCaptureBridge {
    /** True while MainActivity is resumed; no notification is needed then. */
    var appVisible: Boolean = false

    /** Set while Dart listens on the sms_events channel. */
    var sink: EventChannel.EventSink? = null

    /** Tells a running app that the queue has new messages to drain. */
    fun signalQueued() {
        sink?.success("queued")
    }
}
