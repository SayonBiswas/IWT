<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8"%>
<%@ include file="db_config.jsp" %>
<%@ include file="navbar.jsp" %>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Insert title here</title>
<link rel="stylesheet" href="style.css">
</head>
<body>
	<div class="container">
		<div id="history-section">
			<h2>Your Exam History</h2>
            <table>
                <tr>
                    <th>Date</th>
                    <th>Topic</th>
                    <th>Score</th>
                    <th>Performance</th>
                </tr>
                <%
                    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
                        String sql = "SELECT * FROM user_results WHERE username = ? ORDER BY test_date DESC";
                        PreparedStatement ps = conn.prepareStatement(sql);
                        ps.setString(1, (String)session.getAttribute("username"));
                        ResultSet rs = ps.executeQuery();
                        while (rs.next()) {
                            int s = rs.getInt("score");
                            int t = rs.getInt("total_questions");
                            String perf = (s >= t/2) ? "✅ Pass" : "❌ Fail";
                %>
                        <tr>
                            <td><%= rs.getTimestamp("test_date") %></td>
                            <td><%= rs.getString("topic") %></td>
                            <td><%= s %> / <%= t %></td>
                            <td><%= perf %></td>
                        </tr>
                <%
                        }
                    } catch (Exception e) { out.print(e.getMessage()); }
                %>
            </table>
        </div>
	</div>
</body>
</html>