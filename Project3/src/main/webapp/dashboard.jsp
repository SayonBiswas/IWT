<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Student Dashboard</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <%@ include file="navbar.jsp" %>
    <div class="page-shell" style="padding-top: 2rem;">
      <div class="container">
        <h1>Welcome to Your Dashboard</h1>
        
        <div class="box-container">
            <div class="box">
                <h2>Take a Test</h2>
                <p>Generate fresh questions using AI based on any topic of your choice.</p>
                <a href="setup.jsp" class="btn">Start New Test</a>
            </div>

            <div class="box">
                <h2>Quick Stats</h2>
                <%
                    int totalExams = 0;
                    String latestSummary = "No exams yet";
                    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                        String cnt = "SELECT COUNT(*) AS cnt FROM user_results WHERE username = ?";
                        PreparedStatement pcs = conn.prepareStatement(cnt);
                        pcs.setString(1, (String)session.getAttribute("username"));
                        ResultSet rcs = pcs.executeQuery();
                        if (rcs.next()) totalExams = rcs.getInt("cnt");

                        String last = "SELECT score, total_questions, test_date, topic FROM user_results WHERE username = ? ORDER BY test_date DESC LIMIT 1";
                        PreparedStatement pls = conn.prepareStatement(last);
                        pls.setString(1, (String)session.getAttribute("username"));
                        ResultSet rls = pls.executeQuery();
                        if (rls.next()) {
                            latestSummary = "Latest: " + rls.getInt("score") + " / " + rls.getInt("total_questions") + " (" + rls.getTimestamp("test_date") + ")";
                        }
                    } catch (Exception e) {
                        latestSummary = "Error loading stats";
                    }
                %>
                <p>Exams completed: <strong><%= totalExams %></strong></p>
                <p><%= latestSummary %></p>
                <a href="exam_history.jsp" class="btn">View My Records</a>
            </div>
        </div>
      </div>
    </div>
</body>
</html>