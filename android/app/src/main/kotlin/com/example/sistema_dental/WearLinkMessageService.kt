package com.example.sistema_dental

import android.content.Context
import com.google.android.gms.wearable.MessageEvent
import com.google.android.gms.wearable.WearableListenerService
import org.json.JSONArray
import org.json.JSONObject
import java.time.Instant

class WearLinkMessageService : WearableListenerService() {
    override fun onMessageReceived(messageEvent: MessageEvent) {
        val prefs = getSharedPreferences(prefsName, Context.MODE_PRIVATE)
        val payload = messageEvent.data.toString(Charsets.UTF_8)
        val sentAt = extractSentAt(payload)

        when (messageEvent.path) {
            sessionPath -> {
                val lastLogoutAt = prefs.getLong(lastLogoutAtKey, 0L)
                if (sentAt < lastLogoutAt) return

                prefs.edit()
                    .putString(sessionKey, payload)
                    .putString(currentStateKey, payload)
                    .putLong(lastSessionAtKey, sentAt)
                    .remove(logoutKey)
                    .apply()
            }
            logoutPath -> {
                val lastSessionAt = prefs.getLong(lastSessionAtKey, 0L)
                if (sentAt < lastSessionAt) return

                prefs.edit()
                    .putBoolean(logoutKey, true)
                    .putLong(lastLogoutAtKey, sentAt)
                    .remove(sessionKey)
                    .remove(currentStateKey)
                    .apply()
            }
            actionPath -> {
                val pending = try {
                    JSONArray(prefs.getString(actionsKey, "[]"))
                } catch (_: Exception) {
                    JSONArray()
                }
                pending.put(JSONObject(payload))
                while (pending.length() > 20) {
                    pending.remove(0)
                }
                prefs.edit().putString(actionsKey, pending.toString()).apply()
            }
        }
    }

    private fun extractSentAt(payload: String): Long {
        return try {
            val sentAt = JSONObject(payload).optString("sent_at", "")
            Instant.parse(sentAt).toEpochMilli()
        } catch (_: Exception) {
            System.currentTimeMillis()
        }
    }

    companion object {
        const val sessionPath = "/dental_sync/session"
        const val logoutPath = "/dental_sync/logout"
        const val actionPath = "/dental_sync/action"
        const val sessionDataPath = "/dental_sync/session_data"
        const val logoutDataPath = "/dental_sync/logout_data"
        const val payloadKey = "payload"
        const val sentAtKey = "sent_at"
        const val prefsName = "dental_sync_wear_link"
        const val sessionKey = "pending_session"
        const val currentStateKey = "current_state"
        const val logoutKey = "pending_logout"
        const val actionsKey = "pending_actions"
        const val phoneLinkedKey = "phone_session_linked"
        const val lastSessionAtKey = "last_session_at"
        const val lastLogoutAtKey = "last_logout_at"
    }
}
