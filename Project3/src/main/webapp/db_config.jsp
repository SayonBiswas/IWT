<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
</head>
<body>
<%@ page import="java.sql.*" %>
<%
    Class.forName("org.postgresql.Driver");
	String dbUrl = "jdbc:postgresql://localhost:5432/Project";
	String user = "postgres";
	String pass = "1234";
%>
</body>
</html>