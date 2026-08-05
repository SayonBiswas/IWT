<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%@ include file="db_config.jsp" %>
<%@ include file="navbar.jsp" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Register</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
<script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <div class="page-shell">
      <div class="card">
        <h2 style="margin-bottom: 1.5rem; text-align: center;">Register</h2>
        <form method="POST">
            <div class="form-group">
                <input type="text" name="user" placeholder="Username" required>
            </div>
            <div class="form-group">
                <input type="password" name="pass" placeholder="Password" required>
            </div>
            <div class="form-group">
                <input type="email" name="email" placeholder="Email" required>
            </div>
            <button type="submit" class="btn-submit">Create Account</button>
        </form>
        <div class="reg-link">
            Already have an account? <a href="login.jsp">Login</a>
        </div>

        <%
            if(request.getMethod().equalsIgnoreCase("POST")) {
                try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                    String hashedPassword = BCrypt.hashpw(request.getParameter("pass"), BCrypt.gensalt(12));

                    PreparedStatement ps = conn.prepareStatement("INSERT INTO users(username, password, email) VALUES(?,?,?)");
                    ps.setString(1, request.getParameter("user"));
                    ps.setString(2, hashedPassword);
                    ps.setString(3, request.getParameter("email"));
                    ps.executeUpdate();
                    out.print("<script>alert('Registered!'); window.location='login.jsp';</script>");
                } catch(Exception e) {
                    e.printStackTrace();
                    out.print("<p class='error'>Registration failed. Please try again.</p>");
                }
            }
        %>
      </div>
    </div>
</body>
</html>