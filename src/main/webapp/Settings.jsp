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
<body class="modern page-settings">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>
<main class="page">
<section class="content page-shell content-start">
  <div class="page-title">
    <div><h1>Settings</h1><p>Manage your profile, password, and account preferences.</p></div>
    
  </div>
  <div class="grid-3">
    <article class="card feature-card"><div class="feature-icon">◉</div><h3>Profile picture</h3><p>Update the image shown on your account and across the application.</p><a class="btn btn-primary section-gap" href="ChangeProfilePic.jsp">Change picture</a></article>
    <article class="card feature-card"><div class="feature-icon">✎</div><h3>Profile information</h3><p>Keep your name, email, mobile number, and other account details current.</p><a class="btn btn-outline section-gap" href="ChangeProfileInfo.jsp">Edit profile</a></article>
    <article class="card feature-card"><div class="feature-icon">⌁</div><h3>Password</h3><p>Change your account password whenever you need to refresh your credentials.</p><a class="btn btn-outline section-gap" href="ChangePassword.jsp">Change password</a></article>
  </div>
  <section class="card panel-gap">
    <h2 class="card-title">Appearance</h2>
    <p class="card-summary">Your light/dark preference is saved in this browser.</p>
    <div class="identity-row">
      
      <a class="btn btn-ghost" href="Notification.jsp">View notifications</a>
    </div>
  </section>
</section>
</main>
</body>
</html>
