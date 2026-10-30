package com.ragedpanda.hisab.backup

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import java.util.concurrent.TimeUnit

/**
 * Wakes Hisab every few hours while a backup schedule is on, without a
 * library: a periodic JobScheduler job starts a headless Flutter engine at
 * `scheduledBackupMain` (lib/main.dart). The Dart side decides whether a
 * backup is due, writes it to the chosen folder, and calls
 * `backgroundRunFinished`. Persisted, so it survives a reboot.
 */
class ScheduledBackupJob : JobService() {
    private var engine: FlutterEngine? = null
    private var running: JobParameters? = null
    private val main = Handler(Looper.getMainLooper())
    private val timeout = Runnable { finish() }

    override fun onStartJob(params: JobParameters): Boolean {
        running = params
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationCompleteAsync(applicationContext, null, main) {
            if (running == null) return@ensureInitializationCompleteAsync
            val started = FlutterEngine(applicationContext)
            engine = started
            ScheduledBackupChannel(applicationContext, started.dartExecutor.binaryMessenger, onBackgroundRunFinished = ::finish)
            started.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT))
        }
        main.postDelayed(timeout, RUN_LIMIT_MILLIS)
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        running = null
        stopEngine()
        return true
    }

    private fun finish() {
        val params = running ?: return
        running = null
        stopEngine()
        jobFinished(params, false)
    }

    private fun stopEngine() {
        main.removeCallbacks(timeout)
        engine?.destroy()
        engine = null
    }

    companion object {
        private const val JOB_ID = 4207
        private const val ENTRYPOINT = "scheduledBackupMain"
        private val PERIOD_MILLIS = TimeUnit.HOURS.toMillis(6)
        private val FLEX_MILLIS = TimeUnit.HOURS.toMillis(2)
        private val RUN_LIMIT_MILLIS = TimeUnit.MINUTES.toMillis(8)

        /** Schedules the periodic check, or cancels it. An existing job keeps its timing. */
        fun setEnabled(context: Context, enabled: Boolean) {
            val scheduler = context.getSystemService(JobScheduler::class.java) ?: return
            if (!enabled) {
                scheduler.cancel(JOB_ID)
                return
            }
            if (scheduler.getPendingJob(JOB_ID) != null) return
            val job = JobInfo.Builder(JOB_ID, ComponentName(context, ScheduledBackupJob::class.java))
                .setPeriodic(PERIOD_MILLIS, FLEX_MILLIS)
                .setRequiresBatteryNotLow(true)
                .setPersisted(true)
                .build()
            scheduler.schedule(job)
        }
    }
}
