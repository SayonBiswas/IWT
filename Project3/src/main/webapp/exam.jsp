<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.exam.util.DBConnectionPool, com.exam.util.QuestionCache" %>
<%@ include file="db_config.jsp" %>
<%
    System.out.println("[exam.jsp] === START EXAM PAGE ===");
    System.out.println("[exam.jsp] Session attributes: currentTopic=" + session.getAttribute("currentTopic") + ", totalQuestions=" + session.getAttribute("totalQuestions") + ", currentTid=" + session.getAttribute("currentTid"));
    
    Object topicObj = session.getAttribute("currentTopic");
    Object limitObj = session.getAttribute("totalQuestions");
    if (topicObj == null || limitObj == null) {
        System.out.println("[exam.jsp] MISSING SESSION ATTRS - topicObj=" + topicObj + ", limitObj=" + limitObj);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Session Error</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
</head>
<body>
    <div class="page-shell">
        <div class="setup-card">
            <h2 style="color: var(--red);">Session Error</h2>
            <p>Your session has expired or is missing required information. Please start over.</p>
            <p><strong>Debug info:</strong> topicObj=<%= topicObj %>, limitObj=<%= limitObj %></p>
            <a href="setup.jsp" class="btn-submit">Return to Setup</a>
        </div>
    </div>
</body>
</html>
<%
        return;
    }

    Integer tid = (Integer) session.getAttribute("currentTid");
    if (tid == null || tid == -1) {
        System.out.println("[exam.jsp] INVALID TID - tid=" + tid);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Topic Error</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
</head>
<body>
    <div class="page-shell">
        <div class="setup-card">
            <h2 style="color: var(--red);">Topic Not Ready</h2>
            <p>The topic ID is invalid or not set. This usually means the AI generation is still in progress or failed.</p>
            <p><strong>Debug info:</strong> tid=<%= tid %>, topic=<%= topicObj %></p>
            <a href="setup.jsp" class="btn-submit">Return to Setup</a>
        </div>
    </div>
</body>
</html>
<%
        return;
    }

    String topic = (String) topicObj;
    int limit    = (Integer) limitObj;
    System.out.println("[exam.jsp] Valid session - topic=" + topic + ", limit=" + limit + ", tid=" + tid);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Exam: <%= topic %></title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
    <style>
        /* FIX: spin keyframe must be in <head> so the overlay animation works
           on first paint. Previously it was in a <style> tag below the overlay
           div, which meant the browser rendered the overlay before it knew
           about the animation — causing a brief static spinner on slow pages. */
        @keyframes spin { to { transform: rotate(360deg); } }
    </style>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <!-- Loading overlay — shown immediately, hidden after questions render -->
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
                Preparing your exam…
            </p>
            <p style="font-size: 0.85rem; color: var(--ink-muted); margin: 0;">
                Loading questions for <strong style="color: var(--accent-light);"><%= topic %></strong>
            </p>
        </div>
    </div>

    <%
        // ── FIX: flush the overlay to the browser NOW, before the DB query ──
        // Without this, Tomcat buffers the whole response and the user sees
        // a blank white page for however long the DB query takes.
        // With this, the spinner appears instantly, then questions follow.
        response.setBufferSize(0);  // disable response buffering
        out.flush();                // push everything written so far to the browser
    %>

    <div class="page-shell">
      <div class="setup-card">

        <h2 style="color: var(--amber); text-align: center;">Examination in Progress</h2>
        <p style="text-align: center; margin-bottom: 2rem; font-size: 1.1rem;">
            Topic: <strong style="color: var(--ink);"><%= topic %></strong> |
            Questions: <strong style="color: var(--ink);"><%= limit %></strong>
        </p>

        <!-- Skeleton shown while Java fetches questions from DB -->
        <div id="skeletonLoader">
            <% for (int i = 0; i < Math.min(limit, 5); i++) { %>
                <div class="skeleton-card">
                    <div class="skeleton-text" style="width: 80%;"></div>
                    <div class="skeleton-text-sm"></div>
                    <div class="skeleton-option"></div>
                    <div class="skeleton-option"></div>
                    <div class="skeleton-option"></div>
                    <div class="skeleton-option"></div>
                </div>
            <% } %>
        </div>

        <!-- Actual form — hidden until window.onload swaps it in -->
        <form id="examForm" action="result.jsp" method="POST" style="display: none;">
            <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">
            <div id="questionsContainer">
            <%
                List<Map<String, Object>> cachedQuestions = QuestionCache.get(topic, tid);
                boolean useCache = (cachedQuestions != null);

                Connection conn  = null;
                PreparedStatement ps = null;
                ResultSet rs     = null;
                long startTime   = System.currentTimeMillis();

                try {
                    List<Map<String, Object>> questions;

                    if (useCache) {
                        questions = cachedQuestions;
                        System.out.println("[exam.jsp] Using cached questions for: " + topic);
                    } else {
                        conn = DBConnectionPool.getConnection();
                        System.out.println("[exam.jsp] Fetching questions from database for tid=" + tid + ", topic=" + topic);

                        String sql = "SELECT qid, qtext, qopts, qans FROM questions WHERE tid = ? ORDER BY random() LIMIT ?";
                        ps = conn.prepareStatement(sql);
                        ps.setInt(1, tid);
                        ps.setInt(2, Math.min(limit, 50));
                        rs = ps.executeQuery();
                        System.out.println("[exam.jsp] Database query executed successfully");

                        questions = new ArrayList<>();
                        while (rs.next()) {
                            Map<String, Object> question = new HashMap<>();
                            question.put("qid",   rs.getInt("qid"));
                            question.put("qtext", rs.getString("qtext"));
                            question.put("qopts", rs.getArray("qopts").getArray());
                            question.put("qans",  rs.getString("qans"));
                            questions.add(question);
                        }

                        System.out.println("[exam.jsp] Retrieved " + questions.size() + " questions from database");
                        QuestionCache.put(topic, tid, questions);
                        System.out.println("[exam.jsp] Cached " + questions.size() + " questions for: " + topic);
                    }

                    int count = 1;
                    int maxQuestions = Math.min(limit, questions.size());
                    
                    System.out.println("[exam.jsp] Total questions available: " + questions.size() + ", requested: " + limit + ", will display: " + maxQuestions);

                    for (int i = 0; i < maxQuestions; i++) {
                        Map<String, Object> question = questions.get(i);
                        String[] opts = (String[]) question.get("qopts");
            %>
                        <div class="q-card">
                            <h3 style="margin-bottom: 1rem;"><%= count %>. <%= question.get("qtext") %></h3>

                            <label class="option-container">
                                <input type="radio" name="q<%= question.get("qid") %>" value="A" required>
                                <span><%= opts[0] %></span>
                            </label>
                            <label class="option-container">
                                <input type="radio" name="q<%= question.get("qid") %>" value="B">
                                <span><%= opts[1] %></span>
                            </label>
                            <label class="option-container">
                                <input type="radio" name="q<%= question.get("qid") %>" value="C">
                                <span><%= opts[2] %></span>
                            </label>
                            <label class="option-container">
                                <input type="radio" name="q<%= question.get("qid") %>" value="D">
                                <span><%= opts[3] %></span>
                            </label>
                        </div>
            <%
                        count++;
                    }

                    long endTime = System.currentTimeMillis();
                    System.out.println("[exam.jsp] Total time: " + (endTime - startTime) + "ms (cached: " + useCache + ")");

                } catch (Exception e) {
                    System.out.println("[exam.jsp] ERROR: Failed to fetch questions - " + e.getMessage());
                    e.printStackTrace();
                    out.print("<div class='q-card error'>Database Error: " + e.getMessage() + "</div>");
                } finally {
                    try {
                        if (rs   != null) rs.close();
                        if (ps   != null) ps.close();
                        if (conn != null) DBConnectionPool.releaseConnection(conn);
                    } catch (Exception e) {
                        // ignore cleanup errors
                    }
                }
            %>
            </div>
            <button type="submit" class="btn-submit" style="margin-top: 1.5rem; font-size: 1.1rem; padding: 1rem;">
                Finish &amp; Submit Exam
            </button>
        </form>
      </div>
    </div>

    <script>
        window.addEventListener('load', function () {
            var overlay      = document.getElementById('loadingOverlay');
            var skeletonLoader = document.getElementById('skeletonLoader');
            var examForm     = document.getElementById('examForm');

            if (overlay) {
                overlay.style.transition = 'opacity 0.3s ease';
                overlay.style.opacity = '0';
                setTimeout(function () { overlay.remove(); }, 300);
            }

            if (skeletonLoader && examForm) {
                skeletonLoader.style.display = 'none';
                examForm.style.display = 'block';
            }
        });
    </script>
</body>
</html>