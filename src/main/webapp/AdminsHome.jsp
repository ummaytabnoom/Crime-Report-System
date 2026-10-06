<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%
    String currentUser = (String) session.getAttribute("username");
    byte[] imageBytes = null;
    try {
        Class.forName("oracle.jdbc.OracleDriver");
        Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

        String sql = "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME = ?";
        PreparedStatement stmt = conn.prepareStatement(sql);
        stmt.setString(1, currentUser);
        ResultSet rs = stmt.executeQuery();

        if (rs.next()) {
            Blob blob = rs.getBlob("PROFILE_PICTURE");
            if (blob != null) {
                InputStream is = blob.getBinaryStream();
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
                imageBytes = os.toByteArray();
                is.close();
            }
        }

        rs.close();
        stmt.close();
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Admin Dashboard - Crime Report System</title>
<link rel="stylesheet" href="assets/css/app.css">
<script src="assets/js/theme.js"></script>
</head>
<body class="crs-modern">
<div class="crs-dashboard">
    <aside class="crs-sidebar">
        <a class="crs-brand" href="AdminsHome.jsp"><span class="crs-brand-mark">◈</span><span>Crime Report</span></a>
        <nav class="crs-side-nav">
            <a class="active" href="AdminsHome.jsp">⌂ <span>Dashboard</span></a>
            <a href="ReportMan.jsp">▤ <span>Manage Reports</span></a>
            <a href="UserManage.jsp">♙ <span>User Management</span></a>
            <a href="PoliceInfo.jsp">♧ <span>Police Information</span></a>
            <a href="AdminInfo.jsp">◉ <span>Admin Information</span></a>
            <a href="Settings.jsp">⚙ <span>Settings</span></a>
        </nav>
        <div class="crs-side-bottom"><a class="crs-side-nav" href="Logout.jsp" style="display:flex;">↪ <span>Logout</span></a></div>
    </aside>
    <main class="crs-main">
        <header class="crs-topbar">
            <input class="crs-topbar-search" type="search" placeholder="Search reports, users, or settings...">
            <div class="crs-nav-actions">
                <button class="crs-btn crs-theme-toggle" type="button" onclick="CRSTheme.toggle()"><span data-theme-icon>☾</span></button>
                <a class="crs-btn crs-btn-outline" href="UserHome.jsp">User Dashboard</a>
                <span style="font-size:13px;color:var(--text-soft);font-weight:700;"><%= currentUser %></span>
                <% if (imageBytes != null) { %>
                    <img src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile" style="width:34px;height:34px;border-radius:50%;object-fit:cover;border:1px solid var(--border);">
                <% } else { %>
                    <img src="images/default.png" alt="Profile" style="width:34px;height:34px;border-radius:50%;object-fit:cover;border:1px solid var(--border);">
                <% } %>
            </div>
        </header>
        <section class="crs-content">
            <div class="crs-page-title">
                <div><h1>Admin dashboard</h1><p>Manage reports, users, and system information from one place.</p></div>
                <span class="crs-badge crs-badge-info">Administrator</span>
            </div>
            <div class="crs-stat-grid">
                <article class="crs-card crs-stat"><div class="crs-stat-label">Report management</div><div class="crs-stat-value">→</div><a class="crs-btn crs-btn-outline" href="ReportMan.jsp">Open reports</a></article>
                <article class="crs-card crs-stat"><div class="crs-stat-label">Registered users</div><div class="crs-stat-value">→</div><a class="crs-btn crs-btn-outline" href="UserManage.jsp">Manage users</a></article>
                <article class="crs-card crs-stat"><div class="crs-stat-label">Police directory</div><div class="crs-stat-value">→</div><a class="crs-btn crs-btn-outline" href="PoliceInfo.jsp">View police</a></article>
                <article class="crs-card crs-stat"><div class="crs-stat-label">Admin directory</div><div class="crs-stat-value">→</div><a class="crs-btn crs-btn-outline" href="AdminInfo.jsp">View admins</a></article>
            </div>
            <div class="crs-card" style="margin-top:18px;padding:24px;">
                <h2 style="margin:0;font-size:19px;">Welcome back, <%= currentUser %></h2>
                <p style="margin:8px 0 0;color:var(--text-muted);line-height:1.65;">Use the navigation to review submitted crime reports, manage registered accounts, and maintain police and administrator information.</p>
                <div style="display:flex;gap:10px;flex-wrap:wrap;margin-top:20px;">
                    <a class="crs-btn crs-btn-primary" href="ReportMan.jsp">Review reports</a>
                    <a class="crs-btn crs-btn-outline" href="UserManage.jsp">Manage users</a>
                    <a class="crs-btn crs-btn-ghost" href="Settings.jsp">Open settings</a>
                </div>
            </div>
        </section>
    </main>
</div>
</body>
</html>
