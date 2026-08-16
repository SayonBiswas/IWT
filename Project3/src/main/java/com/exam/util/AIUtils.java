package com.exam.util;

import com.google.genai.Client;
import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.util.regex.*;
import java.util.concurrent.*;

public class AIUtils {

    private static final Logger logger = Logger.getLogger(AIUtils.class.getName());
    private static final String model  = "gemini-3-flash-preview";

    private static final int AI_TIMEOUT_SECONDS = 60;
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    private static final Client client = Client.builder()
            .apiKey(System.getenv("GEMINI_API_KEY"))
            .build();

    private static final Pattern QUESTION_PATTERN = Pattern.compile(
            "(?im)^\\s*(\\d+)[.)]+\\s*(.+)\\r?\\n" +
                    "\\s*A[.)]+\\s*(.+)\\r?\\n" +
                    "\\s*B[.)]+\\s*(.+)\\r?\\n" +
                    "\\s*C[.)]+\\s*(.+)\\r?\\n" +
                    "\\s*D[.)]+\\s*(.+)\\r?\\n" +
                    "\\s*(?:\\*{0,2})\\s*Answer\\s*[:\\s]+(?:\\*{0,2})\\s*([A-D])"
    );

    private static final String PROMPT_TEMPLATE =
            "Generate exactly 10 multiple choice questions on the topic: %s.\n" +
                    "Use ONLY this plain text format with no markdown, no bold, no asterisks:\n\n" +
                    "1. Question text here\n" +
                    "A) Option one\n" +
                    "B) Option two\n" +
                    "C) Option three\n" +
                    "D) Option four\n" +
                    "Answer: A\n\n" +
                    "Repeat for all 10 questions. Do not add any extra text or formatting.";

    // ── Original entry point (database source still uses this) ───────────

    public static int prepareQuestions(Connection conn, String topic, String source) throws SQLException {
        int tid = getTopicId(conn, topic);

        if (source.equals("database")) {
            if (tid == -1) return -1;
            try (PreparedStatement check = conn.prepareStatement(
                    "SELECT COUNT(*) FROM questions WHERE tid = ?")) {
                check.setInt(1, tid);
                ResultSet rs = check.executeQuery();
                rs.next();
                return rs.getInt(1) == 0 ? -1 : tid;
            }
        }
        // source "ai" is no longer handled here — use prepareTopicForAI + fetchAIQuestionsAsync
        return -1;
    }

    // ── NEW: Step 1 of async AI path ──────────────────────────────────────
    //
    // Called by generateQuestion.jsp on the HTTP thread using the caller's
    // connection. Does only fast DB work: resolve/create the topic row and
    // clear stale questions + cache. Returns the tid (or -1 on failure).
    // The caller releases the connection immediately after this returns.
    //
    public static int prepareTopicForAI(Connection conn, String topic) throws SQLException {
        int tid = getTopicId(conn, topic);

        if (tid != -1) {
            // Topic exists — wipe old AI questions and invalidate cache
            clearExistingQuestions(conn, tid);
            QuestionCache.invalidate(topic, tid);
        } else {
            // New topic — create it
            tid = createNewTopic(conn, topic);
        }

        return tid;
    }

