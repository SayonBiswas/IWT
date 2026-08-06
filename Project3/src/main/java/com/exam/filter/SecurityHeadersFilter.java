package com.exam.filter;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.IOException;

public class SecurityHeadersFilter implements Filter {

    @Override
    public void init(FilterConfig config) {}

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletResponse response = (HttpServletResponse) res;

        // 1. Content-Security-Policy
        // Only load scripts/styles from your own server. Blocks injected external scripts.
        response.setHeader("Content-Security-Policy",
                "default-src 'self'; " +
                        "script-src 'self'; " +
                        "style-src 'self' 'unsafe-inline'; " +   // unsafe-inline kept for your inline styles
                        "img-src 'self' data:; " +
                        "font-src 'self'; " +
                        "frame-ancestors 'none'");                // also blocks clickjacking

        // 2. Clickjacking protection (older browser fallback for frame-ancestors)
        response.setHeader("X-Frame-Options", "DENY");

        // 3. Stops browser from guessing content types (MIME sniffing attacks)
        response.setHeader("X-Content-Type-Options", "nosniff");

        // 4. HSTS — tells browsers: always use HTTPS for this domain, for 1 year
        // Only activate this once your site is fully on HTTPS (Render.com = yes)
        response.setHeader("Strict-Transport-Security",
                "max-age=31536000; includeSubDomains");

        // 5. Stops the browser sending your full URL as Referer to other sites
        response.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");

        // 6. Disables browser features you don't use (microphone, camera, etc.)
        response.setHeader("Permissions-Policy",
                "geolocation=(), microphone=(), camera=()");

        chain.doFilter(req, res);
    }

    @Override
    public void destroy() {}
}