# flutter_local_notifications — keep all plugin classes so R8
# does not strip the ScheduledNotificationReceiver's deserialization.
-keep class com.dexterous.** { *; }

# Keep Gson generic type info used by the plugin for serialization.
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
