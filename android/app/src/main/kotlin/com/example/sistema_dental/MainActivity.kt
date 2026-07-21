package com.example.sistema_dental

import android.content.Context
import com.google.android.gms.wearable.DataMapItem
import com.google.android.gms.wearable.PutDataMapRequest
import com.google.android.gms.wearable.Wearable
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.time.Instant

class MainActivity : FlutterActivity() {
    private val channelName = "dental_sync/wear_link"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            channelName
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getConnectedWearDevices" -> getConnectedWearDevices(result)
                "linkWearSession" -> linkWearSession(call.arguments, result)
                "unlinkWearSession" -> unlinkWearSession(result)
                "consumePendingWearSession" -> consumePendingWearSession(result)
                "consumePendingWearUnlink" -> consumePendingWearUnlink(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun getConnectedWearDevices(result: MethodChannel.Result) {
        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes -> result.success(nodes.size) }
            .addOnFailureListener { error ->
                result.error("wear_nodes_error", error.localizedMessage, null)
            }
    }

    private fun linkWearSession(arguments: Any?, result: MethodChannel.Result) {
        val payload = arguments as? Map<*, *>
        if (payload == null) {
            result.error("invalid_payload", "No se pudo preparar la sesion Wear OS.", null)
            return
        }

        val stateJson = payload["state_json"] as? String
        if (stateJson.isNullOrBlank()) {
            result.error("invalid_payload", "No se pudo preparar el estado Wear OS.", null)
            return
        }
        val sentAt = payload["sent_at"] as? String ?: Instant.now().toString()
        val json = JSONObject()
        json.put("state_json", stateJson)
        json.put("sent_at", sentAt)

        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) {
                    result.success(mapOf("success" to false, "device_count" to 0))
                    return@addOnSuccessListener
                }

