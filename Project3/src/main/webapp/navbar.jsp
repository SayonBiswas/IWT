<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Determine the current page filename to conditionally toggle navigation tabs
    String currentURI = request.getRequestURI();
    boolean isLoginPage = currentURI.endsWith("login.jsp");
    boolean isRegisterPage = currentURI.endsWith("register.jsp");
%>

<nav class="navbar">
  <div class="navbar__inner">
    <a href="dashboard.jsp" class="navbar__logo">
      <span>📋</span> ExamHub
    </a>
    <ul class="navbar__links">
      <% if (session.getAttribute("username") != null) { %>
        <li><a href="dashboard.jsp">Dashboard</a></li>
        <li><a href="setup.jsp">Take Test</a></li>
        <li>
          <a href="logout.jsp" style="color: #ff4d4d; font-weight: 600;">Logout <%= session.getAttribute("username") %></a>
        </li>
      <% } else { %>
        <% if (isLoginPage) { %>
          <li><a href="register.jsp" style="font-weight: 600; color: var(--amber);">Register</a></li>
        <% } else if (isRegisterPage) { %>
          <li><a href="login.jsp" style="font-weight: 600; color: var(--amber);">Login</a></li>
        <% } else { %>
          <li><a href="login.jsp">Login</a></li>
          <li><a href="register.jsp">Register</a></li>
        <% } %>
      <% } %>
    </ul>
  </div>
</nav>