<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.JobStore, com.exam.util.JobStore.JobResult" %>
<%
    if (session.getAttribute("username") == null) {
        response.setStatus(401);
        out.print("{\"status\":\"error\",\"message\":\"Not logged in.\"}");
        return;
    }

    String jobId  = request.getParameter("jobId");
    String cancel = request.getParameter("cancel");

    if (jobId == null || jobId.trim().isEmpty()) {
        response.setStatus(400);
        out.print("{\"status\":\"error\",\"message\":\"Missing jobId.\"}");
        return;
    }

    // Disable caching so the browser always gets a fresh status
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Pragma", "no-cache");

    // Cancel path — mark the job cancelled and acknowledge
    if ("1".equals(cancel)) {
        JobStore.cancel(jobId);
        out.print("{\"status\":\"cancelled\"}");
        return;
    }

    JobResult result = JobStore.getResult(jobId);

    if (result == null) {
        // Unknown jobId (expired or never existed)
        out.print("{\"status\":\"error\",\"message\":\"Job not found or expired.\"}");
        return;
    }

    switch (result.status) {
        case PENDING:
            out.print("{\"status\":\"pending\"}");
            break;

        case DONE:
            // Write the tid into the session so exam.jsp can use it
            session.setAttribute("currentTid", result.tid);
            // Clean up the job from the store
            JobStore.remove(jobId);
            out.print("{\"status\":\"done\"}");
            break;

        case ERROR:
            JobStore.remove(jobId);
            String safeMsg = result.errorMessage
                    .replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", " ");
            out.print("{\"status\":\"error\",\"message\":\"" + safeMsg + "\"}");
            break;

        default:
            out.print("{\"status\":\"error\",\"message\":\"Unknown job state.\"}");
    }
%>