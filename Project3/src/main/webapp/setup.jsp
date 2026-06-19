<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Configure Exam</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
        <div class="setup-card">
            <h2 style="color: var(--amber); text-align: center;">Configure New Exam</h2>
            <p style="text-align: center; margin-bottom: 2rem;">Select your topic, question limit, and source.</p>

            <form id="setupForm" action="exam_init.jsp" method="POST">

                <div class="form-group">
                    <label>Exam Topic</label>
                    <select name="topic" required>
                        <option value="C">C Programming</option>
                        <option value="C++">C++</option>
                        <option value="Java">Java</option>
                        <option value="PostgreSQL">PostgreSQL</option>
                    </select>
                </div>

                <div class="form-group">
                    <label>Number of Questions</label>
                    <input type="number" name="limit" min="1" max="50" value="10" required>
                </div>

                <div class="form-group">
                    <label>Select Question Source</label>
                    <div class="radio-group">

                        <label class="option-container" style="flex: 1; text-align: center; justify-content: center;">
                            <input type="radio" name="source" value="database" onchange="updateRoute()" checked>
                            <span>Internal Database</span>
                        </label>

                        <label class="option-container" style="flex: 1; text-align: center; justify-content: center;">
                            <input type="radio" name="source" value="ai_generated" onchange="updateRoute()">
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

    <script>
        function updateRoute() {
            const form = document.getElementById('setupForm');

            // Check which radio button is currently selected
            const selectedSource = document.querySelector('input[name="source"]:checked').value;

            if (selectedSource === 'database') {
                // If Database is selected, submit the form to the script that sets up exam.jsp
                // CHANGE THIS to the name of your file that handles database exams!
                form.action = "exam.jsp";

            } else if (selectedSource === 'ai_generated') {
                // If AI is selected, submit the form to the script that calls your API
                // CHANGE THIS to the name of your file that handles AI exams!
                form.action = "generateQuestion.jsp";
            }
        }

        // Run this function immediately when the page loads so the default "checked" button routes correctly
        window.onload = updateRoute;
    </script>
</body>
</html>