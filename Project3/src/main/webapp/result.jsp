<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="db_config.jsp" %>
<%
    // 1. Session Security Check
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String topic = (String) session.getAttribute("currentTopic");
    Integer totalRequested = (Integer) session.getAttribute("totalQuestions");

    // Redirect if session expired or setup was skipped
    if (topic == null) {
        response.sendRedirect("setup.jsp");
        return;
    }

    int score = 0;
    int questionsCounted = 0;

    // Collect question IDs from submitted parameters (parameters are named like q<qid>)
    java.util.List<Integer> qids = new java.util.ArrayList<>();
    java.util.Enumeration<String> params = request.getParameterNames();
    while (params.hasMoreElements()) {
        String p = params.nextElement();
        if (p.startsWith("q")) {
            try {
                int id = Integer.parseInt(p.substring(1));
                qids.add(id);
            } catch (NumberFormatException ignored) {}
        }
    }

    // If no q params found, redirect back to setup
    if (qids.isEmpty()) {
        response.sendRedirect("setup.jsp");
        return;
    }

    // Build a parameterized IN-clause
    String inClause = qids.stream().map(i -> "?").collect(java.util.stream.Collectors.joining(","));

    // We'll collect per-question details to show on the result page
    java.util.List<java.util.Map<String, Object>> details = new java.util.ArrayList<>();

    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
        String sql = "SELECT qid, qtext, qopts, qans FROM questions WHERE qid IN (" + inClause + ")";
        PreparedStatement ps = conn.prepareStatement(sql);
        int idx = 1;
        for (Integer id : qids) ps.setInt(idx++, id);
        ResultSet rs = ps.executeQuery();

        // Map results by qid so we can preserve the order submitted
        java.util.Map<Integer, java.util.Map<String, Object>> map = new java.util.HashMap<>();
        while (rs.next()) {
            int qId = rs.getInt("qid");
            String qtext = rs.getString("qtext");
            String[] opts = (String[]) rs.getArray("qopts").getArray();
            String correctAnswer = rs.getString("qans");
            java.util.Map<String, Object> m = new java.util.HashMap<>();
            m.put("qid", qId);
            m.put("qtext", qtext);
            m.put("opts", opts);
            m.put("qans", correctAnswer);
            map.put(qId, m);
        }

        for (Integer qid : qids) {
            java.util.Map<String, Object> m = map.get(qid);
            if (m == null) continue; // skip if question was not found
            String correctAnswer = (String) m.get("qans");
            String userResponse = request.getParameter("q" + qid);
            if (userResponse != null) {
                questionsCounted++;
                if (userResponse.trim().equalsIgnoreCase(correctAnswer.trim())) {
                    score++;
                }
            }
            m.put("user", userResponse);
            details.add(m);
        }

        // Record the summary result in user_results so exam_history and dashboard can show it
        try {
            String insert = "INSERT INTO user_results(username, topic, score, total_questions, test_date) VALUES (?, ?, ?, ?, NOW())";
            PreparedStatement ins = conn.prepareStatement(insert);
            ins.setString(1, (String) session.getAttribute("username"));
            ins.setString(2, topic);
            ins.setInt(3, score);
            ins.setInt(4, (totalRequested != null) ? totalRequested : questionsCounted);
            ins.executeUpdate();
        } catch (Exception ie) {
            // Non-fatal: show a message but continue to display details
            out.print("<div style='color:orange;'>Warning: could not save result: " + ie.getMessage() + "</div>");
        }

    } catch (Exception e) {
        out.print("<div style='color:red;'>Error calculating score: " + e.getMessage() + "</div>");
        e.printStackTrace();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Exam Result - <%= topic %></title>
	<link rel="stylesheet" href="style.css">
    <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
</head>
<body>
    <div class="page-shell">
      <div class="result-container">
        <h1>Examination Complete!</h1>
        <p>Topic: <strong><%= topic %></strong></p>
        
        <div class="score-circle">
            <%= score %> / <%= (totalRequested != null ? totalRequested : questionsCounted) %>
            <div class="score-label">Correct</div>
        </div>

        <p>Congratulations, <strong><%= session.getAttribute("username") %></strong>! Your results have been recorded.</p>

        <h3>Question-by-question breakdown</h3>
        <table class="results-table">
            <tr>
                <th>#</th>
                <th>Question</th>
                <th>Your Answer</th>
                <th>Correct Answer</th>
                <th>Result</th>
            </tr>
            <%
                int qnum = 1;
                for (java.util.Map<String, Object> m : details) {
                    int qid = (Integer) m.get("qid");
                    String qtext = (String) m.get("qtext");
                    String[] opts = (String[]) m.get("opts");
                    String correct = (String) m.get("qans");
                    String userA = (String) m.get("user");
                    String userText = "-";
                    String correctText = "-";
                    if (userA != null) {
                        int ui = "ABCD".indexOf(userA.toUpperCase());
                        if (ui >= 0 && ui < opts.length) userText = opts[ui];
                    }
                    if (correct != null) {
                        int ci = "ABCD".indexOf(correct.toUpperCase());
                        if (ci >= 0 && ci < opts.length) correctText = opts[ci];
                    }
                    boolean ok = (userA != null && correct != null && userA.trim().equalsIgnoreCase(correct.trim()));
            %>
            <tr>
                <td><%= qnum++ %></td>
                <td><%= qtext %></td>
                <td><%= userText %></td>
                <td><%= correctText %></td>
                <td><%= (ok ? "✅ Correct" : "❌ Wrong") %></td>
            </tr>
            <%
                }
            %>
        </table>

        <br>
        <a href="setup.jsp" class="btn-home">Take Another Exam</a>
    </div>

    <script>
        // Trigger confetti if they got at least 50% correct
        <% if (score >= (totalRequested / 2.0)) { %>
            confetti({
                particleCount: 150,
                spread: 70,
                origin: { y: 0.6 }
            });
        <% } %>
    </script>
      </div>
    </div>
</body>
</html>