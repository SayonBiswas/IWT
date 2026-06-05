<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Load the PostgreSQL Driver
    Class.forName("org.postgresql.Driver");

    // Tell Java to look for secure environment variables when hosted on the internet
    String envUrl = System.getenv("JDBC_DATABASE_URL");
    String envUser = System.getenv("JDBC_DATABASE_USERNAME");
    String envPass = System.getenv("JDBC_DATABASE_PASSWORD");

    // If those variables exist (like on Render), use them! 
    // Otherwise, fallback to fake details so you don't expose your real password in the code.
    String dbUrl = (envUrl != null) ? envUrl : "jdbc:postgresql://localhost:5432/Project";
    String user  = (envUser != null) ? envUser : "postgres";
    String pass  = (envPass != null) ? envPass : "fake_local_password";
%>