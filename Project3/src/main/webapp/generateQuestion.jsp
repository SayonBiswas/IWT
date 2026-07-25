<%@ page import="com.exam.util.AIUtils, java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    String topic = request.getParameter("topic");
    String count = request.getParameter("qCount");
    String source = request.getParameter("source");

    if (topic != null) {
        try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
            int tid = AIUtils.prepareQuestions(conn, topic, source);
            if (tid != -1) {
                session.setAttribute("currentTid", tid);
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