<%@ page import="com.exam.util.AIUtils, java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    String topic = request.getParameter("topic");
    String count = request.getParameter("qCount");
    String source = request.getParameter("source"); // "old" or "new"

    if (topic != null) {
        try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
            // We pass 'source' to determine if we use AI or DB
            boolean success = AIUtils.prepareQuestions(conn, topic, source);
            
            if (success) {
                session.setAttribute("currentTopic", topic);
                session.setAttribute("totalQuestions", Integer.parseInt(count));
                response.sendRedirect("exam.jsp");
            } else {
                out.print("<script>alert('No existing questions found for this topic. Please select New Questions.'); window.location='setup.jsp';</script>");
            }
        } catch(Exception e) { 
            e.printStackTrace(); 
            out.print("Error: " + e.getMessage());
        }
    }
%>