    // ── NEW: Step 2 of async AI path ──────────────────────────────────────
    //
    // Called by JobStore's background thread. No connection parameter —
    // acquires its own connection only during the INSERT, after Gemini
    // has already responded. Returns true on success.
    //
    public static boolean fetchAIQuestionsAsync(String topic, int tid) {
        try {
            logger.info("[AIUtils] Starting async AI generation for topic: " + topic);
            String prompt = String.format(PROMPT_TEMPLATE, topic);

            // ── Step A: Call Gemini — no DB connection held ───────────────
            Future<String> future = executor.submit(() ->
                    client.models.generateContent(model, prompt, null).text()
            );

            String raw;
            try {
                raw = future.get(AI_TIMEOUT_SECONDS, TimeUnit.SECONDS);
                logger.info("[AIUtils] Gemini responded for '" + topic + "'");
            } catch (TimeoutException e) {
                future.cancel(true);
                logger.warning("[AIUtils] Gemini timed out after " + AI_TIMEOUT_SECONDS + "s");
                return false;
            }

            // ── Step B: Parse ─────────────────────────────────────────────
            List<Question> questions = parse(raw);
            if (questions.isEmpty()) {
                logger.warning("[AIUtils] Parser returned 0 questions for: " + topic);
                logger.warning("[AIUtils] Raw response: " + raw);
                return false;
            }

            // ── Step C: Insert — acquire a fresh connection NOW ───────────
            Connection insertConn = null;
            try {
                insertConn = DBConnectionPool.getConnection();
                String sql = "INSERT INTO questions (qno, qtext, qopts, qans, tid) VALUES (?, ?, ?, ?, ?)";
                try (PreparedStatement ps = insertConn.prepareStatement(sql)) {
                    for (Question q : questions) {
                        ps.setInt(1, q.number);
                        ps.setString(2, q.question);
                        ps.setArray(3, insertConn.createArrayOf("text", q.options.toArray()));
                        ps.setString(4, q.answer);
                        ps.setInt(5, tid);
                        ps.addBatch();
                    }
                    ps.executeBatch();
                }
                logger.info("[AIUtils] Inserted " + questions.size() + " questions for tid=" + tid);
                return true;

            } finally {
                if (insertConn != null) {
                    try {
                        DBConnectionPool.releaseConnection(insertConn);
                    } catch (Exception e) {
                        logger.warning("[AIUtils] Failed to release insert connection: " + e.getMessage());
                    }
                }
            }

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            logger.warning("[AIUtils] AI generation interrupted for: " + topic);
            return false;
        } catch (ExecutionException e) {
            logger.log(Level.SEVERE, "[AIUtils] Gemini execution failed for: " + topic, e.getCause());
            return false;
        } catch (Exception e) {
            logger.log(Level.SEVERE, "[AIUtils] Unexpected failure in fetchAIQuestionsAsync", e);
            return false;
        }
    }

    // ── DB helpers ────────────────────────────────────────────────────────

    private static int getTopicId(Connection conn, String topic) throws SQLException {
        String sql = "SELECT tid FROM topics WHERE tname ILIKE ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, topic);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("tid");
        }
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, "%" + topic + "%");
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt("tid") : -1;
        }
    }

    private static void clearExistingQuestions(Connection conn, int tid) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement("DELETE FROM questions WHERE tid = ?")) {
            ps.setInt(1, tid);
            ps.executeUpdate();
        }
    }

    private static int createNewTopic(Connection conn, String topic) throws SQLException {
        try (PreparedStatement ps = conn.prepareStatement(
                "INSERT INTO topics (tname) VALUES (?) RETURNING tid")) {
            ps.setString(1, topic);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : -1;
        }
    }

    // ── Parser ────────────────────────────────────────────────────────────

    private static List<Question> parse(String rawText) {
        List<Question> list = new ArrayList<>();

        String cleaned = rawText
                .replace("**", "")
                .replace("```", "")
                .replace("\r\n", "\n")
                .replace("\r", "\n");

        Matcher m = QUESTION_PATTERN.matcher(cleaned);
        while (m.find()) {
            list.add(new Question(
                    Integer.parseInt(m.group(1)),
                    m.group(2).trim(),
                    List.of(
                            m.group(3).trim(),
                            m.group(4).trim(),
                            m.group(5).trim(),
                            m.group(6).trim()
                    ),
                    m.group(7).toUpperCase()
            ));
        }
        return list;
    }

    // ── Inner model ───────────────────────────────────────────────────────

    private static class Question {
        int number;
        String question;
        List<String> options;
        String answer;

        Question(int n, String q, List<String> o, String a) {
            this.number   = n;
            this.question = q;
            this.options  = o;
            this.answer   = a;
        }
    }
}