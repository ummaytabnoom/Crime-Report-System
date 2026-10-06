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
        int[] out={0,0,0,0};
        for(int i=0;i<sqls.length;i++){
            try(PreparedStatement ps=conn.prepareStatement(sqls[i]); ResultSet rs=ps.executeQuery()){
                if(rs.next()) out[i]=rs.getInt(1);
            }
        }
        totalReports=out[0]; pendingReports=out[1]; totalUsers=out[2]; totalPolice=out[3];
    } catch(Exception ignored){}
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Dashboard - Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %></head>
<body class="crs-modern">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="crs-page">
<section class="crs-content crs-container" style="padding-top:34px">
  <div class="crs-page-title">
    <div><h1>Admin dashboard</h1><p>Keep reports, users, and operational information organized.</p></div>
    <span class="crs-badge crs-badge-info">Administrator • <%= currentUser %></span>
  </div>
  <div class="crs-stat-grid">
    <article class="crs-card crs-stat"><div class="crs-stat-label">Total reports</div><div class="crs-stat-value"><%= totalReports %></div><span style="color:var(--text-muted);font-size:12px;">All submitted incidents</span></article>
    <article class="crs-card crs-stat"><div class="crs-stat-label">Awaiting review</div><div class="crs-stat-value"><%= pendingReports %></div><span style="color:var(--text-muted);font-size:12px;">Reports without approval</span></article>
    <article class="crs-card crs-stat"><div class="crs-stat-label">Registered users</div><div class="crs-stat-value"><%= totalUsers %></div><span style="color:var(--text-muted);font-size:12px;">All system accounts</span></article>
    <article class="crs-card crs-stat"><div class="crs-stat-label">Police accounts</div><div class="crs-stat-value"><%= totalPolice %></div><span style="color:var(--text-muted);font-size:12px;">Verified police users</span></article>
  </div>
  <div class="crs-grid-3" style="margin-top:18px;">
    <article class="crs-card crs-feature-card"><div class="crs-feature-icon">▤</div><h3>Report management</h3><p>Review, approve, reject, and manage submitted crime reports.</p><a class="crs-btn crs-btn-primary" style="margin-top:18px;" href="ReportMan.jsp">Manage reports</a></article>
    <article class="crs-card crs-feature-card"><div class="crs-feature-icon">♙</div><h3>User management</h3><p>Search registered accounts and maintain user access information.</p><a class="crs-btn crs-btn-outline" style="margin-top:18px;" href="UserManage.jsp">Manage users</a></article>
    <article class="crs-card crs-feature-card"><div class="crs-feature-icon">♧</div><h3>Directories</h3><p>Access official police and administrator information from one place.</p><div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:18px;"><a class="crs-btn crs-btn-outline" href="PoliceInfo.jsp">Police</a><a class="crs-btn crs-btn-outline" href="AdminInfo.jsp">Admins</a></div></article>
  </div>
  <section class="crs-card" style="padding:24px;margin-top:18px;">
    <h2 style="margin:0;font-size:19px;">Welcome back</h2>
    <p style="margin:8px 0 0;color:var(--text-muted);line-height:1.65;">Use the navigation above to manage the reporting workflow. Your administrative actions should be limited to information you are authorized to review.</p>
    <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:18px;"><a class="crs-btn crs-btn-primary" href="ReportMan.jsp">Review reports</a><a class="crs-btn crs-btn-outline" href="UserManage.jsp">Manage accounts</a><a class="crs-btn crs-btn-ghost" href="Settings.jsp">Settings</a></div>
  </section>
</section>
</main>
</body>
</html>
