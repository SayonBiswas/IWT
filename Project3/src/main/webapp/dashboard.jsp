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
    <title>Student Dashboard</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
    <style>
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
    </style>
</head>
<body>
    <%@ include file="navbar.jsp" %>
    <div class="page-shell" style="padding-top: 2rem; flex-direction: column; justify-content: flex-start; align-items: center;">
      <div style="width: 100%; max-width: 900px; margin-top: 1rem;">

        <h1 id="typing-welcome" class="type-target blinking-cursor" style="margin-bottom: 2rem; color: var(--amber);">Welcome to Your Dashboard, <%= session.getAttribute("username") %>!</h1>

        <div class="card">
            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1.5rem; flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h2 style="margin: 0 0 0.5rem 0;">Overview</h2>
                    <p style="margin:0; font-size: 13px; color: var(--ink-muted);">Generate fresh questions using AI based on any topic.</p>
                </div>
                <div>
                    <a href="setup.jsp" class="btn-primary" style="text-decoration: none; width: auto; display: inline-block;">+ Start New Test</a>
                </div>
            </div>

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

            <!-- Three-Pillar Stat Tiles -->
            <div class="stat-row">
                <div class="stat">
                    <div class="stat-val" style="color: var(--accent);"><%= totalExams %></div>
                    <div class="stat-lbl">Exams Taken</div>
                </div>
                <div class="stat">
                    <div class="stat-val" style="color: var(--purple); font-size: 1rem; margin-top: 0.5rem;"><%= latestSummary %></div>
                    <div class="stat-lbl">Latest Record</div>
                </div>
                <div class="stat">
                    <div class="stat-val" style="color: var(--green);">Active</div>
                    <div class="stat-lbl">Account Status</div>
                </div>
            </div>

            <div style="height: 1px; background: var(--border); margin: 1.25rem 0;"></div>

            <div style="display: grid; grid-template-columns: 1fr; gap: 1rem;">
                <a href="exam_history.jsp" class="btn-primary" style="display:block; text-align:center; padding: 1rem; text-decoration:none; background: transparent; border: 1.5px solid var(--accent); color: var(--accent);">View All Records</a>
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