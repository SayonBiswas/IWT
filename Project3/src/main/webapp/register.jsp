<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ include file="db_config.jsp" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Register</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
	<div class="page-shell">
      <div class="card">
        <h2>Register</h2>
        <form method="POST">
            <input type="text" name="user" placeholder="Username" required>
            <input type="password" name="pass" placeholder="Password" required>
            <input type="email" name="email" placeholder="Email" required>
            <button type="submit">Create Account</button>
        </form>
        <p><a href="login.jsp">Already have an account? Login</a></p>

        <%
            if(request.getMethod().equalsIgnoreCase("POST")) {
                try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                    PreparedStatement ps = conn.prepareStatement("INSERT INTO users(username, password, email) VALUES(?,?,?)");
                    ps.setString(1, request.getParameter("user"));
                    ps.setString(2, request.getParameter("pass"));
                    ps.setString(3, request.getParameter("email"));
                    ps.executeUpdate();
                    out.print("<script>alert('Registered!'); window.location='login.jsp';</script>");
                } catch(Exception e) { out.print("Error: " + e.getMessage()); }
            }
        %>
      </div>
    </div>
</body>
</html>