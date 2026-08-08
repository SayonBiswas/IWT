package com.exam.util;

import com.google.genai.Client;
import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.util.regex.*;

public class AIUtils {

    private static final Logger logger = Logger.getLogger(AIUtils.class.getName());
    private static final String APIKey = System.getenv("GEMINI_API_KEY");
    private static final String model  = "gemini-3-flash-preview";

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
            return tid;
        } else {
            if (tid != -1) {
                clearExistingQuestions(conn, tid);
            } else {
                tid = createNewTopic(conn, topic);
            }
            return fetchAIQuestions(conn, topic, tid) ? tid : -1;
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
            String prompt = String.format(PROMPT_TEMPLATE, topic);
            String raw    = client.models.generateContent(model, prompt, null).text();

            logger.info("[AIUtils] Raw Gemini response for '" + topic + "':\n" + raw);

            List<Question> questions = parse(raw);

            if (questions.isEmpty()) {
                logger.warning("[AIUtils] Parser returned 0 questions for: " + topic);
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