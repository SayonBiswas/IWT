<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*" %>
<%@ include file="db_config.jsp" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
    String loggedUser = (String) session.getAttribute("username");
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

        <%-- ── Header ─────────────────────────────────────────────────── --%>
        <div style="display:flex; align-items:center; justify-content:space-between;
                    margin-bottom:1.5rem; flex-wrap:wrap; gap:1rem;">
            <div>
                <h2 style="margin:0 0 0.5rem 0;">Smart Notes</h2>
                <p style="margin:0; font-size:13px; color:var(--ink-muted);">
                    Write your notes and get AI-powered suggestions.
                </p>
            </div>
        </div>

        <%-- ── Feedback messages ──────────────────────────────────────── --%>
        <%
            String saved   = (String) session.getAttribute("note_saved");
            String noteErr = (String) session.getAttribute("note_error");
            if (saved != null) {
                session.removeAttribute("note_saved");
        %>
            <div class="info-note success" style="margin-bottom:1.5rem;">
                <span>✓</span><div><%= saved %></div>
            </div>
        <% } %>
        <% if (noteErr != null) {
                session.removeAttribute("note_error");
        %>
            <div class="info-note danger" style="margin-bottom:1.5rem;">
                <span>✕</span><div><%= noteErr %></div>
            </div>
        <% } %>

        <%-- ── Note form ───────────────────────────────────────────────── --%>
        <form method="POST" id="noteForm">
            <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">
            <input type="hidden" name="action" value="save">

            <div class="grid-2">
                <div>
                    <label class="field-label">Note Title / Topic</label>
                    <input type="text" name="noteTitle" class="field focus"
                           placeholder="e.g., Banker's Algorithm & Deadlocks"
                           maxlength="200" required>
                </div>
                <div>
                    <label class="field-label">Academic Level</label>
                    <select name="academicLevel" class="field">
                        <option value="school">School Level</option>
                        <option value="bachelors" selected>Bachelors Level (UG)</option>
                        <option value="masters">Masters Level (PG)</option>
                    </select>
                </div>
            </div>

            <label class="field-label">Note Content</label>
            <textarea name="noteContent" class="field" rows="8"
                      placeholder="Start typing your notes here..."
                      required></textarea>

            <div style="display:flex; justify-content:space-between;
                        align-items:center; margin-top:1rem; flex-wrap:wrap; gap:0.75rem;">
                <button type="button" id="aiBtn" class="btn-outline"
                        style="width:auto; color:var(--purple); border-color:var(--purple);">
                    ✨ Generate AI Suggestions
                </button>
                <button type="submit" class="btn-primary" style="width:auto;">
                    💾 Save Note
                </button>
            </div>
        </form>

        <%-- ── AI suggestions panel (hidden until triggered) ─────────── --%>
        <div id="aiPanel" style="display:none; margin-top:1.5rem;">
            <div id="aiLoading" class="info-note purple" style="display:none;">
                <span>⏳</span>
                <div>Generating AI suggestions, please wait...</div>
            </div>
            <div id="aiResult" class="info-note purple" style="display:none;">
                <span>✨</span>
                <div id="aiText"></div>
            </div>
            <div id="aiError" class="info-note danger" style="display:none;">
                <span>✕</span>
                <div id="aiErrorText"></div>
            </div>
        </div>

        <%-- ── Saved notes list ────────────────────────────────────────── --%>
        <h3 style="font-size:12px; color:var(--ink-soft); margin-top:2.5rem;
                   text-transform:uppercase; letter-spacing:0.05em;">
            Your Saved Notes
        </h3>

        <%
            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                PreparedStatement ps = conn.prepareStatement(
                    "SELECT nid, title, level, created_at FROM notes " +
                    "WHERE username = ? ORDER BY created_at DESC");
                ps.setString(1, loggedUser);
                ResultSet rs = ps.executeQuery();
                boolean hasNotes = false;
                while (rs.next()) {
                    hasNotes = true;
                    String levelLabel = rs.getString("level");
                    if (levelLabel.equals("bachelors")) levelLabel = "Bachelors (UG)";
                    else if (levelLabel.equals("masters")) levelLabel = "Masters (PG)";
                    else levelLabel = "School";
        %>
            <div class="q-card" style="display:flex; justify-content:space-between;
                                       align-items:center; flex-wrap:wrap; gap:0.5rem;
                                       margin-top:0.75rem;">
                <div>
                    <strong style="color:var(--ink);"><%= rs.getString("title") %></strong>
                    <div style="font-size:12px; color:var(--ink-muted); margin-top:0.25rem;">
                        <%= levelLabel %> &nbsp;·&nbsp;
                        <%= rs.getTimestamp("created_at").toString().substring(0, 16) %>
                    </div>
                </div>
                <form method="POST" style="margin:0;">
                    <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="nid" value="<%= rs.getInt("nid") %>">
                    <button type="submit" class="btn-outline"
                            style="width:auto; color:var(--red); border-color:var(--red);
                                   padding:0.3rem 0.8rem; font-size:12px;">
                        Delete
                    </button>
                </form>
            </div>
        <%
                }
                if (!hasNotes) {
        %>
            <p style="color:var(--ink-muted); font-size:13px; margin-top:0.75rem;">
                No notes saved yet. Write your first note above!
            </p>
        <%
                }
            } catch (Exception e) {
                getServletContext().log("[notes.jsp] Failed to load notes list", e);
            }
        %>

      </div>
    </div>

    <%-- ── POST handler ────────────────────────────────────────────────── --%>
    <%
        if (request.getMethod().equalsIgnoreCase("POST")) {
            String action = request.getParameter("action");

            if ("save".equals(action)) {
                String title   = request.getParameter("noteTitle");
                String content = request.getParameter("noteContent");
                String level   = request.getParameter("academicLevel");

                // Server-side validation
                if (title == null || title.trim().isEmpty() ||
                    content == null || content.trim().isEmpty()) {
                    session.setAttribute("note_error", "Title and content are required.");
                } else if (title.length() > 200) {
                    session.setAttribute("note_error", "Title must be 200 characters or fewer.");
                } else {
                    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                        PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO notes (username, title, content, level) VALUES (?, ?, ?, ?)");
                        ps.setString(1, loggedUser);
                        ps.setString(2, title.trim());
                        ps.setString(3, content.trim());
                        ps.setString(4, level != null ? level : "bachelors");
                        ps.executeUpdate();
                        session.setAttribute("note_saved", "Note \"" + title.trim() + "\" saved successfully!");
                    } catch (Exception e) {
                        getServletContext().log("[notes.jsp] Note save error", e);
                        session.setAttribute("note_error", "Failed to save note. Please try again.");
                    }
                }
                response.sendRedirect("notes.jsp");
                return;

            } else if ("delete".equals(action)) {
                String nidParam = request.getParameter("nid");
                if (nidParam != null && nidParam.matches("\\d+")) {
                    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                        // only delete if it belongs to this user
                        PreparedStatement ps = conn.prepareStatement(
                            "DELETE FROM notes WHERE nid = ? AND username = ?");
                        ps.setInt(1, Integer.parseInt(nidParam));
                        ps.setString(2, loggedUser);
                        ps.executeUpdate();
                        session.setAttribute("note_saved", "Note deleted.");
                    } catch (Exception e) {
                        getServletContext().log("[notes.jsp] Note delete error", e);
                        session.setAttribute("note_error", "Failed to delete note.");
                    }
                }
                response.sendRedirect("notes.jsp");
                return;
            }
        }
    %>

    <%-- ── AI Suggestions JS ───────────────────────────────────────────── --%>
    <script>
    (function () {
        const aiBtn     = document.getElementById('aiBtn');
        const aiPanel   = document.getElementById('aiPanel');
        const aiLoading = document.getElementById('aiLoading');
        const aiResult  = document.getElementById('aiResult');
        const aiText    = document.getElementById('aiText');
        const aiError   = document.getElementById('aiError');
        const aiErrTxt  = document.getElementById('aiErrorText');

        aiBtn.addEventListener('click', async function () {
            const title   = document.querySelector('input[name="noteTitle"]').value.trim();
            const content = document.querySelector('textarea[name="noteContent"]').value.trim();
            const level   = document.querySelector('select[name="academicLevel"]').value;

            if (!title || !content) {
                alert('Please enter a title and some content before generating suggestions.');
                return;
            }

            // Show loading
            aiPanel.style.display  = 'block';
            aiLoading.style.display = 'flex';
            aiResult.style.display  = 'none';
            aiError.style.display   = 'none';
            aiBtn.disabled = true;
            aiBtn.textContent = '⏳ Generating...';

            try {
                const response = await fetch("https://api.anthropic.com/v1/messages", {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify({
                        model: "claude-sonnet-4-6",
                        max_tokens: 1000,
                        system: "You are an academic study assistant. Given a student's notes, provide concise, helpful suggestions to improve them. Focus on: missing key concepts, areas to expand, and 3 related topics to explore. Format your response in plain HTML using <strong>, <ul>, <li> only. Keep it under 200 words.",
                        messages: [{
                            role: "user",
                            content: `Topic: ${title}\nLevel: ${level}\n\nStudent's notes:\n${content}\n\nProvide improvement suggestions.`
                        }]
                    })
                });

                const data = await response.json();
                const text = data.content?.find(b => b.type === 'text')?.text || '';

                if (!text) throw new Error('Empty response from AI.');

                aiLoading.style.display = 'none';
                aiResult.style.display  = 'flex';
                aiText.innerHTML = `<strong style="color:var(--purple); display:block;
                                    margin-bottom:0.5rem;">AI Suggestions for "${title}"</strong>
                                    ${text}`;
            } catch (err) {
                aiLoading.style.display = 'none';
                aiError.style.display   = 'flex';
                aiErrTxt.textContent    = 'Could not generate suggestions. Please try again.';
            } finally {
                aiBtn.disabled = false;
                aiBtn.textContent = '✨ Generate AI Suggestions';
            }
        });
    })();
    </script>
</body>
</html>