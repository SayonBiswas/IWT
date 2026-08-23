<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, com.exam.util.DBConnectionPool, com.exam.util.QuestionCache" %>
<%
    // Debug page to manually test the exam functionality
    System.out.println("[debug_exam.jsp] === DEBUG EXAM PAGE ===");
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Exam Debug</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ccc; }
        .ok { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .info { color: blue; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        input, select { padding: 8px; margin: 5px; }
        button { padding: 10px 15px; margin: 5px; cursor: pointer; }
    </style>
</head>
<body>
    <h1>Exam System Debug</h1>
    
    <div class="section">
        <h2>Session Status</h2>
        <p><strong>Username:</strong> <%= session.getAttribute("username") %></p>
        <p><strong>currentTopic:</strong> <%= session.getAttribute("currentTopic") %></p>
        <p><strong>currentTid:</strong> <%= session.getAttribute("currentTid") %></p>
        <p><strong>totalQuestions:</strong> <%= session.getAttribute("totalQuestions") %></p>
    </div>

    <div class="section">
        <h2>Manual Topic Query Test</h2>
        <form method="post">
            <label>Topic Name: <input type="text" name="testTopic" value="Java" required></label>
            <button type="submit" name="action" value="testTopic">Test Topic Lookup</button>
        </form>
        
        <%
            if ("testTopic".equals(request.getParameter("action"))) {
                String testTopic = request.getParameter("testTopic");
                Connection conn = null;
                try {
                    conn = DBConnectionPool.getConnection();
                    System.out.println("[debug_exam.jsp] Testing topic lookup for: " + testTopic);
                    
                    // Test topic lookup
                    String sql = "SELECT tid FROM topics WHERE tname ILIKE ?";
                    PreparedStatement ps = conn.prepareStatement(sql);
                    ps.setString(1, testTopic);
                    ResultSet rs = ps.executeQuery();
                    
                    if (rs.next()) {
                        int tid = rs.getInt("tid");
                        out.println("<p class='ok'>✓ Topic found: tid=" + tid + "</p>");
                        
                        // Test question count
                        PreparedStatement countPs = conn.prepareStatement("SELECT COUNT(*) FROM questions WHERE tid = ?");
                        countPs.setInt(1, tid);
                        ResultSet countRs = countPs.executeQuery();
                        countRs.next();
                        int qCount = countRs.getInt(1);
                        out.println("<p class='info'>Questions in database for this topic: " + qCount + "</p>");
                        countRs.close();
                        countPs.close();
                        
                        // Test question fetch
                        if (qCount > 0) {
                            PreparedStatement qPs = conn.prepareStatement("SELECT qid, qtext, qopts, qans FROM questions WHERE tid = ? LIMIT 3");
                            qPs.setInt(1, tid);
                            ResultSet qRs = qPs.executeQuery();
                            
                            out.println("<h3>Sample Questions:</h3>");
                            out.println("<table><tr><th>qid</th><th>qtext</th><th>qans</th></tr>");
                            while (qRs.next()) {
                                out.println("<tr><td>" + qRs.getInt("qid") + "</td><td>" + 
                                           qRs.getString("qtext").substring(0, Math.min(50, qRs.getString("qtext").length())) + "...</td><td>" + 
                                           qRs.getString("qans") + "</td></tr>");
                            }
                            out.println("</table>");
                            qRs.close();
                            qPs.close();
                        }
                        
                        // Set session attributes for testing
                        session.setAttribute("currentTopic", testTopic);
                        session.setAttribute("currentTid", tid);
                        session.setAttribute("totalQuestions", Math.min(qCount, 10));
                        out.println("<p class='ok'>✓ Session attributes set for testing</p>");
                        out.println("<p><a href='exam.jsp'>Test with exam.jsp</a></p>");
                        
                    } else {
                        out.println("<p class='error'>✗ Topic not found: " + testTopic + "</p>");
                    }
                    rs.close();
                    ps.close();
                    
                } catch (Exception e) {
                    out.println("<p class='error'>✗ Error: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (conn != null) try { DBConnectionPool.releaseConnection(conn); } catch (Exception e) {}
                }
            }
        %>
    </div>

    <div class="section">
        <h2>Direct Database Query</h2>
        <form method="post">
            <label>SQL Query: <input type="text" name="sqlQuery" value="SELECT * FROM topics LIMIT 5" style="width: 400px;"></label>
            <button type="submit" name="action" value="runQuery">Run Query</button>
        </form>
        
        <%
            if ("runQuery".equals(request.getParameter("action"))) {
                String sqlQuery = request.getParameter("sqlQuery");
                Connection conn = null;
                try {
                    conn = DBConnectionPool.getConnection();
                    System.out.println("[debug_exam.jsp] Running query: " + sqlQuery);
                    
                    PreparedStatement ps = conn.prepareStatement(sqlQuery);
                    ResultSet rs = ps.executeQuery();
                    
                    ResultSetMetaData meta = rs.getMetaData();
                    int colCount = meta.getColumnCount();
                    
                    out.println("<table><tr>");
                    for (int i = 1; i <= colCount; i++) {
                        out.println("<th>" + meta.getColumnName(i) + "</th>");
                    }
                    out.println("</tr>");
                    
                    while (rs.next()) {
                        out.println("<tr>");
                        for (int i = 1; i <= colCount; i++) {
                            out.println("<td>" + rs.getString(i) + "</td>");
                        }
                        out.println("</tr>");
                    }
                    out.println("</table>");
                    
                    rs.close();
                    ps.close();
                    
                } catch (Exception e) {
                    out.println("<p class='error'>✗ Query error: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                } finally {
                    if (conn != null) try { DBConnectionPool.releaseConnection(conn); } catch (Exception e) {}
                }
            }
        %>
    </div>

    <div class="section">
        <h2>Cache Status</h2>
        <p>Cache size: <%= QuestionCache.size() %></p>
        <p><a href="debug_exam.jsp?action=clearCache">Clear Cache</a></p>
        
        <%
            if ("clearCache".equals(request.getParameter("action"))) {
                QuestionCache.clear();
                out.println("<p class='ok'>✓ Cache cleared</p>");
            }
        %>
    </div>

    <div class="section">
        <h2>Test Question Fetch</h2>
        <form method="post">
            <label>Topic ID: <input type="number" name="testTid" value="1"></label>
            <label>Topic Name: <input type="text" name="testTopicName" value="Java"></label>
            <label>Limit: <input type="number" name="testLimit" value="5"></label>
            <button type="submit" name="action" value="testFetch">Test Fetch</button>
        </form>
        
        <%
            if ("testFetch".equals(request.getParameter("action"))) {
                int testTid = Integer.parseInt(request.getParameter("testTid"));
                String testTopicName = request.getParameter("testTopicName");
                int testLimit = Integer.parseInt(request.getParameter("testLimit"));
                
                System.out.println("[debug_exam.jsp] Testing fetch - tid=" + testTid + ", topic=" + testTopicName + ", limit=" + testLimit);
                
                try {
                    // Test cache first
                    List<Map<String, Object>> cachedQuestions = QuestionCache.get(testTopicName, testTid);
                    if (cachedQuestions != null) {
                        out.println("<p class='ok'>✓ Cache HIT: " + cachedQuestions.size() + " questions</p>");
                    } else {
                        out.println("<p class='info'>Cache MISS, fetching from database...</p>");
                        
                        // Test database fetch
                        Connection conn = DBConnectionPool.getConnection();
                        String sql = "SELECT qid, qtext, qopts, qans FROM questions WHERE tid = ? ORDER BY random() LIMIT ?";
                        PreparedStatement ps = conn.prepareStatement(sql);
                        ps.setInt(1, testTid);
                        ps.setInt(2, testLimit);
                        ResultSet rs = ps.executeQuery();
                        
                        List<Map<String, Object>> questions = new ArrayList<>();
                        while (rs.next()) {
                            Map<String, Object> question = new HashMap<>();
                            question.put("qid", rs.getInt("qid"));
                            question.put("qtext", rs.getString("qtext"));
                            question.put("qopts", rs.getArray("qopts").getArray());
                            question.put("qans", rs.getString("qans"));
                            questions.add(question);
                        }
                        
                        out.println("<p class='ok'>✓ Database fetch successful: " + questions.size() + " questions</p>");
                        
                        // Cache the results
                        QuestionCache.put(testTopicName, testTid, questions);
                        out.println("<p class='info'>✓ Results cached</p>");
                        
                        // Display sample
                        out.println("<h3>Sample Questions:</h3>");
                        for (int i = 0; i < Math.min(2, questions.size()); i++) {
                            Map<String, Object> q = questions.get(i);
                            String[] opts = (String[]) q.get("qopts");
                            out.println("<p><strong>Q" + (i+1) + ":</strong> " + q.get("qtext") + "</p>");
                            out.println("<p>Answer: " + q.get("qans") + "</p>");
                        }
                        
                        rs.close();
                        ps.close();
                        DBConnectionPool.releaseConnection(conn);
                    }
                    
                } catch (Exception e) {
                    out.println("<p class='error'>✗ Fetch error: " + e.getMessage() + "</p>");
                    e.printStackTrace();
                }
            }
        %>
    </div>

    <div class="section">
        <h2>Quick Actions</h2>
        <p><a href="db_schema_check.jsp">Database Schema Check</a></p>
        <p><a href="setup.jsp">Go to Setup</a></p>
        <p><a href="dashboard.jsp">Go to Dashboard</a></p>
    </div>
</body>
</html>
