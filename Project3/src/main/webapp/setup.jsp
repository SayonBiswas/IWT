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
                            <input type="radio" name="source" value="ai_generated">
                            <span>AI Generated</span>
                        </label>
                    </div>
                    <p style="font-size:0.8rem; color:var(--ink-muted); margin-top:0.5rem;">
                        * Internal database fetches instantly. AI generation may take 10–15 seconds.
                    </p>
                </div>

                <!-- DATABASE: dropdown of real topic names from DB -->
                <div class="form-group" id="db-topic-group">
                    <label>Select Topic</label>
                    <select name="topic" id="topic_db">
                        <option value="">-- Select a topic --</option>
                        <%
                            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                                PreparedStatement ps = conn.prepareStatement(
                                    "SELECT tname FROM topics ORDER BY tname DESC");
                                ResultSet rs = ps.executeQuery();
                                while (rs.next()) {
                        %>
                            <option value="<%= rs.getString("tname") %>">
                                <%= rs.getString("tname") %>
                            </option>
                        <%
                                }
                            } catch (Exception e) {
                                getServletContext().log("[setup.jsp] Failed to load topics", e);
                            }
                        %>
                    </select>
                </div>

                <!-- AI: free-text input, hidden by default -->
                <div class="form-group" id="ai-topic-group" style="display:none;">
                    <label>Exam Topic</label>
                    <input type="text" name="topic" id="topic_ai"
                           placeholder="e.g., C++, Java, Python..."
                           maxlength="100" disabled>
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
        const radios  = document.querySelectorAll('input[name="source"]');
        const dbGroup = document.getElementById('db-topic-group');
        const aiGroup = document.getElementById('ai-topic-group');
        const form    = document.getElementById('setupForm');
        const dbSel   = document.getElementById('topic_db');
        const aiInp   = document.getElementById('topic_ai');

        function toggleTopicInput() {
            const isDB = document.querySelector('input[name="source"]:checked').value === 'database';
            dbGroup.style.display = isDB ? 'block' : 'none';
            aiGroup.style.display = isDB ? 'none'  : 'block';
            dbSel.disabled = !isDB;   // only the visible one submits
            aiInp.disabled =  isDB;
        }

        radios.forEach(r => r.addEventListener('change', toggleTopicInput));
        toggleTopicInput();

        form.addEventListener('submit', function (e) {
            const isDB = document.querySelector('input[name="source"]:checked').value === 'database';
            const val  = isDB ? dbSel.value : aiInp.value.trim();
            if (!val) {
                e.preventDefault();
                alert(isDB ? 'Please select a topic.' : 'Please enter a topic.');
            }
            // Show loading state on button
            const btn = document.querySelector('button[type="submit"]');
            const isAI = document.querySelector('input[name="source"]:checked').value === 'ai_generated';
            if (isAI) {
                btn.disabled = true;
                btn.textContent = '⏳ Generating AI Questions... Please wait';
            }
        });
    })();
    </script>
</body>
</html>