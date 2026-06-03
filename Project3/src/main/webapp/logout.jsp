<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
<%
    // 1. Clear all session data (username, topic, etc.)
    session.invalidate();

    // 2. Clear browser cache for security
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // 3. Redirect to login
    response.sendRedirect("login.jsp");
%>
</body>
</html>