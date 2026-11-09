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
<body class="modern page-notification">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="page">
<section class="content page-shell content-start">
  <div class="page-title">
    <div><h1>Notifications</h1><p>Recent activity from the reporting system.</p></div>
    <a class="btn btn-outline" href="<%= home %>">Back to dashboard</a>
  </div>
  <section class="card wide-button">
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
    <div class="notification-row">
      <div><div class="text-semibold">Report #<%= rs.getInt("CRIME_ID") %> · <%= category == null ? "Crime report" : category %></div>
      <div class="notification-date">Your report has status <strong><%= badge %></strong><% if(date!=null){ %> · <%= date %><% } %></div></div>
      
    </div>
  <%
        }
      }
    } catch(Exception e) {
  %>
    <div class="message error notification-message">Notifications could not be loaded right now. Please try again later.</div>
  <%
    }
    if(!found){
  %>
    <div class="empty-state">
      <div class="feature-icon centered-icon">✓</div>
      <h2 class="empty-title">You're all caught up</h2>
      <p class="empty-copy">There are no recent report updates to show.</p>
    </div>
  <% } %>
  </section>
</section>
</main>
</body>
</html>
