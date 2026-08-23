<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    // Simple database schema verification script
    // This helps diagnose schema compatibility issues
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Database Schema Check</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .ok { color: green; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .section { margin: 20px 0; padding: 15px; border: 1px solid #ccc; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Database Schema Verification</h1>
    
    <div class="section">
        <h2>Connection Test</h2>
        <%
            Connection conn = null;
            try {
                conn = DriverManager.getConnection(dbUrl, user, pass);
                out.println("<p class='ok'>✓ Database connection successful</p>");
                out.println("<p>Connected to: " + dbUrl + "</p>");
                
                DatabaseMetaData meta = conn.getMetaData();
                out.println("<p>Database: " + meta.getDatabaseProductName() + " " + meta.getDatabaseProductVersion() + "</p>");
            } catch (Exception e) {
                out.println("<p class='error'>✗ Database connection failed: " + e.getMessage() + "</p>");
                e.printStackTrace();
                return;
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        %>
    </div>

    <div class="section">
        <h2>Table Existence Check</h2>
        <%
            conn = null;
            try {
                conn = DriverManager.getConnection(dbUrl, user, pass);
                DatabaseMetaData meta = conn.getMetaData();
                
                String[] tables = {"users", "topics", "questions", "user_results"};
                for (String table : tables) {
                    ResultSet rs = meta.getTables(null, null, table, null);
                    if (rs.next()) {
                        out.println("<p class='ok'>✓ Table '" + table + "' exists</p>");
                    } else {
                        out.println("<p class='error'>✗ Table '" + table + "' NOT FOUND</p>");
                    }
                    rs.close();
                }
            } catch (Exception e) {
                out.println("<p class='error'>Error checking tables: " + e.getMessage() + "</p>");
                e.printStackTrace();
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        %>
    </div>

    <div class="section">
        <h2>Questions Table Schema</h2>
        <%
            conn = null;
            try {
                conn = DriverManager.getConnection(dbUrl, user, pass);
                DatabaseMetaData meta = conn.getMetaData();
                
                ResultSet columns = meta.getColumns(null, null, "questions", null);
                out.println("<table><tr><th>Column Name</th><th>Type</th><th>Size</th><th>Nullable</th></tr>");
                
                boolean hasQid = false;
                boolean hasQno = false;
                boolean hasQtext = false;
                boolean hasQopts = false;
                boolean hasQans = false;
                boolean hasTid = false;
                
                while (columns.next()) {
                    String colName = columns.getString("COLUMN_NAME");
                    String colType = columns.getString("TYPE_NAME");
                    int colSize = columns.getInt("COLUMN_SIZE");
                    String nullable = columns.getString("IS_NULLABLE");
                    
                    out.println("<tr><td>" + colName + "</td><td>" + colType + "</td><td>" + colSize + "</td><td>" + nullable + "</td></tr>");
                    
                    if (colName.equalsIgnoreCase("qid")) hasQid = true;
                    if (colName.equalsIgnoreCase("qno")) hasQno = true;
                    if (colName.equalsIgnoreCase("qtext")) hasQtext = true;
                    if (colName.equalsIgnoreCase("qopts")) hasQopts = true;
                    if (colName.equalsIgnoreCase("qans")) hasQans = true;
                    if (colName.equalsIgnoreCase("tid")) hasTid = true;
                }
                out.println("</table>");
                
                out.println("<h3>Required Column Check:</h3>");
                out.println("<p>" + (hasQid ? "<span class='ok'>✓</span>" : "<span class='error'>✗</span>") + " qid (should be SERIAL PRIMARY KEY)</p>");
                out.println("<p>" + (hasQno ? "<span class='ok'>✓</span>" : "<span class='error'>✗</span>") + " qno (question number)</p>");
                out.println("<p>" + (hasQtext ? "<span class='ok'>✓</span>" : "<span class='error'>✗</span>") + " qtext (question text)</p>");
                out.println("<p>" + (hasQopts ? "<span class='ok'>✓</span>" : "<span class='error'>✗</span>") + " qopts (should be TEXT[] array)</p>");
                out.println("<p>" + (hasQans ? "<span class='ok'>✓</span>" : "<span class='error'>✗</span>") + " qans (answer A-D)</p>");
                out.println("<p>" + (hasTid ? "<span class='ok'>✓</span>" : "<span class='error'>✗</span>") + " tid (topic ID foreign key)</p>");
                
                columns.close();
                
            } catch (Exception e) {
                out.println("<p class='error'>Error checking schema: " + e.getMessage() + "</p>");
                e.printStackTrace();
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        %>
    </div>

    <div class="section">
        <h2>Sample Data Check</h2>
        <%
            conn = null;
            try {
                conn = DriverManager.getConnection(dbUrl, user, pass);
                
                PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM questions");
                ResultSet rs = ps.executeQuery();
                rs.next();
                int questionCount = rs.getInt(1);
                out.println("<p>Total questions in database: <strong>" + questionCount + "</strong></p>");
                rs.close();
                ps.close();
                
                if (questionCount > 0) {
                    ps = conn.prepareStatement("SELECT qid, qno, qtext, qans, tid FROM questions LIMIT 5");
                    rs = ps.executeQuery();
                    out.println("<table><tr><th>qid</th><th>qno</th><th>qtext</th><th>qans</th><th>tid</th></tr>");
                    while (rs.next()) {
                        out.println("<tr><td>" + rs.getInt("qid") + "</td><td>" + rs.getInt("qno") + "</td><td>" + 
                                   rs.getString("qtext").substring(0, Math.min(50, rs.getString("qtext").length())) + "...</td><td>" + 
                                   rs.getString("qans") + "</td><td>" + rs.getInt("tid") + "</td></tr>");
                    }
                    out.println("</table>");
                    rs.close();
                    ps.close();
                } else {
                    out.println("<p class='warning'>⚠ No questions found in database. You need to generate questions first.</p>");
                }
                
            } catch (Exception e) {
                out.println("<p class='error'>Error checking data: " + e.getMessage() + "</p>");
                e.printStackTrace();
            } finally {
                if (conn != null) try { conn.close(); } catch (Exception e) {}
            }
        %>
    </div>

    <div class="section">
        <h2>Recommended Schema (if current schema is incorrect)</h2>
        <pre style="background: #f5f5f5; padding: 15px; border: 1px solid #ddd;">
CREATE TABLE IF NOT EXISTS users (
    username VARCHAR(50) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    email VARCHAR(100),
    role VARCHAR(20) DEFAULT 'user'
);

CREATE TABLE IF NOT EXISTS topics (
    tid SERIAL PRIMARY KEY,
    tname VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS questions (
    qid SERIAL PRIMARY KEY,
    qno INTEGER NOT NULL,
    qtext TEXT NOT NULL,
    qopts TEXT[] NOT NULL,
    qans VARCHAR(1) NOT NULL CHECK (qans IN ('A', 'B', 'C', 'D')),
    tid INTEGER NOT NULL REFERENCES topics(tid) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS user_results (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) NOT NULL REFERENCES users(username),
    topic VARCHAR(100) NOT NULL,
    score INTEGER NOT NULL,
    total_questions INTEGER NOT NULL,
    test_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
        </pre>
    </div>

    <div class="section">
        <h2>Action Items</h2>
        <%
            boolean hasIssues = false;
            // You could add logic here to detect specific issues
        %>
        <ol>
            <li>Check if all required columns exist (marked with ✓ above)</li>
            <li>Ensure <strong>qid</strong> is SERIAL PRIMARY KEY (auto-incrementing)</li>
            <li>Ensure <strong>qopts</strong> is of type TEXT[] (PostgreSQL array)</li>
            <li>Verify there are questions in the database (count > 0)</li>
            <li>Check server logs for detailed error messages when running the exam</li>
        </ol>
    </div>

    <p><a href="dashboard.jsp">← Back to Dashboard</a></p>
</body>
</html>
