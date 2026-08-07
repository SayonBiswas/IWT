<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>

<%!
    public String renderHtmlTable(Connection conn, String query, String displayTitle) {
        StringBuilder html = new StringBuilder();
        html.append("<div class='box' style='margin-top: 2rem; padding: 1.5rem;'>");
        html.append("<h3 style='color: var(--amber); margin-bottom: 1rem;'>").append(displayTitle).append("</h3>");
        html.append("<div class='table-wrap'><table><thead><tr>");

        try (PreparedStatement ps = conn.prepareStatement(query);
             ResultSet rs = ps.executeQuery()) {

            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();

            for (int i = 1; i <= columnCount; i++) {
                html.append("<th>").append(metaData.getColumnName(i)).append("</th>");
            }
            html.append("</tr></thead><tbody>");

            while (rs.next()) {
                html.append("<tr>");
                for (int i = 1; i <= columnCount; i++) {
                    html.append("<td>").append(rs.getString(i)).append("</td>");
                }
                html.append("</tr>");
            }

        } catch (Exception e) {
            getServletContext().log("[admin_dashboard.jsp] Failed to load dashboard data", e);
            // FIXED: Appending the error to the StringBuilder instead of using the unavailable 'out' object
            html.append("<tr><td colspan='10'><div class='error'>Could not load dashboard data. Check server logs.</div></td></tr>");
        }

        html.append("</tbody></table></div></div>");
        return html.toString();
    }
%>

<%
    if (session.getAttribute("username") == null || !"admin".equalsIgnoreCase((String)session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ExamHub - Admin Dashboard</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell" style="padding-top: 2rem;">
      <div class="card" style="width: 100%; max-width: 1000px;">
        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:1.5rem;">
            <div>
                <h2 style="margin: 0 0 0.5rem 0;">Admin Control Center</h2>
                <p style="margin:0; font-size: 13px; color: var(--ink-muted);">Logged in as: <strong style="color: var(--amber);"><%= session.getAttribute("username") %></strong></p>
            </div>
        </div>

        <div class="grid-4" style="margin-bottom: 2rem;">
            <div class="stat-tile">
                <div class="stat-tile__val" style="color: var(--ink);">—</div>
                <div class="stat-tile__lbl">Total Users</div>
            </div>
            <div class="stat-tile">
                <div class="stat-tile__val" style="color: var(--purple);">—</div>
                <div class="stat-tile__lbl">AI API Requests</div>
            </div>
            <div class="stat-tile">
                <div class="stat-tile__val" style="color: var(--green);">—</div>
                <div class="stat-tile__lbl">Questions in DB</div>
            </div>
            <div class="stat-tile">
                <div class="stat-tile__val" style="color: var(--amber);">—</div>
                <div class="stat-tile__lbl">Global Avg Score</div>
            </div>
        </div>

        <div style="margin-top: 3rem; border-top: 1px solid var(--border); padding-top: 2rem;">
            <h2 style="color: var(--ink);">Database Overview</h2>

            <%
                Connection conn = null;
                try {
                    Class.forName("org.postgresql.Driver");
                    conn = DriverManager.getConnection(dbUrl, user, pass);

                    // Password column intentionally excluded from users query
                    out.print(renderHtmlTable(conn, "SELECT username, email, role FROM users ORDER BY username", "System Users"));
                    out.print(renderHtmlTable(conn, "SELECT * FROM topics ORDER BY tid", "Exam Topics"));
                    out.print(renderHtmlTable(conn, "SELECT qid, qno, qtext, qans, tid FROM questions ORDER BY tid, qno", "Question Bank Master List"));
                    out.print(renderHtmlTable(conn, "SELECT * FROM user_results ORDER BY test_date DESC", "Student Test Records"));

                } catch (Exception e) {
                    getServletContext().log("[admin_dashboard.jsp] Database connection failed", e);
                    out.print("<div class='error'>Failed to connect to the database. Check server logs.</div>");
                } finally {
                    if (conn != null) { try { conn.close(); } catch (SQLException ignore) {} }
                }
            %>
        </div>

      </div>
    </div>
</body>
</html>