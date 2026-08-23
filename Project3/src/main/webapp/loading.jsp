<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.exam.util.JobStore" %>
<%
    System.out.println("[loading.jsp] === LOADING PAGE START ===");
    System.out.println("[loading.jsp] Parameters - jobId: " + request.getParameter("jobId"));
    
    if (session.getAttribute("username") == null) {
        System.out.println("[loading.jsp] User not logged in");
        response.sendRedirect("login.jsp");
        return;
    }

    String jobId = request.getParameter("jobId");
    System.out.println("[loading.jsp] JobId from request: " + jobId);
    
    if (jobId == null || jobId.trim().isEmpty()) {
        System.out.println("[loading.jsp] JobId is null or empty");
        response.sendRedirect("setup.jsp");
        return;
    }
    
    if (!JobStore.exists(jobId)) {
        System.out.println("[loading.jsp] Job does not exist in JobStore: " + jobId);
        response.sendRedirect("setup.jsp");
        return;
    }
    
    System.out.println("[loading.jsp] Job exists in JobStore: " + jobId);

    String topic = (String) session.getAttribute("currentTopic");
    if (topic == null) topic = "your topic";
    System.out.println("[loading.jsp] Topic from session: " + topic);
%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generating Questions...</title>
    <link rel="stylesheet" href="${pageContext.request.contextPath}/style.css?1.1">
    <style>
        @keyframes spin    { to { transform: rotate(360deg); } }
        @keyframes fadeIn  { from { opacity: 0; transform: translateY(8px); } to { opacity: 1; transform: translateY(0); } }
        @keyframes pulse   { 0%, 100% { opacity: 1; } 50% { opacity: 0.4; } }

        .loading-wrap {
            position: fixed;
            inset: 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            gap: 1.5rem;
            background: var(--bg-page);
        }

        .spinner {
            width: 52px; height: 52px;
            border: 4px solid var(--border);
            border-top-color: var(--accent-light);
            border-radius: 50%;
            animation: spin 0.8s linear infinite;
        }

        .loading-title {
            font-size: 1.1rem;
            font-weight: 600;
            color: var(--ink);
            margin: 0 0 0.35rem 0;
        }

        .loading-sub {
            font-size: 0.875rem;
            color: var(--ink-muted);
            margin: 0;
        }

        .loading-topic {
            color: var(--accent-light);
            font-weight: 600;
        }

        .status-line {
            font-size: 0.8rem;
            color: var(--ink-muted);
            animation: pulse 2s ease-in-out infinite;
            margin: 0;
        }

        .progress-track {
            width: min(320px, 80vw);
            height: 4px;
            background: var(--border);
            border-radius: 2px;
            overflow: hidden;
        }

        .progress-bar {
            height: 100%;
            background: var(--accent-light);
            border-radius: 2px;
            width: 0%;
            transition: width 0.6s ease;
        }

        .cancel-btn {
            margin-top: 0.5rem;
            background: none;
            border: 1px solid var(--border-strong);
            color: var(--ink-muted);
            padding: 0.4rem 1.2rem;
            border-radius: 6px;
            font-size: 0.8rem;
            cursor: pointer;
            transition: border-color 0.2s, color 0.2s;
        }
        .cancel-btn:hover { border-color: var(--red); color: var(--red); }

        .eta-line {
            font-size: 0.78rem;
            color: var(--ink-muted);
            margin: 0;
            min-height: 1.1em;
        }
    </style>
