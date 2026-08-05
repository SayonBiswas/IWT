<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configure Exam</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
<script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
        <div class="setup-card">
            <h2 style="color: var(--amber); text-align: center;">Configure New Exam</h2>
            <p style="text-align: center; margin-bottom: 2rem;">Select your topic, question limit, and source.</p>

            <form id="setupForm" action="generateQuestion.jsp" method="POST">

                <div class="form-group">
                    <label>Exam Topic</label>
                    <input type="text" name="topic" placeholder="e.g., C++, Java, Python..." required>
                </div>

                <div class="form-group">
                    <label>Number of Questions</label>
                    <input type="number" name="qCount" min="1" max="50" value="10" required>
                </div>

                <div class="form-group">
                    <label>Select Question Source</label>
                    <div class="radio-group">

                        <label class="option-container" style="flex: 1; text-align: center; justify-content: center;">
                            <input type="radio" name="source" value="database" checked>
                            <span>Internal Database</span>
                        </label>

                        <label class="option-container" style="flex: 1; text-align: center; justify-content: center;">
                            <input type="radio" name="source" value="ai_generated">
                            <span>AI Generated</span>
                        </label>

                    </div>
                    <p style="font-size: 0.8rem; color: var(--ink-muted); margin-top: 0.5rem;">
                        * Internal database fetches instantly. AI generation may take 10-15 seconds.
                    </p>
                </div>

                <button type="submit" class="btn-submit" style="margin-top: 2rem;">Start Examination</button>
            </form>
        </div>
    </div>
</body>
</html>