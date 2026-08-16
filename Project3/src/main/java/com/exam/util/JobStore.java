package com.exam.util;

import com.exam.util.AIUtils;
import com.exam.util.DBConnectionPool;

import javax.servlet.http.HttpSession;
import java.sql.Connection;
import java.util.*;
import java.util.concurrent.*;
import java.util.logging.*;

/**
 * Tracks asynchronous AI question-generation jobs.
 *
 * Flow:
 *   1. generateQuestion.jsp calls startAIJob() → gets a jobId back immediately.
 *   2. A background thread runs the Gemini call + DB insert.
 *   3. jobStatus.jsp polls getResult(jobId) until status != PENDING.
 *   4. On DONE, jobStatus.jsp writes tid into the session; browser goes to exam.jsp.
 *   5. On ERROR, browser shows the error message and goes back to setup.jsp.
 *
 * Entries auto-expire after 10 minutes so stale jobs never accumulate.
 */
public class JobStore {

    private static final Logger logger = Logger.getLogger(JobStore.class.getName());

    // How long to keep a completed/failed job before evicting it
    private static final long EXPIRY_MS = 10 * 60 * 1000L; // 10 minutes

    // Shared executor — reuse threads across all AI jobs
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    // ── Job status enum ───────────────────────────────────────────────────

    public enum Status { PENDING, DONE, ERROR, CANCELLED }

    // ── JobResult: what callers read back ────────────────────────────────

    public static class JobResult {
        public final Status status;
        public final int    tid;           // valid only when status == DONE
        public final String errorMessage;  // valid only when status == ERROR
        public final long   createdAt;

        private JobResult(Status status, int tid, String errorMessage) {
            this.status       = status;
            this.tid          = tid;
            this.errorMessage = errorMessage;
            this.createdAt    = System.currentTimeMillis();
        }

        public boolean isExpired() {
            return System.currentTimeMillis() - createdAt > EXPIRY_MS;
        }
    }

    // ── Internal job entry (mutable, replaced atomically) ─────────────────

    private static class JobEntry {
        volatile JobResult result;
        volatile Future<?> future;  // so we can cancel() it if needed

        JobEntry() {
            this.result = new JobResult(Status.PENDING, -1, null);
        }
    }

    // ── The store ─────────────────────────────────────────────────────────

    private static final ConcurrentHashMap<String, JobEntry> store = new ConcurrentHashMap<>();

    // Periodic cleanup — runs every 5 minutes, removes expired entries
    private static final ScheduledExecutorService cleaner =
            Executors.newSingleThreadScheduledExecutor();

    static {
        cleaner.scheduleAtFixedRate(() -> {
            Iterator<Map.Entry<String, JobEntry>> it = store.entrySet().iterator();
            while (it.hasNext()) {
                JobEntry entry = it.next().getValue();
                if (entry.result != null && entry.result.isExpired()) {
                    it.remove();
                }
            }
        }, 5, 5, TimeUnit.MINUTES);
    }

    // ── Public API ────────────────────────────────────────────────────────

    /**
     * Starts an async AI question-generation job.
     *
     * @param topic   the exam topic
     * @param tid     the topic ID already resolved by the caller
     * @param session the user's HTTP session (used to write currentTid on completion)
     * @return a unique jobId the caller can pass to the browser
     */
    public static String startAIJob(String topic, int tid, HttpSession session) {
        String jobId = UUID.randomUUID().toString();
        JobEntry entry = new JobEntry();
        store.put(jobId, entry);

        // Launch the background thread — no HTTP thread or DB connection held here
        Future<?> future = executor.submit(() -> {
            logger.info("[JobStore] Starting AI job " + jobId + " for topic: " + topic);

            // Check if cancelled before even starting
            if (entry.result.status == Status.CANCELLED) {
                logger.info("[JobStore] Job " + jobId + " was cancelled before starting.");
                return;
            }

            boolean success = false;
            String  error   = null;
            int     resultTid = tid;

            try {
                // AIUtils.fetchAIQuestionsAsync acquires its own DB connection
                // only during the INSERT (after Gemini responds) — see AIUtils.java
                success = AIUtils.fetchAIQuestionsAsync(topic, tid);

                if (!success) {
                    error = "AI question generation failed or timed out. " +
                            "Please try again or use Database questions.";
                }

            } catch (Exception e) {
                logger.log(Level.SEVERE, "[JobStore] Unexpected error in AI job " + jobId, e);
                error = "Something went wrong during AI generation. Please try again.";
            }

            // Don't update if cancelled mid-flight
            if (entry.result.status == Status.CANCELLED) {
                logger.info("[JobStore] Job " + jobId + " was cancelled mid-flight — result discarded.");
                return;
            }

            if (success) {
                entry.result = new JobResult(Status.DONE, resultTid, null);
                logger.info("[JobStore] Job " + jobId + " completed successfully (tid=" + resultTid + ")");
            } else {
                entry.result = new JobResult(Status.ERROR, -1, error);
                logger.warning("[JobStore] Job " + jobId + " failed: " + error);
            }
        });

        entry.future = future;
        return jobId;
    }

    /**
     * Returns the current result for a job, or null if the jobId is unknown/expired.
     */
    public static JobResult getResult(String jobId) {
        JobEntry entry = store.get(jobId);
        if (entry == null) return null;
        if (entry.result.isExpired()) {
            store.remove(jobId);
            return null;
        }
        return entry.result;
    }

    /**
     * Returns true if the jobId exists and has not expired.
     */
    public static boolean exists(String jobId) {
        JobEntry entry = store.get(jobId);
        return entry != null && !entry.result.isExpired();
    }

    /**
     * Marks a job as cancelled and interrupts the background thread if still running.
     */
    public static void cancel(String jobId) {
        JobEntry entry = store.get(jobId);
        if (entry == null) return;
        entry.result = new JobResult(Status.CANCELLED, -1, null);
        if (entry.future != null) {
            entry.future.cancel(true); // sends interrupt to the thread
        }
        logger.info("[JobStore] Job " + jobId + " cancelled.");
    }

    /**
     * Removes a job from the store (called after a terminal state is read).
     */
    public static void remove(String jobId) {
        store.remove(jobId);
    }
}