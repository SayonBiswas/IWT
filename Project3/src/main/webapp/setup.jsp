<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <title>Setup Exam</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <%@ include file="navbar.jsp" %>
    <div class="page-shell" style="padding-top: 2rem;">
      <div class="setup-card">
        <h2 style="margin-bottom: 1.5rem;">Exam Configuration</h2>
        <form action="generateQuestion.jsp" method="POST">
            <div class="form-group">
                <label>Enter Topic:</label>
                <input type="text" name="topic" placeholder="e.g. Java, Python, History" required>
            </div>
            
            <div class="form-group">
                <label>Number of Questions:</label>
                <input type="number" name="qCount" value="5" min="1" max="10">
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
			        * Internal database uses pre-vetted questions. AI generation may take 10-15 seconds to compile.
			    </p>
			</div>

            <button type="submit" class="btn-submit">Start Preparation</button>
        </form>
      </div>
    </div>
</body>
</html>