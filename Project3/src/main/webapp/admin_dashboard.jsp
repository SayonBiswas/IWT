<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>

<%-- Imports your database credentials from your config file --%>
<%@ include file="db_config.jsp" %>

<%! 
    // Java Helper Function: Generates an HTML table wrapped in your dark theme styling
    public String renderHtmlTable(Connection conn, String dbTableName, String displayTitle) {
        StringBuilder html = new StringBuilder();
        
        // Wrapping the table in your custom .box class to match the theme
        html.append("<div class='box' style='margin-top: 2rem; padding: 1.5rem;'>");
        html.append("<h3 style='color: var(--amber); margin-bottom: 1rem;'>").append(displayTitle).append("</h3>");
        
        // Using your .table-wrap class for mobile responsiveness
        html.append("<div class='table-wrap'><table>");
        html.append("<thead><tr>");
        
        try (Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery("SELECT * FROM " + dbTableName)) {
             
            ResultSetMetaData metaData = rs.getMetaData();
            int columnCount = metaData.getColumnCount();
            
            // 1. Generate Headers
            for (int i = 1; i <= columnCount; i++) {
                html.append("<th>").append(metaData.getColumnName(i)).append("</th>");
            }
            html.append("</tr></thead><tbody>");
            
            // 2. Generate Data Rows
            while (rs.next()) {
                html.append("<tr>");
                for (int i = 1; i <= columnCount; i++) {
                    html.append("<td>").append(rs.getString(i)).append("</td>");
                }
                html.append("</tr>");
            }
            
        } catch (Exception e) {
            html.append("<tr><td colspan='100%' class='error'>Database Error: ").append(e.getMessage()).append("</td></tr>");
        }
        
        html.append("</tbody></table></div></div>");
        return html.toString();
    }
%>

<%
    // Security Gatekeeper Check: Kick unauthorized users back to login
    if (session.getAttribute("username") == null || !"admin".equalsIgnoreCase((String)session.getAttribute("role"))) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Command Center</title>
    <link rel="stylesheet" href="style.css">
</head>
<body>
    <%@ include file="navbar.jsp" %>
    
    <div class="page-shell" style="padding-top: 2rem;">
      <div class="card" style="width: 100%; max-width: 1000px;">
        <h1 style="margin-bottom: 1rem; color: var(--amber);">Admin Command Center</h1>
        <p>Logged in as: <strong style="color: var(--amber-glow);"><%= session.getAttribute("username") %></strong> (Administrator)</p>
        
        <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 1.5rem; margin-top: 2rem;">
            <div class="box">
                <h3 style="color: var(--amber); margin-bottom: 0.5rem;">System Analytics</h3>
                <p>Monitor platform statistics, total exams created, and overall user performance ratios globally.</p>
                <a href="#" class="btn-submit" style="display:inline-block; text-align:center; text-decoration:none;">View Metrics</a>
            </div>
            
            <div class="box">
                <h3 style="color: var(--amber); margin-bottom: 0.5rem;">Question Database</h3>
                <p>Review, modify, or manually purge AI-generated multi-choice layout elements inside table banks.</p>
                <a href="#" class="btn-submit" style="display:inline-block; text-align:center; text-decoration:none;">Manage Bank</a>
            </div>
        </div>

        <div style="margin-top: 3rem; border-top: 1px solid var(--border); padding-top: 1rem;">
            <h2 style="color: var(--ink);">Database Overview</h2>
            
            <%
                Connection conn = null;
                
                try {
                    Class.forName("org.postgresql.Driver");
                    
                    // We use the dbUrl, dbUser, and dbPass variables that were automatically 
                    // brought in by the db_config.jsp include at the very top of the file!
                    conn = DriverManager.getConnection(dbUrl, user, pass);
                    
                    // Render all 4 tables automatically
                    out.print(renderHtmlTable(conn, "users", "System Users"));
                    out.print(renderHtmlTable(conn, "topics", "Exam Topics"));
                    out.print(renderHtmlTable(conn, "questions", "Question Bank Master list"));
                    out.print(renderHtmlTable(conn, "test_results", "Student Test Records"));
                    
                } catch (Exception e) {
                    out.print("<div class='error'>Failed to connect to database: " + e.getMessage() + "</div>");
                } finally {
                    if (conn != null) {
                        try { conn.close(); } catch (SQLException ignore) {}
                    }
                }
            %>
        </div>
        
      </div>
    </div>
</body>
</html>