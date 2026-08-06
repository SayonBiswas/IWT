<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    Object topicObj = session.getAttribute("currentTopic");
    Object limitObj = session.getAttribute("totalQuestions");
    if (topicObj == null || limitObj == null) {
        response.sendRedirect("setup.jsp");
        return;
    }
    String topic = (String) topicObj;
    int limit = (Integer) limitObj;
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Exam: <%= topic %></title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
<script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
      <div class="setup-card">

        <h2 style="color: var(--amber); text-align: center;">Examination in Progress</h2>
        <p style="text-align: center; margin-bottom: 2rem; font-size: 1.1rem;">
            Topic: <strong style="color: var(--ink);"><%= topic %></strong> |
            Questions: <strong style="color: var(--ink);"><%= limit %></strong>
        </p>
        <form id="examForm" action="result.jsp" method="POST">
            <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">
            <%
                try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                    Integer tid = (Integer) session.getAttribute("currentTid");
                    String sql = "SELECT * FROM questions WHERE tid = ? ORDER BY RANDOM() LIMIT ?";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setInt(1, tid);
                    ps.setInt(2, limit);
                    ResultSet rs = ps.executeQuery();
                    int count = 1;
                    while(rs.next()) {
                        String[] opts = (String[]) rs.getArray("qopts").getArray();
            %>
                        <div class="q-card">
                            <h3 style="margin-bottom: 1rem;"><%= count++ %>. <%= rs.getString("qtext") %></h3>
                            
                            <label class="option-container">
                                <input type="radio" name="q<%= rs.getInt("qid") %>" value="A" required> 
                                <span><%= opts[0] %></span>
                            </label>
                            
                            <label class="option-container">
                                <input type="radio" name="q<%= rs.getInt("qid") %>" value="B"> 
                                <span><%= opts[1] %></span>
                            </label>
                           
                            <label class="option-container">
                                <input type="radio" name="q<%= rs.getInt("qid") %>" value="C"> 
                                <span><%= opts[2] %></span>
                            </label>
                            
                            <label class="option-container">
                                <input type="radio" name="q<%= rs.getInt("qid") %>" value="D"> 
                                <span><%= opts[3] %></span>
                            </label>
                        </div>
            <%
                    }
                } catch(Exception e) { 
                    out.print("<div class='q-card error'>Database Error: " + e.getMessage() + "</div>");
                }
            %>
            <button type="submit" class="btn-submit" style="margin-top: 1.5rem; font-size: 1.1rem; padding: 1rem;">Finish &amp; Submit Exam</button>
        </form>
      </div>
    </div>
</body>
</html>