<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%
    String currentUser = (String) session.getAttribute("username");
    String role = (String) session.getAttribute("userRole");
    if (currentUser == null) { response.sendRedirect("Login.jsp"); return; }
%>
<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>Settings - Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %></head>
<body class="crs-modern">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="crs-page">
<section class="crs-content crs-container" style="padding-top:34px">
  <div class="crs-page-title">
    <div><h1>Settings</h1><p>Manage your profile, password, and account preferences.</p></div>
    <span class="crs-badge crs-badge-info"><%= role == null ? "User" : role %></span>
  </div>
  <div class="crs-grid-3">
    <article class="crs-card crs-feature-card"><div class="crs-feature-icon">◉</div><h3>Profile picture</h3><p>Update the image shown on your account and across the application.</p><a class="crs-btn crs-btn-primary" style="margin-top:18px;" href="ChangeProfilePic.jsp">Change picture</a></article>
    <article class="crs-card crs-feature-card"><div class="crs-feature-icon">✎</div><h3>Profile information</h3><p>Keep your name, email, mobile number, and other account details current.</p><a class="crs-btn crs-btn-outline" style="margin-top:18px;" href="ChangeProfileInfo.jsp">Edit profile</a></article>
    <article class="crs-card crs-feature-card"><div class="crs-feature-icon">⌁</div><h3>Password</h3><p>Change your account password whenever you need to refresh your credentials.</p><a class="crs-btn crs-btn-outline" style="margin-top:18px;" href="ChangePassword.jsp">Change password</a></article>
  </div>
  <section class="crs-card" style="padding:24px;margin-top:18px;">
    <h2 style="margin:0;font-size:19px;">Appearance</h2>
    <p style="margin:8px 0 0;color:var(--text-muted);">Your light/dark preference is saved in this browser.</p>
    <div style="display:flex;align-items:center;gap:12px;margin-top:18px;">
      <button class="crs-btn crs-btn-outline" type="button" onclick="CRSTheme.toggle()"><span data-theme-icon>☾</span> Toggle theme</button>
      <a class="crs-btn crs-btn-ghost" href="Notification.jsp">View notifications</a>
    </div>
  </section>
</section>
</main>
</body>
</html>