                var sent = 0
                var completed = 0
                val bytes = json.toString().toByteArray(Charsets.UTF_8)
                putWearDataItem(WearLinkMessageService.sessionDataPath, json.toString())
                nodes.forEach { node ->
                    Wearable.getMessageClient(this)
                        .sendMessage(node.id, WearLinkMessageService.sessionPath, bytes)
                        .addOnSuccessListener {
                            sent += 1
                            completed += 1
                            if (completed == nodes.size) {
                                result.success(
                                    mapOf(
                                        "success" to (sent > 0),
                                        "device_count" to sent
                                    )
                                )
                            }
                        }
                        .addOnFailureListener {
                            completed += 1
                            if (completed == nodes.size) {
                                result.success(
                                    mapOf(
                                        "success" to (sent > 0),
                                        "device_count" to sent
                                    )
                                )
                            }
                        }
                }
            }
            .addOnFailureListener { error ->
                result.error("wear_link_error", error.localizedMessage, null)
            }
    }

    private fun unlinkWearSession(result: MethodChannel.Result) {
        val json = JSONObject()
        json.put("sent_at", Instant.now().toString())
        val bytes = json.toString().toByteArray(Charsets.UTF_8)
        putWearDataItem(WearLinkMessageService.logoutDataPath, json.toString())

        Wearable.getNodeClient(this).connectedNodes
            .addOnSuccessListener { nodes ->
                if (nodes.isEmpty()) {
                    result.success(mapOf("success" to false, "device_count" to 0))
                    return@addOnSuccessListener
                }

                var sent = 0
                var completed = 0
                nodes.forEach { node ->
                    Wearable.getMessageClient(this)
                        .sendMessage(
                            node.id,
                            WearLinkMessageService.logoutPath,
                            bytes
                        )
                        .addOnSuccessListener {
                            sent += 1
                            completed += 1
                            if (completed == nodes.size) {
                                result.success(
                                    mapOf("success" to (sent > 0), "device_count" to sent)
                                )
                            }
                        }
                        .addOnFailureListener {
                            completed += 1
                            if (completed == nodes.size) {
                                result.success(
                                    mapOf("success" to (sent > 0), "device_count" to sent)
                                )
                            }
                        }
                }
            }
            .addOnFailureListener { error ->
                result.error("wear_unlink_error", error.localizedMessage, null)
            }
    }

    private fun consumePendingWearSession(result: MethodChannel.Result) {
        val prefs = getSharedPreferences(WearLinkMessageService.prefsName, Context.MODE_PRIVATE)
        val payload = prefs.getString(
            WearLinkMessageService.sessionKey,
            prefs.getString(WearLinkMessageService.currentStateKey, null)
        )
        if (payload == null) {
            consumePendingWearSessionFromDataLayer(result)
            return
        }

        prefs.edit().remove(WearLinkMessageService.sessionKey).apply()
        val json = JSONObject(payload)
        result.success(
            mapOf(
                "state_json" to json.optString("state_json", ""),
                "sent_at" to json.optString("sent_at", "")
            )
        )
    }

    private fun consumePendingWearUnlink(result: MethodChannel.Result) {
        val prefs = getSharedPreferences(WearLinkMessageService.prefsName, Context.MODE_PRIVATE)
        val pending = prefs.getBoolean(WearLinkMessageService.logoutKey, false)
        if (!pending) {
            consumePendingWearUnlinkFromDataLayer(result)
            return
        }

        prefs.edit()
            .remove(WearLinkMessageService.logoutKey)
            .remove(WearLinkMessageService.sessionKey)
            .remove(WearLinkMessageService.currentStateKey)
            .apply()
        result.success(true)
    }

    private fun putWearDataItem(path: String, payload: String) {
        val request = PutDataMapRequest.create(path).apply {
            dataMap.putString(WearLinkMessageService.payloadKey, payload)
            dataMap.putString(WearLinkMessageService.sentAtKey, Instant.now().toString())
        }.asPutDataRequest().setUrgent()

        Wearable.getDataClient(this).putDataItem(request)
    }

    private fun consumePendingWearSessionFromDataLayer(result: MethodChannel.Result) {
        Wearable.getDataClient(this).dataItems
            .addOnSuccessListener { items ->
                var payload: String? = null
                val urisToDelete = mutableListOf<android.net.Uri>()

                for (item in items) {
                    if (item.uri.path == WearLinkMessageService.sessionDataPath) {
                        payload = DataMapItem.fromDataItem(item)
                            .dataMap
                            .getString(WearLinkMessageService.payloadKey)
                        urisToDelete.add(item.uri)
                    }
                }
                items.release()

                urisToDelete.forEach { uri -> Wearable.getDataClient(this).deleteDataItems(uri) }
                if (payload == null) {
                    result.success(null)
                    return@addOnSuccessListener
                }

                getSharedPreferences(WearLinkMessageService.prefsName, Context.MODE_PRIVATE)
                    .edit()
                    .putString(WearLinkMessageService.currentStateKey, payload)
                    .apply()

                val json = JSONObject(payload)
                result.success(
                    mapOf(
                        "state_json" to json.optString("state_json", ""),
                        "sent_at" to json.optString("sent_at", "")
                    )
                )
            }
            .addOnFailureListener {
                result.success(null)
            }
    }

    private fun consumePendingWearUnlinkFromDataLayer(result: MethodChannel.Result) {
        Wearable.getDataClient(this).dataItems
            .addOnSuccessListener { items ->
                var logoutFound = false
                var logoutAt = 0L
                var sessionAt = 0L
                val urisToDelete = mutableListOf<android.net.Uri>()
                val sessionUris = mutableListOf<android.net.Uri>()

                for (item in items) {
                    if (item.uri.path == WearLinkMessageService.logoutDataPath) {
                        val dataMap = DataMapItem.fromDataItem(item).dataMap
                        logoutFound = true
                        logoutAt = parseInstantMillis(
                            dataMap.getString(WearLinkMessageService.sentAtKey)
                        )
                        urisToDelete.add(item.uri)
                    }
                    if (item.uri.path == WearLinkMessageService.sessionDataPath) {
                        val dataMap = DataMapItem.fromDataItem(item).dataMap
                        sessionAt = parseInstantMillis(
                            dataMap.getString(WearLinkMessageService.sentAtKey)
                        )
                        sessionUris.add(item.uri)
                    }
                }
                items.release()

                val shouldUnlink = logoutFound && logoutAt >= sessionAt
                if (shouldUnlink) {
                    urisToDelete.addAll(sessionUris)
                    getSharedPreferences(WearLinkMessageService.prefsName, Context.MODE_PRIVATE)
                        .edit()
                        .remove(WearLinkMessageService.currentStateKey)
                        .remove(WearLinkMessageService.sessionKey)
                        .remove(WearLinkMessageService.logoutKey)
                        .apply()
                }
                urisToDelete.forEach { uri -> Wearable.getDataClient(this).deleteDataItems(uri) }
                result.success(shouldUnlink)
            }
            .addOnFailureListener {
                result.success(false)
            }
    }

    private fun parseInstantMillis(value: String?): Long {
        return try {
            Instant.parse(value ?: "").toEpochMilli()
        } catch (_: Exception) {
            0L
        }
    }
}
