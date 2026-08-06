<%@ include file="db_config.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ExamHub - Sign In</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
      <div class="login-card">

        <!-- Unified Branding Header -->
        <div style="text-align:center; margin-bottom: 1.5rem;">
            <h2 style="margin-bottom: 0.5rem; text-align: center;">ExamHub</h2>
            <p style="text-align:center; font-size:0.85rem; color:var(--ink-muted); margin-bottom:1.5rem;">One login for Students, Teachers &amp; Admins</p>
        </div>

        <form method="POST">
            <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">
            <div class="form-group">
                <label class="field-label">Username</label>
                <input type="text" name="user" class="field" placeholder="Username" required>
            </div>
            <div class="form-group">
                <label class="field-label">Password</label>
                <input type="password" name="pass" class="field" placeholder="••••••••" required>
            </div>
            <button type="submit" class="btn-submit">Sign In</button>
        </form>

        <div class="reg-link">
            <span style="font-size:11px; color:var(--ink-muted);">Don't have an account? </span>
            <a href="register.jsp" class="link">Register here</a>
        </div>

        <%
            if(request.getMethod().equalsIgnoreCase("POST")) {
                String u = request.getParameter("user");
                String p = request.getParameter("pass");

                try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                    String query = "SELECT username, password, role FROM users WHERE username = ?";
                    PreparedStatement ps = conn.prepareStatement(query);
                    ps.setString(1, u);

                    ResultSet rs = ps.executeQuery();
                    if (rs.next() && BCrypt.checkpw(p, rs.getString("password"))) {
                        String userRole = rs.getString("role");
                        if (userRole == null) { userRole = "student"; }

                        session.invalidate();
                        HttpSession newSession = request.getSession(true);
                        newSession.setAttribute("username", rs.getString("username"));
                        newSession.setAttribute("role", userRole);

                        if ("admin".equalsIgnoreCase(userRole)) {
                            response.sendRedirect("admin_dashboard.jsp");
                        } else {
                            response.sendRedirect("dashboard.jsp");
                        }
                    } else {
                        out.print("<p class='error' style='margin-top: 1rem;'>Invalid Username or Password!</p>");
                    }
                } catch(Exception e) {
                    getServletContext().log("[login.jsp] Login error", e);
                    out.print("<p class='error' style='margin-top: 1rem;'>Login failed. Please try again.</p>");
                }
            }
        %>
      </div>
    </div>
</body>
</html>