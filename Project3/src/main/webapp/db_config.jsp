<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%
    // Load the PostgreSQL Driver
    Class.forName("org.postgresql.Driver");

    // Read environment variables (set these in Koyeb's environment variables section)
    String envUrl  = System.getenv("DB_URL");
    String envUser = System.getenv("DB_USER");
    String envPass = System.getenv("DB_PASSWORD");

    // Use env variables when hosted, fallback to local for development
    String dbUrl = (envUrl  != null) ? envUrl  : "jdbc:postgresql://localhost:5432/Project";
    String user  = (envUser != null) ? envUser : "postgres";
    String pass  = (envPass != null) ? envPass : "fake_local_password";
%>