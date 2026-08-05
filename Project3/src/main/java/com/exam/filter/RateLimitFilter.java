package com.exam.filter;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

public class RateLimitFilter implements Filter {

    // Max failed attempts before lockout
    private static final int MAX_ATTEMPTS = 5;
    // Lockout duration in milliseconds (15 minutes)
    private static final long LOCK_DURATION_MS = 15 * 60 * 1000L;

    // ip -> [failCount, firstFailTimestamp]
    private final Map<String, long[]> attempts = new ConcurrentHashMap<>();

    @Override
    public void init(FilterConfig config) {}

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;

        // Only inspect POST requests (the actual login/register submission)
        if ("POST".equalsIgnoreCase(request.getMethod())) {

            String ip = request.getRemoteAddr();
            long now  = System.currentTimeMillis();

            long[] record = attempts.get(ip);

            if (record != null) {
                long failCount       = record[0];
                long firstFailTime   = record[1];
                long elapsed         = now - firstFailTime;

                if (failCount >= MAX_ATTEMPTS && elapsed < LOCK_DURATION_MS) {
                    long waitSecs = (LOCK_DURATION_MS - elapsed) / 1000;
                    response.setStatus(429); // Too Many Requests
                    response.setContentType("text/html;charset=UTF-8");
                    response.getWriter().write(
                            "<p style='color:red;'>Too many failed attempts. " +
                                    "Try again in " + waitSecs + " seconds.</p>"
                    );
                    return; // Block the request — do NOT continue the chain
                }

                // Reset counter if lockout window has expired
                if (elapsed >= LOCK_DURATION_MS) {
                    attempts.remove(ip);
                }
            }
        }

        // Wrap response so we can inspect what happened after the chain runs
        chain.doFilter(req, res);

        // After the chain: if it's a POST and the response has NOT redirected
        // (meaning login/register failed), increment the failure counter.
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            HttpServletResponse httpRes = (HttpServletResponse) res;
            int status = httpRes.getStatus();

            // A successful login always redirects (302). 200 = page re-rendered = failure.
            if (status == 200) {
                String ip = request.getRemoteAddr();
                long   now = System.currentTimeMillis();
                attempts.compute(ip, (k, v) -> {
                    if (v == null) return new long[]{1, now};
                    v[0]++;
                    return v;
                });
            } else {
                // Successful login/register: clear the counter for this IP
                attempts.remove(request.getRemoteAddr());
            }
        }
    }

    @Override
    public void destroy() {
        attempts.clear();
    }
}