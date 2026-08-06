<%@ page import="com.exam.util.AIUtils, java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
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
            getServletContext().log("[generateQuestion.jsp] Failed to generate question", e);
            out.print("<p class='error'>Could not generate question. Please try again.</p>");
        }
    }
%>