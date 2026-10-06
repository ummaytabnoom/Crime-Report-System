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
<body class="crs-modern">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="crs-page">
  <section class="crs-content crs-container" style="padding-top:34px">
    <div class="crs-page-title">
      <div><h1>Police dashboard</h1><p>Review reported incidents, update case progress, and access verified records.</p></div>
      <span class="crs-badge crs-badge-info">Police • <%= currentUser %></span>
    </div>

    <div class="crs-stat-grid">
      <article class="crs-card crs-stat"><div class="crs-stat-label">All reports</div><div class="crs-stat-value"><%= totalReports %></div><span style="color:var(--text-muted);font-size:12px;">Reported incidents in the system</span></article>
      <article class="crs-card crs-stat"><div class="crs-stat-label">Active cases</div><div class="crs-stat-value"><%= activeReports %></div><span style="color:var(--text-muted);font-size:12px;">Cases needing attention</span></article>
      <article class="crs-card crs-stat"><div class="crs-stat-label">Resolved</div><div class="crs-stat-value"><%= resolvedReports %></div><span style="color:var(--text-muted);font-size:12px;">Closed or resolved cases</span></article>
      <article class="crs-card crs-stat"><div class="crs-stat-label">Your workspace</div><div class="crs-stat-value">24/7</div><span style="color:var(--text-muted);font-size:12px;">Access from any device</span></article>
    </div>

    <div class="crs-grid-3" style="margin-top:18px;">
      <article class="crs-card crs-feature-card">
        <div class="crs-feature-icon">▤</div><h3>Crime reports</h3>
        <p>Browse reported incidents and review the information available to authorized police personnel.</p>
        <a class="crs-btn crs-btn-primary" style="margin-top:18px;" href="UpdateCrime.jsp">Open reports</a>
      </article>
      <article class="crs-card crs-feature-card">
        <div class="crs-feature-icon">↗</div><h3>Status updates</h3>
        <p>Move cases through the workflow and record the officer responsible for an update.</p>
        <a class="crs-btn crs-btn-outline" style="margin-top:18px;" href="StateUpgrade.jsp">Update status</a>
      </article>
      <article class="crs-card crs-feature-card">
        <div class="crs-feature-icon">♧</div><h3>Police directory</h3>
        <p>Find police personnel and official profile information available in the system.</p>
        <a class="crs-btn crs-btn-outline" style="margin-top:18px;" href="PoliceInfo.jsp">Open directory</a>
      </article>
    </div>

    <section class="crs-card" style="padding:24px;margin-top:18px;">
      <div class="crs-page-title" style="margin-bottom:0;">
        <div><h2 style="margin:0;font-size:19px;">Quick actions</h2><p>Common tasks for your shift.</p></div>
        <a class="crs-btn crs-btn-ghost" href="Settings.jsp">Settings →</a>
      </div>
      <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:18px;">
        <a class="crs-btn crs-btn-primary" href="UpdateCrime.jsp">Review incidents</a>
        <a class="crs-btn crs-btn-outline" href="StateUpgrade.jsp">Change report status</a>
        <a class="crs-btn crs-btn-outline" href="PoliceInfo.jsp">Search personnel</a>
        <a class="crs-btn crs-btn-ghost" href="Notification.jsp">Notifications</a>
      </div>
    </section>
  </section>
</main>
</body>
</html>
