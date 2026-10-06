<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String currentUser = (String) session.getAttribute("username");
    String currentRole = (String) session.getAttribute("userRole");
    String dashboard = "admin".equalsIgnoreCase(currentRole) ? "AdminsHome.jsp" : ("police".equalsIgnoreCase(currentRole) ? "PoliceHome.jsp" : "UserHome.jsp");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="crs-modern">
<div class="crs-page">
    <header class="crs-nav">
        <a class="crs-brand" href="MainHome.jsp">
            <span class="crs-brand-mark">◈</span>
            <span>Crime Report System</span>
        </a>
        <nav class="crs-nav-links" aria-label="Main navigation">
            <a href="#home">Home</a>
            <a href="#mission">About</a>
            <a href="#features">Features</a>
        </nav>
        <div class="crs-nav-actions">
            <button class="crs-btn crs-theme-toggle" type="button" onclick="CRSTheme.toggle()" aria-label="Toggle theme"><span data-theme-icon>☾</span></button>
            <% if (currentUser == null) { %>
                <a class="crs-btn crs-btn-outline" href="Login.jsp">Login</a>
                <a class="crs-btn crs-btn-primary" href="Registration.jsp">Register</a>
            <% } else { %>
                <a class="crs-btn crs-btn-primary" href="<%= dashboard %>">Dashboard</a>
                <a class="crs-btn crs-btn-outline" href="Logout.jsp">Logout</a>
            <% } %>
        </div>
    </header>

    <main id="home">
        <section class="crs-hero">
            <div class="crs-container">
                <div class="crs-hero-content">
                    <div class="crs-eyebrow">● A safer community starts with reporting</div>
                    <h1>Report crimes.<br><span class="crs-gradient-text">Build safer communities.</span></h1>
                    <p>Share incidents securely, track progress, and help authorities take action. Every report gives your community a better chance to respond.</p>
                    <div class="crs-hero-actions">
                        <a class="crs-btn crs-btn-primary" href="<%= currentUser == null ? "Login.jsp" : ("public".equalsIgnoreCase(currentRole) ? "ReportSub.jsp" : dashboard) %>">Report a Crime →</a>
                        <a class="crs-btn crs-btn-outline" href="#features">Learn More</a>
                    </div>
                    <div class="crs-trust-row">
                        <div class="crs-trust-item"><span class="crs-trust-icon">✓</span><span><strong>Easy reporting</strong><br>Submit in minutes</span></div>
                        <div class="crs-trust-item"><span class="crs-trust-icon">↗</span><span><strong>Track progress</strong><br>Stay updated</span></div>
                        <div class="crs-trust-item"><span class="crs-trust-icon">◆</span><span><strong>Confidential</strong><br>Your data is protected</span></div>
                    </div>
                </div>
            </div>
        </section>

        <section class="crs-section" id="features">
            <div class="crs-container">
                <div class="crs-section-header" id="mission">
                    <h2>Everything you need to report responsibly</h2>
                    <p>A focused workflow for citizens, police personnel, and administrators.</p>
                </div>
                <div class="crs-grid-3">
                    <article class="crs-card crs-feature-card">
                        <div class="crs-feature-icon">↗</div>
                        <h3>Report incidents</h3>
                        <p>Submit accurate incident details, location information, and supporting evidence through a simple guided form.</p>
                    </article>
                    <article class="crs-card crs-feature-card">
                        <div class="crs-feature-icon">✓</div>
                        <h3>Verified workflow</h3>
                        <p>Reports move through review and verification so authorized teams can focus on credible cases.</p>
                    </article>
                    <article class="crs-card crs-feature-card">
                        <div class="crs-feature-icon">◉</div>
                        <h3>Track progress</h3>
                        <p>Follow report status and updates from submission through investigation and resolution.</p>
                    </article>
                </div>
            </div>
        </section>
    </main>
</div>
</body>
</html>
