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
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
<script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
    <style>
        /* 1. Strictly forces the layout blocks to stay side-by-side */
        .box-container {
            display: flex !important;
            flex-direction: row;
            gap: 2rem;
            flex-wrap: nowrap; /* Prevents containers from wrapping down */
            align-items: stretch;
        }
        
        .box-container .box {
            flex: 1 1 50%; /* Each sub-div occupies exactly half of the row space */
        }
        
        /* 2. Style configuration for the focused header typewriter element */
        .type-target {
            visibility: hidden; /* Avoid layout text flickering prior to JS execution */
        }
        
        /* The typewriter cursor line */
        .blinking-cursor::after {
            content: '|';
            display: inline-block;
            color: var(--amber);
            animation: blink 1s step-end infinite;
            margin-left: 6px;
        }
        
        @keyframes blink { 
            50% { opacity: 0; } 
        }

        /* Safety responsive wrap fallback for super small mobile viewports */
        @media (max-width: 768px) {
            .box-container {
                flex-wrap: wrap; 
            }
            .box-container .box {
                flex: 1 1 100%;
            }
        }
    </style>
</head>
<body>
    <%@ include file="navbar.jsp" %>
    <div class="page-shell" style="padding-top: 2rem; flex-direction: column; justify-content: flex-start; align-items: center;">
      <div style="width: 100%; max-width: 900px; margin-top: 1rem;">
        
        <h1 id="typing-welcome" class="type-target blinking-cursor" style="margin-bottom: 2rem; color: var(--amber);">Welcome to Your Dashboard, <%= session.getAttribute("username") %>!</h1>
        
        <div class="card">
            <div class="box-container">
                <div class="box">
                    <h2 style="margin-bottom: 1rem;">Take a Test</h2>
                    <p>Generate fresh questions using AI based on any topic of your choice.</p>
                    <br>
                    <a href="setup.jsp" class="btn-submit" style="text-align: center; display: inline-block; text-decoration: none;">Start New Test</a>
                </div>

                <div class="box">
                    <h2 style="margin-bottom: 1rem;">Quick Stats</h2>
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
                    <p>Exams completed: <strong style="color: var(--amber);"><%= totalExams %></strong></p>
                    <p><%= latestSummary %></p>
                    <br>
                    <a href="exam_history.jsp" class="btn-submit" style="text-align: center; display: inline-block; text-decoration: none;">View My Records</a>
                </div>
            </div>
        </div>
        
      </div>
    </div>

    <script>
        document.addEventListener("DOMContentLoaded", () => {
            const welcomeHeader = document.getElementById('typing-welcome');
            
            // Capture the fully evaluated text compiled by the server
            const fullText = welcomeHeader.textContent || welcomeHeader.innerText;
            
            // Clear content and switch to visible to let it start empty
            welcomeHeader.textContent = '';
            welcomeHeader.style.visibility = 'visible';
            
            let charIndex = 0;
            
            function typeCharacter() {
                if (charIndex < fullText.length) {
                    welcomeHeader.textContent += fullText.charAt(charIndex);
                    charIndex++;
                    // Natural typing speed variation (adds a random factor between 20ms and 50ms)
                    setTimeout(typeCharacter, Math.random() * 30 + 20);
                } else {
                    // Stop blinking effect 2 seconds after completion
                    setTimeout(() => {
                        welcomeHeader.classList.remove('blinking-cursor');
                    }, 2000);
                }
            }
            
            // Initiate the typewriter chain
            typeCharacter();
        });
    </script>
</body>
</html>