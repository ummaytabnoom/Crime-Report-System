<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*" %>
<%@ page import="utils.DBConnection" %>
<%
    String currentUser = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("userRole");
    if (!"police".equalsIgnoreCase(role)) {
        String target = "admin".equalsIgnoreCase(role) ? "AdminsHome.jsp" : "UserHome.jsp";
        response.sendRedirect(target);
        return;
    }

    int totalReports = 0, activeReports = 0, resolvedReports = 0;
    try (Connection conn = DBConnection.getConnection()) {
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM REPORTED_CRIMES")) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) totalReports = rs.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM REPORTED_CRIMES WHERE UPPER(NVL(STATUS,'PENDING')) NOT IN ('RESOLVED','CLOSED')")) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) activeReports = rs.getInt(1);
        }
        try (PreparedStatement ps = conn.prepareStatement("SELECT COUNT(*) FROM REPORTED_CRIMES WHERE UPPER(STATUS) IN ('RESOLVED','CLOSED')")) {
            ResultSet rs = ps.executeQuery();
            if (rs.next()) resolvedReports = rs.getInt(1);
        }
    } catch (Exception ignored) {}
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Police Dashboard - Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-policehome">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="page">
  <section class="content page-shell content-start">
    <div class="page-title">
      <div><h1>Police dashboard</h1><p>Review reported incidents, update case progress, and access verified records.</p></div>
      
    </div>

    <div class="stat-grid">
      <article class="card stat"><div class="stat-label">All reports</div><div class="stat-value"><%= totalReports %></div><span class="text-small">Reported incidents in the system</span></article>
      <article class="card stat"><div class="stat-label">Active cases</div><div class="stat-value"><%= activeReports %></div><span class="text-small">Cases needing attention</span></article>
      <article class="card stat"><div class="stat-label">Resolved</div><div class="stat-value"><%= resolvedReports %></div><span class="text-small">Closed or resolved cases</span></article>
      <article class="card stat"><div class="stat-label">Your workspace</div><div class="stat-value">24/7</div><span class="text-small">Access from any device</span></article>
    </div>

    <div class="grid-3 section-gap">
      <article class="card feature-card">
        <div class="feature-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M7 3.75h7l4 4v12.5H7a2 2 0 0 1-2-2v-12.5a2 2 0 0 1 2-2Z"/><path d="M14 3.75v4h4M8.5 12h7M8.5 15.5h7"/></svg></div><h3>Crime reports</h3>
        <p>Browse reported incidents and review the information available to authorized police personnel.</p>
        <a class="btn btn-primary section-gap" href="UpdateCrime.jsp">Open reports</a>
      </article>
      <article class="card feature-card">
        <div class="feature-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M20 7v5h-5M4 17v-5h5"/><path d="M5.5 9A7 7 0 0 1 18 6.5L20 12M4 12l2 5.5A7 7 0 0 0 18.5 15"/></svg></div><h3>Status updates</h3>
        <p>Move cases through the workflow and record the officer responsible for an update.</p>
        <a class="btn btn-outline section-gap" href="StateUpgrade.jsp">Update status</a>
      </article>
      <article class="card feature-card">
        <div class="feature-icon" aria-hidden="true"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="8" r="3.25"/><path d="M5.5 19a6.5 6.5 0 0 1 13 0M4 6.5h2M18 6.5h2M12 2v1.5"/></svg></div><h3>Police directory</h3>
        <p>Find police personnel and official profile information available in the system.</p>
        <a class="btn btn-outline section-gap" href="PoliceInfo.jsp">Open directory</a>
      </article>
    </div>

    <section class="card panel-gap">
      <div class="page-title no-bottom-margin">
        <div><h2 class="card-title">Quick actions</h2><p>Common tasks for your shift.</p></div>
        <a class="btn btn-ghost" href="Settings.jsp">Settings →</a>
      </div>
      <div class="actions">
        <a class="btn btn-primary" href="UpdateCrime.jsp">Review incidents</a>
        <a class="btn btn-outline" href="StateUpgrade.jsp">Change report status</a>
        <a class="btn btn-outline" href="PoliceInfo.jsp">Search personnel</a>
        <a class="btn btn-ghost" href="Notification.jsp">Notifications</a>
      </div>
    </section>
  </section>
</main>
</body>
</html>
