<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="utils.DBConnection" %>
<%
    String currentUser = (String) session.getAttribute("username");
    if (currentUser == null) { response.sendRedirect("Login.jsp"); return; }
    String role = (String) session.getAttribute("userRole");
    String home = "admin".equalsIgnoreCase(role) ? "AdminsHome.jsp" : ("police".equalsIgnoreCase(role) ? "PoliceHome.jsp" : "UserHome.jsp");
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Notifications - Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %></head>
<body class="crs-modern">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="crs-page">
<section class="crs-content crs-container" style="padding-top:34px">
  <div class="crs-page-title">
    <div><h1>Notifications</h1><p>Recent activity from the reporting system.</p></div>
    <a class="crs-btn crs-btn-outline" href="<%= home %>">Back to dashboard</a>
  </div>
  <section class="crs-card" style="padding:8px 22px;">
  <%
    boolean found=false;
    String sql = "SELECT CRIME_ID, CATEGORY, STATUS, DATE_OF_INCIDENT FROM REPORTED_CRIMES WHERE USER_NAME=? ORDER BY CRIME_ID DESC";
    try (Connection conn=DBConnection.getConnection(); PreparedStatement ps=conn.prepareStatement(sql)) {
      ps.setString(1,currentUser);
      try(ResultSet rs=ps.executeQuery()){
        int shown=0;
        while(rs.next() && shown<12){
          found=true; shown++;
          String status=rs.getString("STATUS");
          String category=rs.getString("CATEGORY");
          Timestamp date=rs.getTimestamp("DATE_OF_INCIDENT");
          String badge = status==null ? "Pending" : status;
  %>
    <div style="display:flex;align-items:center;justify-content:space-between;gap:18px;padding:18px 0;border-bottom:1px solid var(--border);">
      <div><div style="font-weight:750;">Report #<%= rs.getInt("CRIME_ID") %> · <%= category == null ? "Crime report" : category %></div>
      <div style="margin-top:4px;color:var(--text-muted);font-size:13px;">Your report has status <strong><%= badge %></strong><% if(date!=null){ %> · <%= date %><% } %></div></div>
      <span class="crs-badge crs-badge-info"><%= badge %></span>
    </div>
  <%
        }
      }
    } catch(Exception e) {
  %>
    <div class="crs-message error" style="margin:14px 0;">Notifications could not be loaded right now. Please try again later.</div>
  <%
    }
    if(!found){
  %>
    <div style="padding:48px 10px;text-align:center;">
      <div class="crs-feature-icon" style="margin:0 auto 14px;">✓</div>
      <h2 style="margin:0;font-size:18px;">You're all caught up</h2>
      <p style="margin:8px 0;color:var(--text-muted);">There are no recent report updates to show.</p>
    </div>
  <% } %>
  </section>
</section>
</main>
</body>
</html>
