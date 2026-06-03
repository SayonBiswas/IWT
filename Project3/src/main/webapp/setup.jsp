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
        <h2>Exam Configuration</h2>
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
                <label>Question Source:</label>
                <div class="radio-group">
                    <label style="font-weight: normal;">
                        <input type="radio" name="source" value="old" checked> Use Existing
                    </label>
                    <label style="font-weight: normal;">
                        <input type="radio" name="source" value="new"> Generate New (AI)
                    </label>
                </div>
            </div>

            <button type="submit">Start Preparation</button>
        </form>
      </div>
    </div>
</body>
</html>