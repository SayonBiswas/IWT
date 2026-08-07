package com.exam.util;

import com.google.genai.Client;
import java.sql.*;
import java.util.*;
import java.util.logging.*;
import java.util.regex.*;

public class AIUtils {

    private static final Logger logger = Logger.getLogger(AIUtils.class.getName());
    private static final String APIKey = System.getenv("GEMINI_API_KEY");

    // ── Fix 1: correct model name ──────────────────────────────────────────
    private static final String model = "gemini-3-flash-preview";

    // ── Fix 2: relaxed regex ───────────────────────────────────────────────
    // Handles: "A)" or "A." delimiters, "**Answer: A**" bold, trailing text after answer
    private static final String pattern =
            "(?i)(\\d+)[.)\\s]+([^\\n]+?)\\s*\\n" +          // question number + text
                    "\\s*A[.)]+\\s*([^\\n]+?)\\s*\\n" +               // option A
                    "\\s*B[.)]+\\s*([^\\n]+?)\\s*\\n" +               // option B
                    "\\s*C[.)]+\\s*([^\\n]+?)\\s*\\n" +               // option C
                    "\\s*D[.)]+\\s*([^\\n]+?)\\s*\\n" +               // option D
                    "\\s*\\**\\s*Answer[:\\s*]+\\**\\s*([A-D])";      // Answer: A (with optional ** markdown)

    // ── Fix 3: better prompt — strips markdown from Gemini response ────────
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
            return tid;  // -1 if topic not found in DB
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
        // exact match first
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, topic);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) return rs.getInt("tid");
        }
        // wildcard fallback
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
            Client client = Client.builder().apiKey(APIKey).build();
            String prompt = String.format(PROMPT_TEMPLATE, topic);
            String raw = client.models.generateContent(model, prompt, null).text();

            logger.info("[AIUtils] Raw Gemini response for topic '" + topic + "':\n" + raw);

            List<Question> questions = parse(raw);

            if (questions.isEmpty()) {
                logger.warning("[AIUtils] Parser returned 0 questions for topic: " + topic);
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

            logger.info("[AIUtils] Successfully inserted " + questions.size() + " questions for tid=" + tid);
            return true;

        } catch (Exception e) {
            // ── Fix 4: no printStackTrace — use logger ─────────────────
            logger.log(Level.SEVERE, "[AIUtils] Failed to fetch or store AI questions", e);
            return false;
        }
    }

    // ── Parser ─────────────────────────────────────────────────────────────
    private static List<Question> parse(String rawText) {
        List<Question> list = new ArrayList<>();

        // Strip common markdown artifacts Gemini sometimes adds
        String cleaned = rawText
                .replace("**", "")          // bold markers
                .replace("```", "")         // code fences
                .replace("\r\n", "\n")      // normalise line endings
                .replace("\r", "\n");

        Matcher m = Pattern.compile(pattern, Pattern.DOTALL).matcher(cleaned);
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
            this.number = n;
            this.question = q;
            this.options = o;
            this.answer = a;
        }
    }
}