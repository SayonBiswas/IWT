<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.AIUtils, com.exam.util.DBConnectionPool, java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String topic  = request.getParameter("topic");
    String count  = request.getParameter("qCount");
    String source = request.getParameter("source");

    if (topic == null || topic.trim().isEmpty() || count == null || source == null) {
        response.sendRedirect("setup.jsp");
        return;
    }

    topic = topic.trim();
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generating Questions...</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <style>
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <!-- Loading overlay shown immediately -->
    <div id="loadingOverlay" style="
        position: fixed;
        inset: 0;
        z-index: 999;
        background: var(--bg-page);
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1.5rem;
    ">
        <div style="
            width: 48px; height: 48px;
            border: 4px solid var(--border);
            border-top-color: var(--accent-light);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        "></div>
        <div style="text-align: center;">
            <p style="font-size: 1rem; font-weight: 600; color: var(--ink); margin: 0 0 0.4rem 0;">
                <% if (source.equals("ai")) { %>
                    Generating AI Questions...
                <% } else { %>
                    Loading Questions...
                <% } %>
            </p>
            <p style="font-size: 0.85rem; color: var(--ink-muted); margin: 0;">
                Preparing exam for <strong style="color: var(--accent-light);"><%= topic %></strong>
            </p>
        </div>
    </div>

    <%
    Connection conn = null;
    try {
        conn = DBConnectionPool.getConnection();
        int tid = AIUtils.prepareQuestions(conn, topic, source);

        if (tid == -1) {
            String errorMsg;
            if (source.equals("ai")) {
                errorMsg = "AI question generation timed out or failed. " +
                          "This may be due to slow API response or network issues. Please try again or use Database questions.";
            } else {
                errorMsg = "No questions found for \"" + topic + "\" in the database. " +
                          "The topic may not exist or has no questions yet. Please check the topic name or use AI Generated.";
            }
    %>
            <script>
                setTimeout(function() {
                    alert('<%= errorMsg %>');
                    window.location='setup.jsp';
                }, 100);
            </script>
    <%
            return;
        }

        session.setAttribute("currentTid", tid);
        session.setAttribute("currentTopic", topic);
        session.setAttribute("totalQuestions", Integer.parseInt(count));
    %>
        <script>
            window.location='exam.jsp';
        </script>
    <%
    } catch (Exception e) {
        getServletContext().log("[generateQuestion.jsp] Failed to prepare questions", e);
    %>
        <script>
            setTimeout(function() {
                alert('Something went wrong. Please try again.');
                window.location='setup.jsp';
            }, 100);
        </script>
    <%
    } finally {
        if (conn != null) {
            try {
                DBConnectionPool.releaseConnection(conn);
            } catch (Exception e) {
                // Ignore cleanup errors
            }
        }
    }
    %>
</body>
</html>