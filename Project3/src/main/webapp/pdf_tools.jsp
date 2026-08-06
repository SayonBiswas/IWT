<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%-- YOUR SECURITY/BACKEND LOGIC HERE (Session check) --%>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ExamHub - PDF Tools</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <script type="module" src="${pageContext.request.contextPath}/static/main.js"></script>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="page-shell">
        <div class="card" style="max-width: 800px;">

            <div style="margin-bottom: 1.5rem;">
                <h2 style="margin: 0 0 0.5rem 0;">Combine PDF Documents</h2>
                <p style="margin:0; font-size: 13px; color: var(--ink-muted);">Drag and drop multiple PDF notes or assignments to merge them.</p>
            </div>

            <form action="mergePdfServlet" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="_csrf" value="<%= session.getAttribute("_csrf") %>">

                <!-- Styled Drag & Drop Zone from style.css -->
                <div class="drop-zone" style="margin-bottom: 1.5rem;">
                    <div class="drop-zone__icon">📄</div>
                    <div class="drop-zone__title">Click to upload or drag and drop</div>
                    <div class="drop-zone__sub">PDF files only (Max 20MB)</div>
                    <input type="file" name="pdfFiles" multiple accept="application/pdf" style="display: none;" id="pdfUploader">
                </div>

                <!-- List of uploaded files to merge -->
                <div class="file-row">
                    <div style="display: flex; align-items: center; gap: 0.5rem;">
                        <span style="color: var(--ink-muted);">⠿</span>
                        <span style="color: var(--red);">📄</span>
                        <span style="color: var(--ink);">OS_Unit1_Notes.pdf</span>
                    </div>
                    <div style="color: var(--ink-muted); font-size: 11px;">
                        1.2 MB
                        <a href="#" class="link" style="color: var(--red); margin-left: 1rem;">Remove</a>
                    </div>
                </div>

                <div class="divider"></div>

                <div style="display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; gap: 1rem;">
                    <div style="font-size: 12px; color: var(--ink-soft);">Total: 1 file (1.2 MB)</div>
                    <button type="submit" class="btn-primary" style="width: auto; background: var(--red);">Merge &amp; Download PDF</button>
                </div>
            </form>

        </div>
    </div>

    <!-- Optional JS to trigger file upload click -->
    <script>
        document.querySelector('.drop-zone').addEventListener('click', function() {
            document.getElementById('pdfUploader').click();
        });
    </script>
</body>
</html>