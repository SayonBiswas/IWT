package com.exam.filter;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.UUID;

public class CsrfFilter implements Filter {

    private static final String CSRF_TOKEN_SESSION = "_csrf";
    private static final String CSRF_TOKEN_PARAM   = "_csrf";

    @Override
    public void init(FilterConfig config) {}

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        HttpServletRequest  request  = (HttpServletRequest)  req;
        HttpServletResponse response = (HttpServletResponse) res;
        HttpSession         session  = request.getSession(false);

        // --- Generate token on GET (seed the session) ---
        if ("GET".equalsIgnoreCase(request.getMethod())) {
            if (session == null) {
                session = request.getSession(true);
            }
            if (session.getAttribute(CSRF_TOKEN_SESSION) == null) {
                session.setAttribute(CSRF_TOKEN_SESSION, UUID.randomUUID().toString());
            }
            chain.doFilter(req, res);
            return;
        }

        // --- Validate token on POST ---
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String sessionToken = (session != null)
                    ? (String) session.getAttribute(CSRF_TOKEN_SESSION)
                    : null;
            String requestToken = request.getParameter(CSRF_TOKEN_PARAM);

            if (sessionToken == null || !sessionToken.equals(requestToken)) {
                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("text/html;charset=UTF-8");
                response.getWriter().write(
                        "<p style='color:red;'>Invalid or missing security token. " +
                                "Please go back and try again.</p>"
                );
                return;
            }

            // Rotate token after each successful POST so it can't be reused
            if (session != null) {
                session.setAttribute(CSRF_TOKEN_SESSION, UUID.randomUUID().toString());
            }
        }

        chain.doFilter(req, res);
    }

    @Override
    public void destroy() {}
}