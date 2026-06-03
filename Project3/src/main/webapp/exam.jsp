<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    // 1. Get objects from session
    Object topicObj = session.getAttribute("currentTopic");
    Object limitObj = session.getAttribute("totalQuestions");

    // 2. SAFETY CHECK: If the user skipped setup, redirect them back
    if (topicObj == null || limitObj == null) {
        response.sendRedirect("setup.jsp");
        return; // Stop processing the rest of the page
    }

    // 3. Now it is safe to cast and unbox
    String topic = (String) topicObj;
    int limit = (Integer) limitObj; 
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Exam: <%= topic %></title>
	<link rel="stylesheet" href="style.css">	
</head>
<body>
    <%@ include file="navbar.jsp" %>
    <div class="page-shell" style="padding-top: 2rem;">
      <div>
        <h2>Online Examination</h2>
        <div class="header-info">
        Topic: <strong><%= topic %></strong> | Questions: <strong><%= limit %></strong>
    </div>

    <form id="examForm" action="result.jsp" method="POST">
        <%
            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                String sql = "SELECT q.* FROM questions q JOIN topics t ON q.tid = t.tid WHERE t.tname ILIKE ? ORDER BY RANDOM() LIMIT ?";
                PreparedStatement ps = conn.prepareStatement(sql);
                ps.setString(1, topic);
                ps.setInt(2, limit);
                ResultSet rs = ps.executeQuery();
                int count = 1;
                while(rs.next()) {
                    String[] opts = (String[]) rs.getArray("qopts").getArray(); // Handle Array
        %>
                    <div class="q-card">
                        <h3><%= count++ %>. <%= rs.getString("qtext") %></h3>
                        
                        <label class="option-container">
                            <input type="radio" name="q<%= rs.getInt("qid") %>" value="A" required> 
                            <%= opts[0] %>
                        </label>
                        
                        <label class="option-container">
                            <input type="radio" name="q<%= rs.getInt("qid") %>" value="B"> 
                            <%= opts[1] %>
                        </label>
                        
                        <label class="option-container">
                            <input type="radio" name="q<%= rs.getInt("qid") %>" value="C"> 
                            <%= opts[2] %>
                        </label>
                        
                        <label class="option-container">
                            <input type="radio" name="q<%= rs.getInt("qid") %>" value="D"> 
                            <%= opts[3] %>
                        </label>
                    </div>
        <%
                }
            } catch(Exception e) { 
                out.print("<div class='q-card' style='color:red;'>Database Error: " + e.getMessage() + "</div>"); 
            }
        %>
        <button type="submit">Finish &amp; Submit Exam</button>
    </form>
      </div>
    </div>
</body>
</html>