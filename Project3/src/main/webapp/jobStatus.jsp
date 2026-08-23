<%@ page language="java" contentType="application/json; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.JobStore, com.exam.util.JobStore.JobResult" %>
<%
    System.out.println("[jobStatus.jsp] === JOB STATUS REQUEST ===");
    System.out.println("[jobStatus.jsp] Parameters - jobId: " + request.getParameter("jobId") + ", cancel: " + request.getParameter("cancel"));
    
    if (session.getAttribute("username") == null) {
        System.out.println("[jobStatus.jsp] User not logged in");
        response.setStatus(401);
        out.print("{\"status\":\"error\",\"message\":\"Not logged in.\"}");
        return;
    }

    String jobId  = request.getParameter("jobId");
    String cancel = request.getParameter("cancel");

    if (jobId == null || jobId.trim().isEmpty()) {
        System.out.println("[jobStatus.jsp] Missing jobId");
        response.setStatus(400);
        out.print("{\"status\":\"error\",\"message\":\"Missing jobId.\"}");
        return;
    }

    // Disable caching so the browser always gets a fresh status
    response.setHeader("Cache-Control", "no-store");
    response.setHeader("Pragma", "no-cache");

    // Cancel path — mark the job cancelled and acknowledge
    if ("1".equals(cancel)) {
        System.out.println("[jobStatus.jsp] Cancel requested for job: " + jobId);
        JobStore.cancel(jobId);
        out.print("{\"status\":\"cancelled\"}");
        return;
    }

    System.out.println("[jobStatus.jsp] Getting result for job: " + jobId);
    JobResult result = JobStore.getResult(jobId);

    if (result == null) {
        // Unknown jobId (expired or never existed)
        System.out.println("[jobStatus.jsp] Job not found or expired: " + jobId);
        out.print("{\"status\":\"error\",\"message\":\"Job not found or expired.\"}");
        return;
    }

    System.out.println("[jobStatus.jsp] Job status: " + result.status + " for job: " + jobId);
    
    switch (result.status) {
        case PENDING:
            System.out.println("[jobStatus.jsp] Job still pending: " + jobId);
            out.print("{\"status\":\"pending\"}");
            break;

        case DONE:
            // Write the tid into the session so exam.jsp can use it
            System.out.println("[jobStatus.jsp] Job DONE, setting currentTid=" + result.tid + " in session");
            session.setAttribute("currentTid", result.tid);
            System.out.println("[jobStatus.jsp] Session attributes after setting: currentTopic=" + session.getAttribute("currentTopic") + ", currentTid=" + session.getAttribute("currentTid") + ", totalQuestions=" + session.getAttribute("totalQuestions"));
            // Clean up the job from the store
            JobStore.remove(jobId);
            out.print("{\"status\":\"done\"}");
            break;

        case ERROR:
            System.out.println("[jobStatus.jsp] Job ERROR: " + result.errorMessage);
            JobStore.remove(jobId);
            String safeMsg = result.errorMessage
                    .replace("\\", "\\\\")
                    .replace("\"", "\\\"")
                    .replace("\n", " ");
            out.print("{\"status\":\"error\",\"message\":\"" + safeMsg + "\"}");
            break;

        default:
            System.out.println("[jobStatus.jsp] Unknown job state: " + result.status);
            out.print("{\"status\":\"error\",\"message\":\"Unknown job state.\"}");
    }
    
    System.out.println("[jobStatus.jsp] Response sent for job: " + jobId);
%>