<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.AIUtils, java.sql.*" %>
<%@ include file="db_config.jsp" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String topic  = request.getParameter("topic");
    String count  = request.getParameter("qCount");
    String source = request.getParameter("source");

    if (topic == null || topic.trim().isEmpty() || count == null || source == null) {
        response.sendRedirect("setup.jsp");
        return;
    }

    topic = topic.trim();

    try (Connection conn = DriverManager.getConnection(dbUrl, user, pass)) {
        int tid = AIUtils.prepareQuestions(conn, topic, source);

        if (tid == -1) {
            out.print("<script>alert('No questions found for \"" + topic + "\". " +
                      "Please choose a different topic or use AI Generated.'); " +
                      "window.location='setup.jsp';</script>");
            return;
        }

        if (source.equals("database")) {
            PreparedStatement check = conn.prepareStatement(
                "SELECT COUNT(*) FROM questions WHERE tid = ?");
            check.setInt(1, tid);
            ResultSet rs = check.executeQuery();
            rs.next();
            if (rs.getInt(1) == 0) {
                out.print("<script>alert('The topic \"" + topic + "\" exists but has no questions " +
                          "in the database yet. Please use AI Generated instead.'); " +
                          "window.location='setup.jsp';</script>");
                return;
            }
        }

        session.setAttribute("currentTid", tid);
        session.setAttribute("currentTopic", topic);
        session.setAttribute("totalQuestions", Integer.parseInt(count));
        response.sendRedirect("exam.jsp");

    } catch (Exception e) {
        getServletContext().log("[generateQuestion.jsp] Failed to prepare questions", e);
        out.print("<script>alert('Something went wrong. Please try again.'); " +
                  "window.location='setup.jsp';</script>");
    }
%>