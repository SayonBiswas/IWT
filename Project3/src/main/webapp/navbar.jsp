<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String currentURI    = request.getRequestURI();
    boolean isLoginPage    = currentURI.endsWith("login.jsp");
    boolean isRegisterPage = currentURI.endsWith("register.jsp");
    String  role           = (String) session.getAttribute("role");
    boolean isAdmin        = "admin".equalsIgnoreCase(role);
%>

<nav class="navbar">
  <div class="navbar__inner">
    <a href="dashboard.jsp" class="navbar__logo" style="text-decoration: none;">
      <span>📋</span> ExamHub
      <% if (isAdmin) { %>
        <li><a href="admin_dashboard.jsp" class="<%= currentURI.endsWith("admin_dashboard.jsp") ? "active" : "" %>">Overview</a></li>
        <li><a href="admin_dashboard.jsp">Database</a></li>
        <li>
          <a href="admin_dashboard.jsp">
            AI Queue <span class="badge badge-red" style="margin-left: 0.2rem;">3</span>
          </a>
        </li>
        <li><a href="admin_dashboard.jsp">Users</a></li>
       <% } %>
    </a>

    <ul class="navbar__links">
      <% if (session.getAttribute("username") != null) { %>

        <%-- Admin Navigation --%>
        <% if (isAdmin) { %>
          <li><a href="admin_dashboard.jsp" class="<%= currentURI.endsWith("admin_dashboard.jsp") ? "active" : "" %>">Overview</a></li>
          <li><a href="admin_dashboard.jsp">Database</a></li>
          <li><a href="admin_dashboard.jsp">Users</a></li>

        <%-- Student Navigation --%>
        <% } else { %>
          <li><a href="dashboard.jsp" class="<%= currentURI.endsWith("dashboard.jsp") ? "active" : "" %>">Dashboard</a></li>
          <li><a href="setup.jsp" class="<%= currentURI.endsWith("setup.jsp") || currentURI.endsWith("exam.jsp") ? "active" : "" %>">Exams</a></li>
          <li><a href="notes.jsp" class="<%= currentURI.endsWith("notes.jsp") ? "active" : "" %>">Notes</a></li>
          <li><a href="pdf_tools.jsp" class="<%= currentURI.endsWith("pdf_tools.jsp") ? "active" : "" %>">PDF Tools</a></li>
        <% } %>

        <li>
          <a href="logout.jsp" class="nav-danger">
            Logout <%= session.getAttribute("username") %>
          </a>
        </li>
      <% } else { %>
        <% if (isLoginPage) { %>
          <li><a href="register.jsp">Register</a></li>
        <% } else if (isRegisterPage) { %>
          <li><a href="login.jsp">Login</a></li>
        <% } else { %>
          <li><a href="login.jsp">Login</a></li>
          <li><a href="register.jsp">Register</a></li>
        <% } %>
      <% } %>

      <li>
        <button class="theme-toggle" id="themeBtn" title="Toggle light/dark mode">🌙</button>
      </li>
    </ul>
  </div>
</nav>

<script>
(function () {
  var html  = document.documentElement;
  var btn   = document.getElementById('themeBtn');
  var saved = localStorage.getItem('eh-theme') || 'dark';

  function applyTheme(t) {
    if (t === 'light') {
      html.setAttribute('data-theme', 'light');
      if (btn) btn.textContent = '☀️';
    } else {
      html.removeAttribute('data-theme');
      if (btn) btn.textContent = '🌙';
    }
    localStorage.setItem('eh-theme', t);
  }

  applyTheme(saved);

  if (btn) {
    btn.addEventListener('click', function () {
      var current = localStorage.getItem('eh-theme') || 'dark';
      applyTheme(current === 'dark' ? 'light' : 'dark');
    });
  }
})();
</script>