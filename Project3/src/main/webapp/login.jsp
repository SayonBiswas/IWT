<%@ include file="db_config.jsp" %>
<%@ include file="navbar.jsp" %>
<html>
<head>
    <title>Login - Online Exam</title>
	<link rel="stylesheet" href="style.css">
</head>
<body>
    <div class="page-shell">
      <div class="login-card">
        <h2>Exam Login</h2>
        <form method="POST">
            <input type="text" name="user" placeholder="Username" required>
            <input type="password" name="pass" placeholder="Password" required>
            <button type="submit">Login</button>
        </form>
        
        <div class="reg-link">
            Don't have an account? <a href="register.jsp">Register here</a>
        </div>

        <%
            // Logic to handle Login
            if(request.getMethod().equalsIgnoreCase("POST")) {
                String u = request.getParameter("user");
                String p = request.getParameter("pass");
                
                try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                    String query = "SELECT username FROM users WHERE username=? AND password=?";
                    PreparedStatement ps = conn.prepareStatement(query);
                    ps.setString(1, u);
                    ps.setString(2, p);
                    
                    ResultSet rs = ps.executeQuery();
                    
                    if(rs.next()) {
                        // Create a session for the user
                        session.setAttribute("username", u);
                        // Redirect to the exam page
                        response.sendRedirect("dashboard.jsp");
                    } else {
                        out.print("<p class='error'>Invalid Username or Password!</p>");
                    }
                } catch(Exception e) {
                    out.print("<p class='error'>Database Error: " + e.getMessage() + "</p>");
                }
            }
        %>
      </div>
    </div>
</body>
</html>