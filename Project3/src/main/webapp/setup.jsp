<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, com.exam.util.DBConnectionPool" %>
<%@ include file="db_config.jsp" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configure Exam</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
        <div class="setup-card">
            <h2 style="color: var(--amber); text-align: center;">Configure New Exam</h2>
            <p style="text-align: center; margin-bottom: 2rem;">Select your topic, question limit, and source.</p>

            <form id="setupForm" action="generateQuestion.jsp" method="POST">
                <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">

                <!-- SOURCE SELECTOR — shown first so topic input reacts immediately -->
                <div class="form-group">
                    <label>Select Question Source</label>
                    <div class="radio-group">
                        <label class="option-container" style="flex:1; text-align:center; justify-content:center;">
                            <input type="radio" name="source" value="database" checked>
                            <span>Internal Database</span>
                        </label>
                        <label class="option-container" style="flex:1; text-align:center; justify-content:center;">
                            <input type="radio" name="source" value="ai">
                            <span>AI Generated</span>
                        </label>
                    </div>
                    <p style="font-size:0.8rem; color:var(--ink-muted); margin-top:0.5rem;">
                        * Internal database fetches instantly. AI generation may take 15–30 seconds.
                    </p>
                </div>

                <!-- Topic input - used for both database and AI sources -->
                <div class="form-group">
                    <label>Exam Topic</label>
                    <input type="text" name="topic" id="topic_input"
                           placeholder="e.g., C++, Java, Python, Data Structures..."
                           maxlength="100" required>
                    <p style="font-size:0.8rem; color:var(--ink-muted); margin-top:0.5rem;">
                        <% Connection conn = null;
                           try {
                               conn = DBConnectionPool.getConnection();
                               PreparedStatement ps = conn.prepareStatement(
                                   "SELECT COUNT(*) FROM topics");
                               ResultSet rs = ps.executeQuery();
                               rs.next();
                               int topicCount = rs.getInt(1);
                               rs.close();
                               ps.close();
                           %>
                               * Database has <%= topicCount %> topics available. Type any topic name to search.
                           <%
                               } catch (Exception e) {
                                   getServletContext().log("[setup.jsp] Failed to load topic count", e);
                           %>
                               * Database topics available.
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
                    </p>
                </div>

                <!-- NUMBER OF QUESTIONS -->
                <div class="form-group">
                    <label>Number of Questions</label>
                    <input type="number" name="qCount" min="1" max="50" value="10" required>
                </div>

                <button type="submit" class="btn-submit" style="margin-top:2rem;">
                    Start Examination
                </button>
            </form>
        </div>
    </div>

    <script>
    (function () {
        const form = document.getElementById('setupForm');
        const topicInput = document.getElementById('topic_input');

        form.addEventListener('submit', function (e) {
            const topicValue = topicInput.value.trim();
            if (!topicValue) {
                e.preventDefault();
                alert('Please enter a topic.');
                return;
            }
            
            // Show loading state on button immediately
            const btn = document.querySelector('button[type="submit"]');
            const sourceValue = document.querySelector('input[name="source"]:checked').value;
            const isAI = sourceValue === 'ai';
            
            btn.disabled = true;
            if (isAI) {
                btn.innerHTML = '<span class="btn-spinner"></span> Generating AI Questions... Please wait';
            } else {
                btn.innerHTML = '<span class="btn-spinner"></span> Loading Questions...';
            }
        });
    })();
    </script>
</body>
</html>