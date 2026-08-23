<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.DBConnectionPool, java.sql.*" %>
<%
    if (session.getAttribute("username") == null) { response.sendRedirect("login.jsp"); return; }
    String topic = (String) session.getAttribute("currentTopic");
    Integer totalRequested = (Integer) session.getAttribute("totalQuestions");
    if (topic == null) { response.sendRedirect("setup.jsp"); return; }

    int score = 0; int questionsCounted = 0;
    java.util.List<Integer> qids = new java.util.ArrayList<>();
    java.util.Enumeration<String> params = request.getParameterNames();
    while (params.hasMoreElements()) {
        String p = params.nextElement();
        if (p.startsWith("q")) {
            try { qids.add(Integer.parseInt(p.substring(1))); } catch (NumberFormatException ignored) {}
        }
    }
    if (qids.isEmpty()) { response.sendRedirect("setup.jsp"); return; }

    String inClause = qids.stream().map(i -> "?").collect(java.util.stream.Collectors.joining(","));
    java.util.List<java.util.Map<String, Object>> details = new java.util.ArrayList<>();
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    try {
        conn = DBConnectionPool.getConnection();
        String sql = "SELECT qid, qtext, qopts, qans FROM questions WHERE qid IN (" + inClause + ")";
        ps = conn.prepareStatement(sql);
        int idx = 1; for (Integer id : qids) ps.setInt(idx++, id);
        rs = ps.executeQuery();
        
        java.util.Map<Integer, java.util.Map<String, Object>> map = new java.util.HashMap<>();
        while (rs.next()) {
            java.util.Map<String, Object> m = new java.util.HashMap<>();
            m.put("qid", rs.getInt("qid"));
            m.put("qtext", rs.getString("qtext"));
            m.put("opts", (String[]) rs.getArray("qopts").getArray());
            m.put("qans", rs.getString("qans"));
            map.put(rs.getInt("qid"), m);
        }

        for (Integer qid : qids) {
            java.util.Map<String, Object> m = map.get(qid);
            if (m == null) continue;
            String correctAnswer = (String) m.get("qans");
            String userResponse = request.getParameter("q" + qid);
            if (userResponse != null) {
                questionsCounted++;
                if (userResponse.trim().equalsIgnoreCase(correctAnswer.trim())) score++;
            }
            m.put("user", userResponse);
            details.add(m);
        }
        try {
            String insert = "INSERT INTO user_results(username, topic, score, total_questions, test_date) VALUES (?, ?, ?, ?, NOW())";
            PreparedStatement ins = conn.prepareStatement(insert);
            ins.setString(1, (String) session.getAttribute("username"));
            ins.setString(2, topic);
            ins.setInt(3, score);
            ins.setInt(4, (totalRequested != null) ? totalRequested : questionsCounted);
            ins.executeUpdate();
        } catch (Exception ie) {
            getServletContext().log("[result.jsp] Could not save result", ie);
            out.print("<div class='error'>Could not save your result. Please contact support.</div>");
        }
    } catch (Exception e) {
        getServletContext().log("[result.jsp] Score calculation failed", e);
        out.print("<div class='error'>Could not calculate your score. Please try again.</div>");
    } finally {
        try {
            if (rs != null) rs.close();
            if (ps != null) ps.close();
        } catch (Exception e) {
            getServletContext().log("[result.jsp] Failed to close statement/result", e);
        }
        if (conn != null) {
            try {
                DBConnectionPool.releaseConnection(conn);
            } catch (Exception e) {
                getServletContext().log("[result.jsp] Failed to release connection", e);
            }
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ExamHub - Exam Result - <%= topic %></title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
    <script src="https://cdn.jsdelivr.net/npm/canvas-confetti@1.6.0/dist/confetti.browser.min.js"></script>
</head>
<body>
    <div class="page-shell">
      <div class="result-container">
        <h1 style="margin-bottom: 1rem;">Examination Complete!</h1>
        <p style="margin-bottom: 1.5rem;">Topic: <strong><%= topic %></strong></p>

        <!-- Replaced hardcoded #38bdf8 with var(--sky) -->
        <h2 style="font-size: 2.2rem; margin-bottom: 1rem; color: var(--sky);">
            Score: <%= score %> / <%= (totalRequested != null ? totalRequested : questionsCounted) %>
        </h2>
        <p>Congratulations, <strong><%= session.getAttribute("username") %></strong>! Your results have been recorded.</p>

        <h3 style="margin-top: 2rem; text-align: left; margin-bottom: 1rem;">Question-by-question breakdown</h3>
        <div class="table-wrap">
            <table>
                <thead>
                    <tr><th>#</th><th>Question</th><th>Your Answer</th><th>Correct Answer</th><th>Result</th></tr>
                </thead>
                <tbody>
                <%
                    int qnum = 1;
                    for (java.util.Map<String, Object> m : details) {
                        String[] opts = (String[]) m.get("opts");
                        String userA = (String) m.get("user");
                        String correct = (String) m.get("qans");
                        String userText = "-"; String correctText = "-";

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
                    <td><strong><%= m.get("qtext") %></strong></td>
                    <td><%= userText %></td>
                    <!-- Replaced hardcoded #34d399 with var(--green) -->
                    <td style="color: var(--green); font-weight: 500;"><%= correctText %></td>
                    <td style="font-weight: 600;"><%= (ok ? "✅ Correct" : "❌ Wrong") %></td>
                </tr>
                <% } %>
                </tbody>
            </table>
        </div>
        <br>
        <a href="setup.jsp" class="btn-home">Take Another Exam</a>
      </div>
    </div>
    <script>
        <% if (score >= (totalRequested / 2.0)) { %>
            confetti({ particleCount: 150, spread: 70, origin: { y: 0.6 } });
        <% } %>
    </script>
</body>
</html>