package com.example.momoshield

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.provider.Telephony
import android.telephony.SmsMessage
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "momoshield/sms"
    private val EVENT_CHANNEL = "momoshield/sms_stream"
    private val SMS_PERMISSION_CODE = 1
    
    private var eventSink: EventChannel.EventSink? = null
    private var smsReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getRecentMessages" -> {
                    val limit = call.argument<Int>("limit") ?: 100
                    if (checkSmsPermission()) {
                        val messages = getRecentSmsMessages(limit)
                        result.success(messages)
                    } else {
                        result.error("PERMISSION_DENIED", "SMS permission not granted", null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
        
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                    startListeningForSms()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                    stopListeningForSms()
                }
            }
        )
    }

    private fun checkSmsPermission(): Boolean {
        val readSms = ContextCompat.checkSelfPermission(this, Manifest.permission.READ_SMS) == PackageManager.PERMISSION_GRANTED
        val receiveSms = ContextCompat.checkSelfPermission(this, Manifest.permission.RECEIVE_SMS) == PackageManager.PERMISSION_GRANTED
        return readSms && receiveSms
    }

    private fun getRecentSmsMessages(limit: Int): List<Map<String, Any>> {
        val messages = mutableListOf<Map<String, Any>>()
        
        try {
            val uri = Uri.parse("content://sms/inbox")
            val projection = arrayOf("_id", "address", "body", "date")
            val sortOrder = "date DESC LIMIT $limit"
            
            val cursor: Cursor? = contentResolver.query(uri, projection, null, null, sortOrder)
            
            cursor?.use {
                val idIndex = it.getColumnIndex("_id")
                val addressIndex = it.getColumnIndex("address")
                val bodyIndex = it.getColumnIndex("body")
                val dateIndex = it.getColumnIndex("date")
                
                while (it.moveToNext()) {
                    val message = mapOf(
                        "id" to (if (idIndex >= 0) it.getString(idIndex) else ""),
                        "address" to (if (addressIndex >= 0) it.getString(addressIndex) else ""),
                        "body" to (if (bodyIndex >= 0) it.getString(bodyIndex) else ""),
                        "date" to (if (dateIndex >= 0) it.getLong(dateIndex) else 0L)
                    )
                    messages.add(message)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
        
        return messages
    }

    private fun startListeningForSms() {
        if (!checkSmsPermission()) {
            eventSink?.error("PERMISSION_DENIED", "SMS permissions not granted", null)
            return
        }
        
        try {
            smsReceiver = object : BroadcastReceiver() {
                override fun onReceive(context: Context?, intent: Intent?) {
                    if (intent?.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
                        try {
                            val messages = Telephony.Sms.Intents.getMessagesFromIntent(intent)
                            for (smsMessage in messages) {
                                val messageData = mapOf(
                                    "id" to System.currentTimeMillis().toString(),
                                    "address" to (smsMessage.originatingAddress ?: ""),
                                    "body" to (smsMessage.messageBody ?: ""),
                                    "date" to smsMessage.timestampMillis
                                )
                                eventSink?.success(messageData)
                            }
                        } catch (e: Exception) {
                            eventSink?.error("SMS_PARSE_ERROR", e.message, null)
                        }
                    }
                }
            }
            
            val filter = IntentFilter(Telephony.Sms.Intents.SMS_RECEIVED_ACTION)
            filter.priority = 1000
            registerReceiver(smsReceiver, filter)
        } catch (e: Exception) {
            eventSink?.error("LISTENER_START_ERROR", e.message, null)
        }
    }
    
    private fun stopListeningForSms() {
        smsReceiver?.let { receiver ->
            try {
                unregisterReceiver(receiver)
            } catch (e: Exception) {
                // Receiver was not registered
            }
        }
        smsReceiver = null
    }

    override fun onDestroy() {
        super.onDestroy()
        stopListeningForSms()
    }
}
