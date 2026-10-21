# shared_preferences_android calls its Kotlin API from Dart through JNI (package:jni), looking
# classes and methods up by their full JVM names at runtime. R8 cannot see those lookups, so it
# renames or strips the Kotlin types involved (kotlin.coroutines.Continuation became "z4",
# CoroutineSingletons was removed) and the release build throws on startup and never leaves
# the splash screen. Keep the plugin classes and every Kotlin type the JNI bindings name.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.CoroutineContext { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.jvm.functions.Function1 { *; }
-keep class kotlin.jvm.internal.DefaultConstructorMarker { *; }
-keep class kotlin.enums.EnumEntries { *; }
