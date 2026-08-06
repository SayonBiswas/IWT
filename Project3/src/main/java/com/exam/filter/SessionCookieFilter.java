package com.exam.filter;

import javax.servlet.*;
import javax.servlet.http.*;
import java.io.IOException;
import java.util.Collection;

public class SessionCookieFilter implements Filter {

    @Override
    public void init(FilterConfig config) {}

    @Override
    public void doFilter(ServletRequest req, ServletResponse res, FilterChain chain)
            throws IOException, ServletException {

        chain.doFilter(req, res);   // let the page run first

        HttpServletResponse response = (HttpServletResponse) res;

        // Re-write every Set-Cookie header, appending SameSite=Strict
        // if it isn't already there.
        Collection<String> headers = response.getHeaders("Set-Cookie");
        boolean first = true;
        for (String header : headers) {
            if (!header.contains("SameSite")) {
                header = header + "; SameSite=Strict";
            }
            if (first) {
                response.setHeader("Set-Cookie", header);   // replaces
                first = false;
            } else {
                response.addHeader("Set-Cookie", header);   // appends
            }
        }
    }

    @Override
    public void destroy() {}
}