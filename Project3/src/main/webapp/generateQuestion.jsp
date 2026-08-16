<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.AIUtils, com.exam.util.DBConnectionPool, com.exam.util.JobStore, java.sql.*" %>
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

    // ── DATABASE path: fast, do it inline ────────────────────────────────
    if (source.equals("database")) {
        int tid = -1;
        String errorMsg = null;

        Connection conn = null;
        try {
            conn = DBConnectionPool.getConnection();
            tid  = AIUtils.prepareQuestions(conn, topic, source);
        } catch (Exception e) {
            errorMsg = "Something went wrong. Please try again.";
            getServletContext().log("[generateQuestion.jsp] DB error", e);
        } finally {
            // Release connection BEFORE writing any response
            if (conn != null) {
                try { DBConnectionPool.releaseConnection(conn); } catch (Exception ignored) {}
            }
        }

        if (errorMsg == null && tid != -1) {
            session.setAttribute("currentTid", tid);
            session.setAttribute("currentTopic", topic);
            session.setAttribute("totalQuestions", Integer.parseInt(count));
            response.sendRedirect("exam.jsp");
            return;
        }

        // DB failure — fall through to render error page below
        if (errorMsg == null) {
            errorMsg = "No questions found for \"" + topic + "\" in the database. " +
                       "The topic may not exist or has no questions yet. " +
                       "Please check the topic name or use AI Generated.";
        }
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
</head>
<body>
    <script>
        setTimeout(function () {
            alert('<%= errorMsg.replace("'", "\\'").replace("\n", " ") %>');
            window.location = 'setup.jsp';
        }, 50);
    </script>
</body>
</html>
<%
        return;
    }

    // ── AI path: kick off background job, redirect to loading page ────────
    //
    // 1. Do only the fast DB work (topic lookup / insert / cache invalidation)
    //    while holding a connection — this takes milliseconds.
    // 2. Start a background thread for the Gemini call (could take 15-60s).
    // 3. Store a jobId in the session and redirect immediately.
    //    The browser never waits for Gemini here.

    String jobId    = null;
    String jobError = null;

    Connection conn = null;
    try {
        conn = DBConnectionPool.getConnection();

        // Resolve or create the topic row — fast DB work only
        int tid = AIUtils.prepareTopicForAI(conn, topic);

        if (tid == -1) {
            jobError = "Failed to create or find topic in the database. Please try again.";
        } else {
            // Store count + topic in session now so loading.jsp can show them
            session.setAttribute("currentTopic", topic);
            session.setAttribute("totalQuestions", Integer.parseInt(count));
            // currentTid intentionally NOT set yet — set by the background job on success

            // Register the job and launch it; JobStore returns a unique jobId
            jobId = JobStore.startAIJob(topic, tid, session);
        }

    } catch (Exception e) {
        jobError = "Something went wrong starting AI generation. Please try again.";
        getServletContext().log("[generateQuestion.jsp] Failed to start AI job", e);
    } finally {
        // Connection released here — background thread acquires its own later
        if (conn != null) {
            try { DBConnectionPool.releaseConnection(conn); } catch (Exception ignored) {}
        }
    }

    if (jobError != null) {
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
</head>
<body>
    <script>
        setTimeout(function () {
            alert('<%= jobError.replace("'", "\\'") %>');
            window.location = 'setup.jsp';
        }, 50);
    </script>
</body>
</html>
<%
        return;
    }

    // Job started successfully — redirect to the loading/polling page
    response.sendRedirect("loading.jsp?jobId=" + jobId);
%>