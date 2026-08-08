<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="org.apache.pdfbox.multipdf.PDFMergerUtility"%>
<%@ page import="javax.servlet.http.Part, java.util.*, java.io.*"%>
<%@ page contentType="text/html" %>
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
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <%-- ── POST handler: merge and stream PDF back ─────────────────────── --%>
    <%
        String pdfError = request.getParameter("error");

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            try {
                Collection<Part> parts = request.getParts();
                PDFMergerUtility merger = new PDFMergerUtility();
                int fileCount = 0;

                for (Part part : parts) {
                    if (!"pdfFiles".equals(part.getName())) continue;
                    if (part.getSize() == 0) continue;
                    String ct = part.getContentType();
                    if (ct == null || !ct.equals("application/pdf")) continue;

                    merger.addSource(part.getInputStream());
                    fileCount++;
                }

                if (fileCount < 2) {
                    pdfError = "Please upload at least 2 PDF files.";
                } else {
                    ByteArrayOutputStream baos = new ByteArrayOutputStream();
                    merger.setDestinationStream(baos);
                    merger.mergeDocuments(null);

                    // Stream merged PDF to browser as download
                    response.reset();
                    response.setContentType("application/pdf");
                    response.setHeader("Content-Disposition",
                        "attachment; filename=\"merged_output.pdf\"");
                    response.setContentLength(baos.size());
                    response.getOutputStream().write(baos.toByteArray());
                    response.getOutputStream().flush();
                    return;   // stop JSP rendering — we already wrote the response
                }

            } catch (Exception e) {
                getServletContext().log("[pdf_tools.jsp] PDF merge failed", e);
                pdfError = "Merge failed. Please ensure all files are valid PDFs.";
            }
        }
    %>

    <div class="page-shell">
        <div class="card" style="max-width:800px;">

            <div style="margin-bottom:1.5rem;">
                <h2 style="margin:0 0 0.5rem 0;">Combine PDF Documents</h2>
                <p style="margin:0; font-size:13px; color:var(--ink-muted);">
                    Upload 2 or more PDF files to merge them into one downloadable PDF.
                </p>
            </div>

            <% if (pdfError != null && !pdfError.isEmpty()) { %>
                <div class="info-note danger" style="margin-bottom:1.5rem;">
                    <span>✕</span><div><%= pdfError %></div>
                </div>
            <% } %>

            <form action="pdf_tools.jsp" method="POST"
                  enctype="multipart/form-data" id="mergeForm">
                <input type="hidden" name="_csrf"
                       value="<%= session.getAttribute("_csrf") %>">

                <div class="drop-zone" id="dropZone" style="margin-bottom:1.5rem;">
                    <div class="drop-zone__icon">📄</div>
                    <div class="drop-zone__title">Click to upload or drag and drop</div>
                    <div class="drop-zone__sub">PDF files only · Max 20 MB each</div>
                    <input type="file" name="pdfFiles" multiple
                           accept="application/pdf" id="pdfUploader"
                           style="display:none;">
                </div>

                <div id="fileList"></div>

                <div class="divider"></div>

                <div style="display:flex; align-items:center;
                            justify-content:space-between;
                            flex-wrap:wrap; gap:1rem;">
                    <div id="fileSummary"
                         style="font-size:12px; color:var(--ink-soft);">
                        No files selected
                    </div>
                    <button type="submit" id="mergeBtn" class="btn-primary"
                            style="width:auto; background:var(--red);" disabled>
                        Merge &amp; Download PDF
                    </button>
                </div>
            </form>
        </div>
    </div>

    <script>
    (function () {
        const dropZone = document.getElementById('dropZone');
        const uploader = document.getElementById('pdfUploader');
        const fileList = document.getElementById('fileList');
        const summary  = document.getElementById('fileSummary');
        const mergeBtn = document.getElementById('mergeBtn');

        let files = [];

        dropZone.addEventListener('click', () => uploader.click());

        dropZone.addEventListener('dragover', e => {
            e.preventDefault();
            dropZone.style.borderColor = 'var(--amber)';
        });
        dropZone.addEventListener('dragleave', () => {
            dropZone.style.borderColor = '';
        });
        dropZone.addEventListener('drop', e => {
            e.preventDefault();
            dropZone.style.borderColor = '';
            addFiles([...e.dataTransfer.files]);
        });

        uploader.addEventListener('change', () => {
            addFiles([...uploader.files]);
            uploader.value = '';
        });

        function addFiles(incoming) {
            incoming.forEach(f => {
                if (f.type !== 'application/pdf') {
                    alert(f.name + ' is not a PDF and was skipped.');
                    return;
                }
                if (f.size > 20 * 1024 * 1024) {
                    alert(f.name + ' exceeds the 20 MB limit and was skipped.');
                    return;
                }
                if (!files.find(x => x.name === f.name && x.size === f.size)) {
                    files.push(f);
                }
            });
            renderList();
        }

        window.removeFile = function (index) {
            files.splice(index, 1);
            renderList();
        };

        function renderList() {
            fileList.innerHTML = '';
            let totalSize = 0;

            files.forEach((f, i) => {
                totalSize += f.size;
                const sizeMB = (f.size / (1024 * 1024)).toFixed(2);
                const row = document.createElement('div');
                row.className = 'file-row';
                row.innerHTML = `
                    <div style="display:flex; align-items:center; gap:0.5rem;">
                        <span style="color:var(--ink-muted);">⠿</span>
                        <span style="color:var(--red);">📄</span>
                        <span style="color:var(--ink);">${f.name}</span>
                    </div>
                    <div style="color:var(--ink-muted); font-size:11px;
                                display:flex; align-items:center; gap:1rem;">
                        ${sizeMB} MB
                        <button type="button" onclick="removeFile(${i})"
                                style="background:none; border:none; cursor:pointer;
                                       color:var(--red); font-size:12px; padding:0;">
                            Remove
                        </button>
                    </div>`;
                fileList.appendChild(row);
            });

            const totalMB = (totalSize / (1024 * 1024)).toFixed(2);
            summary.textContent = files.length === 0
                ? 'No files selected'
                : `Total: ${files.length} file${files.length > 1 ? 's' : ''} (${totalMB} MB)`;

            mergeBtn.disabled = files.length < 2;

            const dt = new DataTransfer();
            files.forEach(f => dt.items.add(f));
            uploader.files = dt.files;
        }
    })();
    </script>
</body>
</html>