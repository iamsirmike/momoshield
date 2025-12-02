package com.example.momoshield

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.Telephony
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "momoshield/sms"
    private val EVENT_CHANNEL = "momoshield/sms_stream"
    private val NOTIFICATION_CHANNEL = "momoshield/notifications"
    private val SMS_PERMISSION_CODE = 1
    private val FRAUD_NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "MOMOSHIELD_FRAUD_ALERTS"
    
    private var eventSink: EventChannel.EventSink? = null
    private var smsReceiver: BroadcastReceiver? = null
    private var notificationManager: NotificationManager? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize notification manager
        notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        createNotificationChannel()
        
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

        // Method channel for notifications
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NOTIFICATION_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showFraudAlert" -> {
                    val phoneNumber = call.argument<String>("phoneNumber") ?: "Unknown"
                    val message = call.argument<String>("message") ?: "Suspicious message detected"
                    val threatType = call.argument<String>("threatType") ?: "Fraud"
                    showFraudNotification(phoneNumber, message, threatType)
                    result.success(true)
                }
                "wakeUpApp" -> {
                    wakeUpApp()
                    result.success(true)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Fraud Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications for detected SMS fraud attempts"
                enableVibration(true)
                enableLights(true)
                setShowBadge(true)
            }
            notificationManager?.createNotificationChannel(channel)
        }
    }

    private fun showFraudNotification(phoneNumber: String, message: String, threatType: String) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
            putExtra("fraud_alert", true)
            putExtra("phone_number", phoneNumber)
            putExtra("message", message)
        }
        
        val pendingIntent = PendingIntent.getActivity(
            this, 
            0, 
            intent, 
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle("🚨 $threatType Detected!")
            .setContentText("From: $phoneNumber")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Suspicious message from $phoneNumber:\n\n${message.take(100)}${if (message.length > 100) "..." else ""}"))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setColor(ContextCompat.getColor(this, android.R.color.holo_red_dark))
            .addAction(
                android.R.drawable.ic_menu_view,
                "View Details",
                pendingIntent
            )
            .addAction(
                android.R.drawable.ic_menu_close_clear_cancel,
                "Block Sender",
                createBlockSenderIntent(phoneNumber)
            )
            .build()

        notificationManager?.notify(FRAUD_NOTIFICATION_ID, notification)
    }

    private fun createBlockSenderIntent(phoneNumber: String): PendingIntent {
        val blockIntent = Intent(this, BlockSenderReceiver::class.java).apply {
            putExtra("phone_number", phoneNumber)
        }
        return PendingIntent.getBroadcast(
            this,
            phoneNumber.hashCode(),
            blockIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    private fun wakeUpApp() {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                   Intent.FLAG_ACTIVITY_CLEAR_TOP or 
                   Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("wake_up", true)
        }
        startActivity(intent)
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
                                
                                // Check for fraud patterns immediately
                                if (isLikelyFraud(smsMessage.messageBody ?: "")) {
                                    showFraudNotification(
                                        smsMessage.originatingAddress ?: "Unknown",
                                        smsMessage.messageBody ?: "",
                                        "SCAM"
                                    )
                                    wakeUpApp()
                                }
                                
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

    // Simple fraud detection for immediate notification
    private fun isLikelyFraud(message: String): Boolean {
        val fraudPatterns = listOf(
            "send your momo pin",
            "your momo has been blocked",
            "urgent money needed",
            "cash-out",
            "reset your account",
            "unlock bonus",
            "you won",
            "verify your pin",
            "account suspended",
            "immediate payment"
        )
        
        val lowerMessage = message.lowercase()
        return fraudPatterns.any { pattern -> 
            lowerMessage.contains(pattern)
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

// Broadcast receiver for handling block sender action
class BlockSenderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        val phoneNumber = intent?.getStringExtra("phone_number")
        // TODO: Implement blocking logic
        // For now, just show a toast or log
        android.util.Log.d("MoMoShield", "Block sender requested for: $phoneNumber")
    }
}
