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
        .type-target { visibility: hidden; }
        .blinking-cursor::after {
            content: '|';
            display: inline-block;
            color: var(--amber);
            animation: blink 1s step-end infinite;
            margin-left: 6px;
        }
        @keyframes blink { 50% { opacity: 0; } }
    </style>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell" style="flex-direction: column; justify-content: flex-start; align-items: center; padding-top: 2rem;">
      <div style="width: 100%; max-width: 900px;">

        <%-- ── DB queries ─────────────────────────────────────────── --%>
        <%
            int    totalExams   = 0;
            int    latestScore  = 0;
            int    latestTotal  = 0;
            String latestTopic  = null;
            String latestDate   = null;
            double avgScore     = 0;
            boolean hasHistory  = false;

            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {

                // total exams
                PreparedStatement pcs = conn.prepareStatement(
                    "SELECT COUNT(*) AS cnt FROM user_results WHERE username = ?");
                pcs.setString(1, (String) session.getAttribute("username"));
                ResultSet rcs = pcs.executeQuery();
                if (rcs.next()) totalExams = rcs.getInt("cnt");

                // average score %
                PreparedStatement pav = conn.prepareStatement(
                    "SELECT AVG(score::float / NULLIF(total_questions,0) * 100) AS avg FROM user_results WHERE username = ?");
                pav.setString(1, (String) session.getAttribute("username"));
                ResultSet rav = pav.executeQuery();
                if (rav.next()) avgScore = rav.getDouble("avg");

                // latest result
                PreparedStatement pls = conn.prepareStatement(
                    "SELECT score, total_questions, test_date, topic FROM user_results WHERE username = ? ORDER BY test_date DESC LIMIT 1");
                pls.setString(1, (String) session.getAttribute("username"));
                ResultSet rls = pls.executeQuery();
                if (rls.next()) {
                    hasHistory  = true;
                    latestScore = rls.getInt("score");
                    latestTotal = rls.getInt("total_questions");
                    latestTopic = rls.getString("topic");
                    latestDate  = rls.getTimestamp("test_date").toString();
                }

            } catch (Exception e) {
                getServletContext().log("[dashboard.jsp] DB error", e);
            }

            int avgPct = (int) Math.round(avgScore);
        %>

        <%-- ── Welcome typewriter heading ────────────────────────── --%>
        <h1 id="typing-welcome" class="type-target blinking-cursor"
            style="margin-bottom: 2rem; color: var(--amber);">
            Welcome back, <%= session.getAttribute("username") %>! 👋
        </h1>

        <%-- ── Main card ──────────────────────────────────────────── --%>
        <div class="card">

            <%-- Header row --%>
            <div style="display:flex; align-items:center; justify-content:space-between;
                        margin-bottom:1.5rem; flex-wrap:wrap; gap:1rem;">
                <div>
                    <h2 style="margin:0 0 0.25rem 0;">Overview</h2>
                    <p style="margin:0; font-size:0.8rem; color:var(--ink-muted);">
                        Here is a summary of your studies and tools.
                    </p>
                </div>
                <div style="display:flex; gap:0.5rem; flex-wrap:wrap;">
                    <a href="setup.jsp"  class="btn-primary" style="width:auto; text-decoration:none;">+ Take Exam</a>
                    <a href="notes.jsp"  class="btn-outline" style="width:auto; text-decoration:none;">+ New Note</a>
                </div>
            </div>

            <%-- ── Stat tiles ─────────────────────────────────────── --%>
            <div class="grid-3" style="margin-bottom:1.5rem;">
                <div class="stat-tile">
                    <div class="stat-tile__val"><%= totalExams %></div>
                    <div class="stat-tile__lbl">Exams Taken</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-tile__val" style="color: var(--purple);">
                        <%= totalExams > 0 ? avgPct + "%" : "—" %>
                    </div>
                    <div class="stat-tile__lbl">Average Score</div>
                </div>
                <div class="stat-tile">
                    <div class="stat-tile__val" style="color: var(--green);">Active</div>
                    <div class="stat-tile__lbl">Account Status</div>
                </div>
            </div>

            <%-- ── Recent Activity ────────────────────────────────── --%>
            <div class="divider"></div>
            <h3 style="font-size:0.72rem; color:var(--ink-muted); text-transform:uppercase;
                       letter-spacing:0.06em; margin-bottom:1rem;">Recent Activity</h3>

            <% if (hasHistory) { %>
                <%-- Latest exam row --%>
                <div style="display:flex; align-items:center; justify-content:space-between;
                            padding:0.75rem 0; border-bottom:1px solid var(--border); flex-wrap:wrap; gap:0.5rem;">
                    <div style="display:flex; align-items:center; gap:0.75rem;">
                        <span style="font-size:1.35rem;">📝</span>
                        <div>
                            <div style="font-size:0.875rem; font-weight:500; color:var(--ink);">
                                Exam: <%= latestTopic %>
                            </div>
                            <div style="font-size:0.75rem; color:var(--ink-muted); margin-top:0.2rem;">
                                Completed on <%= latestDate %>
                            </div>
                        </div>
                    </div>
                    <%
                        boolean passed = latestTotal > 0 && latestScore >= latestTotal / 2.0;
                        int pct = latestTotal > 0 ? (int) Math.round(latestScore * 100.0 / latestTotal) : 0;
                    %>
                    <span class="badge <%= passed ? "badge-green" : "badge-red" %>">
                        Score: <%= pct %>%
                    </span>
                </div>

                <%-- Notes row (static placeholder — wire to DB when notes table exists) --%>
                <div style="display:flex; align-items:center; justify-content:space-between;
                            padding:0.75rem 0; flex-wrap:wrap; gap:0.5rem;">
                    <div style="display:flex; align-items:center; gap:0.75rem;">
                        <span style="font-size:1.35rem;">🧠</span>
                        <div>
                            <div style="font-size:0.875rem; font-weight:500; color:var(--ink);">
                                Smart Notes
                            </div>
                            <div style="font-size:0.75rem; color:var(--ink-muted); margin-top:0.2rem;">
                                Visit the Notes tab to create and manage your study notes.
                            </div>
                        </div>
                    </div>
                    <span class="badge badge-purple">AI Assisted</span>
                </div>

            <% } else { %>
                <div style="padding:1.5rem 0; text-align:center; color:var(--ink-muted); font-size:0.875rem;">
                    No activity yet — take your first exam to get started!
                </div>
            <% } %>

            <%-- ── Footer action ──────────────────────────────────── --%>
            <div class="divider"></div>
            <a href="exam_history.jsp" class="btn-outline"
               style="display:block; text-align:center; text-decoration:none;">
                View All Records →
            </a>

        </div>
      </div>
    </div>

    <%-- ── Typewriter script ──────────────────────────────────────── --%>
    <script>
        document.addEventListener("DOMContentLoaded", () => {
            const el       = document.getElementById('typing-welcome');
            const fullText = el.textContent || el.innerText;
            el.textContent = '';
            el.style.visibility = 'visible';
            let i = 0;
            function type() {
                if (i < fullText.length) {
                    el.textContent += fullText.charAt(i++);
                    setTimeout(type, Math.random() * 30 + 20);
                } else {
                    setTimeout(() => el.classList.remove('blinking-cursor'), 2000);
                }
            }
            type();
        });
    </script>
</body>
</html>