<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*" %>
<%@ page import="utils.DBConnection" %>
<%
    String currentUser = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("userRole");
    if (!"admin".equalsIgnoreCase(role)) {
        String target = "police".equalsIgnoreCase(role) ? "PoliceHome.jsp" : "UserHome.jsp";
        response.sendRedirect(target);
        return;
    }
    int totalReports=0, pendingReports=0, totalUsers=0, totalPolice=0;
    try (Connection conn=DBConnection.getConnection()) {
        String[] sqls = {
            "SELECT COUNT(*) FROM REPORTED_CRIMES",
            "SELECT COUNT(*) FROM REPORTED_CRIMES WHERE ACCEPTED_BY IS NULL",
            "SELECT COUNT(*) FROM REGISTERED_USERS",
            "SELECT COUNT(*) FROM REGISTERED_USERS WHERE LOWER(ROLE)='police'"
        };
        int[] counts = {0, 0, 0, 0};

        for (int i = 0; i < sqls.length; i++) {
            try (PreparedStatement ps = conn.prepareStatement(sqls[i]);
                 ResultSet rs = ps.executeQuery()) {

                if (rs.next()) {
                    counts[i] = rs.getInt(1);
                }
            }
        }

        totalReports = counts[0];
        pendingReports = counts[1];
        totalUsers = counts[2];
        totalPolice = counts[3];
    } catch(Exception ignored){}
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Dashboard - Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %></head>
<body class="modern page-adminshome">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="page">
<section class="content page-shell content-start">
  <div class="page-title">
    <div><h1>Admin dashboard</h1><p>Keep reports, users, and operational information organized.</p></div>
    
  </div>
  <div class="stat-grid">
    <article class="card stat"><div class="stat-label">Total reports</div><div class="stat-value"><%= totalReports %></div><span class="text-small">All submitted incidents</span></article>
    <article class="card stat"><div class="stat-label">Awaiting review</div><div class="stat-value"><%= pendingReports %></div><span class="text-small">Reports without approval</span></article>
    <article class="card stat"><div class="stat-label">Registered users</div><div class="stat-value"><%= totalUsers %></div><span class="text-small">All system accounts</span></article>
    <article class="card stat"><div class="stat-label">Police accounts</div><div class="stat-value"><%= totalPolice %></div><span class="text-small">Verified police users</span></article>
  </div>
  <div class="grid-3 section-gap">
    <article class="card feature-card"><div class="feature-icon">▤</div><h3>Report management</h3><p>Review, approve, reject, and manage submitted crime reports.</p><a class="btn btn-primary section-gap" href="ReportMan.jsp">Manage reports</a></article>
    <article class="card feature-card"><div class="feature-icon">♙</div><h3>User management</h3><p>Search registered accounts and maintain user access information.</p><a class="btn btn-outline section-gap" href="UserManage.jsp">Manage users</a></article>
    <article class="card feature-card"><div class="feature-icon">♧</div><h3>Directories</h3><p>Access official police and administrator information from one place.</p><div class="action-row"><a class="btn btn-outline" href="PoliceInfo.jsp">Police</a><a class="btn btn-outline" href="AdminInfo.jsp">Admins</a></div></article>
  </div>
  <section class="card panel-gap">
    <h2 class="card-title">Welcome back</h2>
    <p class="card-description">Use the navigation above to manage the reporting workflow. Your administrative actions should be limited to information you are authorized to review.</p>
    <div class="actions"><a class="btn btn-primary" href="ReportMan.jsp">Review reports</a><a class="btn btn-outline" href="UserManage.jsp">Manage accounts</a><a class="btn btn-ghost" href="Settings.jsp">Settings</a></div>
  </section>
</section>
</main>
</body>
</html>
