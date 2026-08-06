<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%-- YOUR SECURITY/BACKEND LOGIC HERE (Session check) --%>
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
    <title>ExamHub - Smart Notes</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
        <div class="card">

            <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1.5rem; flex-wrap: wrap; gap: 1rem;">
                <div>
                    <h2 style="margin: 0 0 0.5rem 0;">Create Smart Note</h2>
                    <p style="margin:0; font-size: 13px; color: var(--ink-muted);">Organize your thoughts and get AI-powered insights.</p>
                </div>
                <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
                    <button class="btn-outline" style="width:auto; color: var(--ink); border-color: var(--border);">💾 Save Note</button>
                    <!-- PDF Export logic goes here -->
                    <button class="btn-primary" style="width:auto; background: var(--red);">📄 Export PDF</button>
                </div>
            </div>

            <form method="POST">
                <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">

                <div class="grid-2">
                    <div>
                        <label class="field-label">Note Title / Topic</label>
                        <input type="text" name="noteTitle" class="field focus" placeholder="e.g., Banker's Algorithm & Deadlocks" required />
                    </div>
                    <div>
                        <label class="field-label">Academic Level (For AI Context)</label>
                        <select name="academicLevel" class="field">
                            <option value="school">School Level</option>
                            <option value="bachelors" selected>Bachelors Level (UG)</option>
                            <option value="masters">Masters Level (PG)</option>
                        </select>
                    </div>
                </div>

                <label class="field-label">Note Content</label>
                <textarea name="noteContent" class="field" placeholder="Start typing your notes here..." required></textarea>

                <div style="display: flex; justify-content: flex-end; margin-bottom: 1.5rem;">
                    <button type="button" class="btn-outline" style="width: auto; color: var(--purple); border-color: var(--purple);">✨ Generate AI Suggestions</button>
                </div>
            </form>

            <!-- AI Suggestions Result (Dynamically render this after AI call) -->
            <div class="info-note purple">
                <span>✨</span>
                <div>
                    <strong style="color: var(--purple); display:block; margin-bottom:0.4rem; font-size:13px;">AI Insights for "Banker's Algorithm"</strong>
                    Your note covers the basic definition well. Consider adding:<br><br>
                    <ul style="margin: 0; padding-left: 1.2rem; color: var(--ink);">
                        <li>The four data structures required: <strong>Available, Max, Allocation, Need</strong>.</li>
                        <li>A practical numerical example showing a safe sequence.</li>
                    </ul>
                </div>
            </div>

            <h3 style="font-size: 12px; color: var(--ink-soft); margin-top: 2rem; text-transform: uppercase;">Suggested Related Topics</h3>
            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap; margin-top: 0.5rem;">
                <span class="badge badge-purple" style="padding: 6px 12px; cursor: pointer;">✦ Resource Allocation Graph</span>
                <span class="badge badge-purple" style="padding: 6px 12px; cursor: pointer;">✦ Mutex &amp; Semaphores</span>
            </div>

        </div>
    </div>

    <%
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String title = request.getParameter("noteTitle");
            String content = request.getParameter("noteContent");
            String level = request.getParameter("academicLevel");

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                // YOUR INSERT QUERY HERE
                // e.g., INSERT INTO notes (username, title, content, level) VALUES (?, ?, ?, ?)
                out.print("<script>alert('Note Saved Successfully!');</script>");
            } catch (Exception e) {
                getServletContext().log("Note save error", e);
                out.print("<p class='error'>Failed to save note.</p>");
            }
        }
    %>
</body>
</html>