</head>
<body>
    <%@ include file="navbar.jsp" %>

    <div class="loading-wrap">
        <div class="spinner"></div>

        <div style="text-align: center; animation: fadeIn 0.4s ease both;">
            <p class="loading-title">Generating AI Questions…</p>
            <p class="loading-sub">
                Preparing exam for <span class="loading-topic"><%= topic %></span>
            </p>
        </div>

        <div class="progress-track">
            <div class="progress-bar" id="progressBar"></div>
        </div>

        <p class="status-line" id="statusLine">Contacting Gemini AI…</p>
        <p class="eta-line"    id="etaLine"></p>

        <button class="cancel-btn" id="cancelBtn">Cancel</button>
        <button class="cancel-btn" id="forceRedirectBtn" style="margin-left: 10px;">Force Redirect</button>
    </div>

    <script>
    // Global functions for button handlers
    function manualRedirect() {
        console.log('[loading.jsp] Manual redirect triggered');
        window.location = 'exam.jsp';
    }

    function cancelJob() {
        console.log('[loading.jsp] Cancel triggered');
        var jobId = '<%= jobId %>';
        clearTimeout(window.pollTimer);
        fetch('jobStatus.jsp?jobId=' + encodeURIComponent(jobId) + '&cancel=1', {
            credentials: 'same-origin'
        }).finally(function () {
            window.location = 'setup.jsp';
        });
    }

    // Set up button event listeners
    document.addEventListener('DOMContentLoaded', function() {
        var cancelBtn = document.getElementById('cancelBtn');
        var forceRedirectBtn = document.getElementById('forceRedirectBtn');
        
        if (cancelBtn) {
            cancelBtn.addEventListener('click', cancelJob);
            console.log('[loading.jsp] Cancel button listener attached');
        } else {
            console.error('[loading.jsp] Cancel button not found');
        }
        
        if (forceRedirectBtn) {
            forceRedirectBtn.addEventListener('click', manualRedirect);
            console.log('[loading.jsp] Force redirect button listener attached');
        } else {
            console.error('[loading.jsp] Force redirect button not found');
        }
    });

    // Polling logic
    (function () {
        var jobId      = '<%= jobId %>';
        var pollUrl    = 'jobStatus.jsp?jobId=' + encodeURIComponent(jobId);
        var startTime  = Date.now();
        var pollCount  = 0;
        var maxPolls   = 35;   // 35 × 2s = 70s before client gives up
        var timer      = null;

        var progressBar = document.getElementById('progressBar');
        var statusLine  = document.getElementById('statusLine');
        var etaLine     = document.getElementById('etaLine');

        console.log('[loading.jsp] Starting polling for jobId:', jobId);
        console.log('[loading.jsp] Poll URL:', pollUrl);

        // Status messages shown in sequence while waiting
        var messages = [
            'Contacting Gemini AI…',
            'Crafting your questions…',
            'Reviewing answer choices…',
            'Almost there — finalising…',
            'Saving to database…',
            'Wrapping up…'
        ];

        function updateProgress(count) {
            // Visual progress: moves fast early, slows near the end
            var pct = Math.min(90, Math.round((count / maxPolls) * 100 * 1.4));
            progressBar.style.width = pct + '%';

            var msgIdx = Math.min(Math.floor(count / 6), messages.length - 1);
            statusLine.textContent = messages[msgIdx];

            var elapsed = Math.round((Date.now() - startTime) / 1000);
            var remaining = Math.max(0, 30 - elapsed);
            if (elapsed < 5) {
                etaLine.textContent = 'Usually takes 15–30 seconds.';
            } else if (remaining > 0) {
                etaLine.textContent = 'About ' + remaining + ' second' + (remaining === 1 ? '' : 's') + ' remaining…';
            } else {
                etaLine.textContent = 'Taking a bit longer than usual — almost done…';
            }
        }

        function poll() {
            pollCount++;
            console.log('[loading.jsp] Poll #' + pollCount + ' for jobId:', jobId);

            if (pollCount > maxPolls) {
                clearTimeout(timer);
                console.error('[loading.jsp] Max polls reached, giving up');
                alert('AI generation is taking too long. Please try again or use Database questions.');
                window.location = 'setup.jsp';
                return;
            }

            updateProgress(pollCount);

            console.log('[loading.jsp] Fetching:', pollUrl);
            fetch(pollUrl, { credentials: 'same-origin' })
                .then(function (res) {
                    console.log('[loading.jsp] Response status:', res.status);
                    if (!res.ok) throw new Error('HTTP ' + res.status);
                    return res.json();
                })
                .then(function (data) {
                    console.log('[loading.jsp] Response data:', data);
                    if (data.status === 'done') {
                        progressBar.style.width = '100%';
                        statusLine.textContent  = 'Questions ready!';
                        etaLine.textContent     = '';
                        console.log('[loading.jsp] Job done, redirecting to exam.jsp');
                        // Small delay so user sees the "100%" state
                        setTimeout(function () { window.location = 'exam.jsp'; }, 400);

                    } else if (data.status === 'error') {
                        clearTimeout(timer);
                        console.error('[loading.jsp] Job error:', data.message);
                        alert(data.message || 'AI generation failed. Please try again.');
                        window.location = 'setup.jsp';

                    } else {
                        console.log('[loading.jsp] Job still pending, continuing to poll');
                        // still 'pending' — keep polling
                        timer = setTimeout(poll, 2000);
                    }
                })
                .catch(function (err) {
                    console.error('[loading.jsp] Poll error:', err);
                    // Don't stop on a transient network error — retry
                    timer = setTimeout(poll, 3000);
                });
        }

        // Start first poll after 1s (give server a moment to begin)
        console.log('[loading.jsp] Starting first poll in 1 second');
        timer = setTimeout(poll, 1000);
        window.pollTimer = timer; // Store globally for cancel access
    })();
    </script>
</body>
</html>