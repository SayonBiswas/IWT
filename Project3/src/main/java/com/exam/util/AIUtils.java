package com.exam.util;

import com.google.genai.Client;
import java.sql.*;
import java.util.*;
import java.util.regex.*;

public class AIUtils {
    private static final String APIKey = "YOUR_API_KEY_HERE";
    private static final String model = "Your Model Name Here";
    private static final String pattern = "(?i)(\\d+)\\.\\s*(.*?)\\s*\\n\\s*A\\)\\s*(.*?)\\s*\\n\\s*B\\)\\s*(.*?)\\s*\\n\\s*C\\)\\s*(.*?)\\s*\\n\\s*D\\)\\s*(.*?)\\s*\\n\\s*Answer:\\s*([A-D])";

    public static boolean prepareQuestions(Connection conn, String topic, String source) throws SQLException {
        int tid = getTopicId(conn, topic);

        if (source.equals("old")) {
            // If user wants old questions, just check if they exist
            return (tid != -1); 
        } else {
            // If user wants NEW questions, we clear old ones and call AI
            if (tid != -1) {
                clearExistingQuestions(conn, tid);
            } else {
                tid = createNewTopic(conn, topic);
            }
            return fetchAIQuestions(conn, topic, tid);
        }
    }

    private static int getTopicId(Connection conn, String topic) throws SQLException {
        String sql = "SELECT tid FROM topics WHERE tname ILIKE ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, topic);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt("tid") : -1;
        }
    }

    private static void clearExistingQuestions(Connection conn, int tid) throws SQLException {
        String sql = "DELETE FROM questions WHERE tid = ?";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, tid);
            ps.executeUpdate();
        }
    }

    private static int createNewTopic(Connection conn, String topic) throws SQLException {
        String sql = "INSERT INTO topics (tname) VALUES (?) RETURNING tid";
        try (PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, topic);
            ResultSet rs = ps.executeQuery();
            return rs.next() ? rs.getInt(1) : -1;
        }
    }

    private static boolean fetchAIQuestions(Connection conn, String topic, int tid) {
        Client client = Client.builder().apiKey(APIKey).build();
        String prompt = "Generate exactly 10 MCQs on " + topic + ". Format: 1. Q\\nA) O1\\nB) O2\\nC) O3\\nD) O4\\nAnswer: A";
        
        try {
            String raw = client.models.generateContent(model, prompt, null).text();
            List<Question> questions = parse(raw);
            
            if (questions.isEmpty()) return false;

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
            return true;
        } catch (Exception e) {
            e.printStackTrace();
            return false;
        }
    }

    private static List<Question> parse(String rawText) {
        List<Question> list = new ArrayList<>();
        Matcher m = Pattern.compile(pattern, Pattern.DOTALL).matcher(rawText.replace("\\n", "\n"));
        while (m.find()) {
            list.add(new Question(Integer.parseInt(m.group(1)), m.group(2).trim(), 
                List.of(m.group(3).trim(), m.group(4).trim(), m.group(5).trim(), m.group(6).trim()), 
                m.group(7).toUpperCase()));
        }
        return list;
    }

    private static class Question {
        int number; String question; List<String> options; String answer;
        Question(int n, String q, List<String> o, String a) {
            this.number = n; this.question = q; this.options = o; this.answer = a;
        }
    }
}