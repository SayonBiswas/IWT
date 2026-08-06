<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="org.mindrot.jbcrypt.BCrypt" %>
<%@ include file="db_config.jsp" %>
<%@ include file="navbar.jsp" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ExamHub - Register</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <div class="page-shell">
      <div class="card register-card">

        <div style="text-align:center; margin-bottom: 1.5rem;">
            <h2 style="margin-bottom: 0.5rem; text-align: center;">ExamHub</h2>
            <p style="text-align:center; font-size:0.85rem; color:var(--ink-muted); margin-bottom:1.5rem;">Create your account</p>
        </div>

        <form method="POST">
            <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">
            <div class="form-group">
                <label for="user">Username</label>
                <input type="text" id="user" name="user" placeholder="Username"
                       minlength="3" maxlength="30" required>
            </div>
            <div class="form-group">
                <label for="pass">Password</label>
                <input type="password" id="pass" name="pass" placeholder="Password"
                       minlength="8" maxlength="72" required>

                <!-- Strength meter — hidden until user starts typing -->
                <div id="pwd-meter" class="pwd-meter" style="display:none;">
                    <div class="pwd-bar-track">
                        <div id="pwd-bar" class="pwd-bar"></div>
                    </div>
                    <span id="pwd-label" class="pwd-label"></span>
                    <ul class="pwd-rules">
                        <li id="pwd-rule-0"><span class="pwd-rule-icon">○</span> At least 8 characters</li>
                        <li id="pwd-rule-1"><span class="pwd-rule-icon">○</span> One uppercase letter</li>
                        <li id="pwd-rule-2"><span class="pwd-rule-icon">○</span> One number</li>
                        <li id="pwd-rule-3"><span class="pwd-rule-icon">○</span> One special character</li>
                        <li id="pwd-rule-4"><span class="pwd-rule-icon">○</span> 12+ characters (strong)</li>
                    </ul>
                </div>
            </div>
            <div class="form-group">
                <label for="email">Email</label>
                <input type="email" id="email" name="email" placeholder="Email"
                       maxlength="100" required>
            </div>
            <button type="submit" class="btn-submit">Create Account</button>
        </form>
        <div class="reg-link">
            Already have an account? <a href="login.jsp">Login</a>
        </div>

        <%
            if (request.getMethod().equalsIgnoreCase("POST")) {
                String username = request.getParameter("user");
                String password = request.getParameter("pass");
                String email    = request.getParameter("email");

                // ── Server-side validation ──────────────────────────────
                String validationError = null;

                if (username == null || username.trim().isEmpty()) {
                    validationError = "Username is required.";
                } else if (username.length() < 3 || username.length() > 30) {
                    validationError = "Username must be 3–30 characters.";
                } else if (!username.matches("[a-zA-Z0-9_]+")) {
                    validationError = "Username may only contain letters, numbers, and underscores.";

                } else if (password == null || password.length() < 8) {
                    validationError = "Password must be at least 8 characters.";
                } else if (password.length() > 72) {
                    validationError = "Password must be 72 characters or fewer.";
                } else if (!password.matches(".*[0-9!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?].*")) {
                    validationError = "Password must contain at least one number or special character.";

                } else if (email == null || email.trim().isEmpty()) {
                    validationError = "Email is required.";
                } else if (!email.matches("^[^@\\s]+@[^@\\s]+\\.[^@\\s]{2,}$")) {
                    validationError = "Please enter a valid email address.";
                } else if (email.length() > 100) {
                    validationError = "Email must be 100 characters or fewer.";
                }

                if (validationError != null) {
                    out.print("<p class='error'>" + validationError + "</p>");
                } else {
                    // ── Safe to hash and insert ──────────────────────────
                    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                        String hashedPassword = BCrypt.hashpw(password, BCrypt.gensalt(12));
                        PreparedStatement ps = conn.prepareStatement(
                            "INSERT INTO users(username, password, email) VALUES(?,?,?)");
                        ps.setString(1, username.trim());
                        ps.setString(2, hashedPassword);
                        ps.setString(3, email.trim().toLowerCase());
                        ps.executeUpdate();
                        out.print("<script>alert('Registered!'); window.location='login.jsp';</script>");
                    } catch (Exception e) {
                        // log server-side only — don't expose stack trace
                        getServletContext().log("Registration error", e);
                        out.print("<p class='error'>Registration failed. Please try again.</p>");
                    }
                }
            }
        %>
      </div>
    </div>
</body>
</html>