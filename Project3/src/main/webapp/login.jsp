<%@ include file="db_config.jsp" %>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Login - Online Exam</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <%@ include file="navbar.jsp" %>
    
    <div class="page-shell">
      <div class="login-card">
        <h2 style="margin-bottom: 1.5rem; text-align: center;">Exam Login</h2>
        
        <form method="POST">
            <div class="form-group">
                <label>Username</label>
                <input type="text" name="user" placeholder="Username" required>
            </div>
            
            <div class="form-group">
                <label>Password</label>
                <input type="password" name="pass" placeholder="Password" required>
            </div>
            
            <button type="submit" class="btn-submit">Login</button>
        </form>
         
        <div class="reg-link">
            Don't have an account? <a href="register.jsp">Register here</a>
        </div>

        <%
            if(request.getMethod().equalsIgnoreCase("POST")) {
                String u = request.getParameter("user");
                String p = request.getParameter("pass");
                
                try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                    // CHANGED: Querying both username and role now
                    String query = "SELECT username, role FROM users WHERE username=? AND password=?";
                    PreparedStatement ps = conn.prepareStatement(query);
                    ps.setString(1, u);
                    ps.setString(2, p);
                    
                    ResultSet rs = ps.executeQuery();
                    if(rs.next()) {
                        String userRole = rs.getString("role");
                        if(userRole == null) { userRole = "student"; }

                        // Save identity parameters inside the HTTP Session
                        session.setAttribute("username", rs.getString("username"));
                        session.setAttribute("role", userRole);
                        
                        // CHANGED: Dynamic Role Router Logic
                        if("admin".equalsIgnoreCase(userRole)) {
                            response.sendRedirect("admin_dashboard.jsp");
                        } else {
                            response.sendRedirect("dashboard.jsp");
                        }
                    } else {
                        out.print("<p class='error' style='margin-top: 1rem;'>Invalid Username or Password!</p>");
                    }
                } catch(Exception e) {
                    out.print("<p class='error' style='margin-top: 1rem;'>Database Error: " + e.getMessage() + "</p>");
                }
            }
        %>
      </div>
    </div>
</body>
</html>