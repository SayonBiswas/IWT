<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>

<nav class="navbar">
  <div class="navbar__inner">
    <a href="dashboard.jsp" class="navbar__logo">
      <span>📋</span> ExamHub
    </a>
    <ul class="navbar__links">
      <li><a href="dashboard.jsp">Dashboard</a></li>
      <li><a href="setup.jsp">Take Test</a></li>
      <li>
        <% if (session.getAttribute("username") != null) { %>
          <a href="logout.jsp" style="color: #ff4d4d; font-weight: 600;">Logout <%= session.getAttribute("username") %></a>
        <% } else { %>
          <a href="login.jsp">Login</a>
        <% } %>
      </li>
    </ul>
  </div>
</nav>