package com.exam.util;

import com.google.genai.Client;
import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.util.regex.*;
import java.util.concurrent.*;

public class AIUtils {

    private static final Logger logger = Logger.getLogger(AIUtils.class.getName());
    private static final String APIKey = System.getenv("GEMINI_API_KEY");
    private static final String model  = "gemini-1.5-flash"; // Stable, fast model with good performance
    
    // ── Timeout configuration ─────────────────────────────────────────────
    private static final int AI_TIMEOUT_SECONDS = 60; // 60 seconds timeout for AI calls (increased for reliability)
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    // ── Static client — created once, reused on every request ─────────────
    private static final Client client = Client.builder()
            .apiKey(System.getenv("GEMINI_API_KEY"))
            .build();

    // ── Regex WITHOUT DOTALL — no catastrophic backtracking ───────────────
    private static final Pattern QUESTION_PATTERN = Pattern.compile(
            "(?im)^\\s*(\\d+)[.)]+\\s*(.+)\\r?\\n" +   // question number + text
                    "\\s*A[.)]+\\s*(.+)\\r?\\n" +               // option A
                    "\\s*B[.)]+\\s*(.+)\\r?\\n" +               // option B
                    "\\s*C[.)]+\\s*(.+)\\r?\\n" +               // option C
                    "\\s*D[.)]+\\s*(.+)\\r?\\n" +               // option D
                    "\\s*(?:\\*{0,2})\\s*Answer\\s*[:\\s]+(?:\\*{0,2})\\s*([A-D])"  // Answer: A
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

    // ── Public entry point ─────────────────────────────────────────────────
    public static int prepareQuestions(Connection conn, String topic, String source) throws SQLException {
        int tid = getTopicId(conn, topic);

        if (source.equals("database")) {
            // Check if topic exists and has questions
            if (tid == -1) {
                return -1; // Topic not found
            }
            // Verify that the topic has questions in the database
            try (PreparedStatement check = conn.prepareStatement(
                    "SELECT COUNT(*) FROM questions WHERE tid = ?")) {
                check.setInt(1, tid);
                ResultSet rs = check.executeQuery();
                rs.next();
                if (rs.getInt(1) == 0) {
                    return -1; // Topic exists but has no questions
                }
            }
            return tid;
        } else if (source.equals("ai")) {
            if (tid != -1) {
                clearExistingQuestions(conn, tid);
            } else {
                tid = createNewTopic(conn, topic);
            }
            return fetchAIQuestions(conn, topic, tid) ? tid : -1;
        } else {
            return -1; // Unknown source
        }
    }

    // ── DB helpers ─────────────────────────────────────────────────────────
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

    // ── AI fetch ───────────────────────────────────────────────────────────
    private static boolean fetchAIQuestions(Connection conn, String topic, int tid) {
        try {
            logger.info("[AIUtils] Starting AI question generation for topic: " + topic + " using model: " + model);
            String prompt = String.format(PROMPT_TEMPLATE, topic);
            
            // Submit AI call to executor with timeout
            Future<String> future = executor.submit(() -> {
                return client.models.generateContent(model, prompt, null).text();
            });
            
            String raw;
            try {
                raw = future.get(AI_TIMEOUT_SECONDS, TimeUnit.SECONDS);
                logger.info("[AIUtils] Raw Gemini response for '" + topic + "':\n" + raw);
            } catch (TimeoutException e) {
                future.cancel(true); // Interrupt the AI call if still running
                logger.warning("[AIUtils] AI API call timed out after " + AI_TIMEOUT_SECONDS + " seconds for topic: " + topic);
                logger.warning("[AIUtils] Consider checking your API key, network connection, or trying a different topic.");
                return false;
            }

            List<Question> questions = parse(raw);

            if (questions.isEmpty()) {
                logger.warning("[AIUtils] Parser returned 0 questions for: " + topic);
                logger.warning("[AIUtils] Raw response that failed parsing: " + raw);
                return false;
            }

            String sql = "INSERT INTO questions (qno, qtext, qopts, qans, tid) VALUES (?, ?, ?, ?, ?)";
            try (PreparedStatement ps = conn.prepareStatement(sql)) {
                for (Question q : questions) {
                    ps.setInt(1, q.number);
                    ps.setString(2, q.question);
                    ps.setArray(3, conn.createArrayOf("text", q.options.toArray()));
                    ps.setString(4, q.answer);
                    ps.setInt(5, tid);
                    ps.addBatch();
                }
                ps.executeBatch();
            }

            logger.info("[AIUtils] Inserted " + questions.size() + " questions for tid=" + tid);
            return true;

        } catch (InterruptedException e) {
            Thread.currentThread().interrupt(); // Restore interrupt status
            logger.warning("[AIUtils] AI question generation interrupted for topic: " + topic);
            return false;
        } catch (ExecutionException e) {
            logger.log(Level.SEVERE, "[AIUtils] AI question generation execution failed for topic: " + topic, e);
            logger.log(Level.SEVERE, "[AIUtils] Execution exception cause: " + e.getCause());
            return false;
        } catch (Exception e) {
            logger.log(Level.SEVERE, "[AIUtils] AI question generation failed", e);
            return false;
        }
    }

    // ── Parser ─────────────────────────────────────────────────────────────
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

    // ── Inner model ────────────────────────────────────────────────────────
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