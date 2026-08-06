<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ include file="db_config.jsp" %>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Your Exam History</title>
<link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
<script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>
    <div class="page-shell" style="padding-top: 2rem;">
        <div class="card" style="width: 100%; max-width: 900px;">
            <div id="history-section">
                <h2 style="margin-bottom: 1.5rem;">Your Exam History</h2>
                <div class="table-wrap">
                    <table>
                        <thead>
                            <tr>
                                <th>Date</th>
                                <th>Topic</th>
                                <th>Score</th>
                                <th>Performance</th>
                            </tr>
                        </thead>
                        <tbody>
                        <%
                            try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                                String sql = "SELECT * FROM user_results WHERE username = ? ORDER BY test_date DESC";
                                PreparedStatement ps = conn.prepareStatement(sql);
                                ps.setString(1, (String)session.getAttribute("username"));
                                ResultSet rs = ps.executeQuery();
                                while (rs.next()) {
                                    int s = rs.getInt("score");
                                    int t = rs.getInt("total_questions");
                                    String perf = (s >= t/2.0) ? "✅ Pass" : "❌ Fail";
                        %>
                                <tr>
                                    <td><%= rs.getTimestamp("test_date") %></td>
                                    <td><strong><%= rs.getString("topic") %></strong></td>
                                    <td style="font-weight: 600; color: var(--sky);"><%= s %> / <%= t %></td>
                                    <td><%= perf %></td>
                                </tr>
                        <%
                                }
                            } catch (Exception e) { 
                                out.print("<tr><td colspan='4' class='error'>" + e.getMessage() + "</td></tr>");
                            }
                        %>
                        </tbody>
                    </table>
                </div>
                <br>
                <a href="dashboard.jsp" class="btn-home">Back to Dashboard</a>
            </div>
        </div>
    </div>
</body>
</html>