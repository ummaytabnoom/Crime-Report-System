<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>
<%@ page import="utils.DBConnection" %>
<%
    // Get user data from session
    Integer currentUserId = (Integer) session.getAttribute("userId");
    String currentUserName = (String) session.getAttribute("username");

    // If user is not logged in, redirect to login page immediately.
    // This prevents any NullPointerException and forces authentication.
    if (currentUserId == null || currentUserName == null) {
        response.sendRedirect("Login.jsp"); // Redirect to your Login page
        return; // Stop further execution
    }

    byte[] imageBytes = null;
    List<Map<String,Object>> crimeList = new ArrayList<>();

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
conn = DBConnection.getConnection();

        // Use the userId from the session to get the profile picture.
        stmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID=?");
        stmt.setInt(1, currentUserId);
        rs = stmt.executeQuery();
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

        // Get all reported crimes from the PERMANENT_REPORTS table
        PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM REPORTED_CRIMES ORDER BY CRIME_ID DESC");
        ResultSet crimesRs = ps.executeQuery();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

        while (crimesRs.next()) {
            Map<String, Object> crime = new HashMap<>();
            String hideIdentity = crimesRs.getString("HIDE_IDENTITY");

            crime.put("crimeId", crimesRs.getInt("CRIME_ID"));
            crime.put("userName", crimesRs.getString("USER_NAME"));
            crime.put("fullName", crimesRs.getString("FULL_NAME"));
            crime.put("category", crimesRs.getString("CATEGORY"));
            crime.put("description", crimesRs.getString("DESCRIPTION"));
            crime.put("status", crimesRs.getString("STATUS"));

            java.sql.Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
            crime.put("date", (ts != null) ? sdf.format(ts) : "");

            String fullLocation = crimesRs.getString("ZILLA") + ", " +
                                  crimesRs.getString("UPAZILLA") + ", " +
                                  crimesRs.getString("POLICE_STATION") + ", " +
                                  crimesRs.getString("ROAD_NAME") + ", Road No: " +
                                  crimesRs.getString("ROAD_NO");
            crime.put("fullLocation", fullLocation);

            byte[] demoBytes = crimesRs.getBytes("MEDIA_FILE");
            crime.put("demoImg", (demoBytes != null) ? Base64.getEncoder().encodeToString(demoBytes) : "");

            // Fetch reporter info
            PreparedStatement userStmt = conn.prepareStatement(
                    "SELECT PROFILE_PICTURE, FULL_NAME, USER_NAME FROM REGISTERED_USERS WHERE USER_NAME=?");
            userStmt.setString(1, crimesRs.getString("USER_NAME"));
            ResultSet userRs = userStmt.executeQuery();

            String profileImg = "";
            String fullNameReal = "";
            String userNameReal = "";
            if(userRs.next()) {
                byte[] profileBytes = userRs.getBytes("PROFILE_PICTURE");
                if(profileBytes != null) profileImg = Base64.getEncoder().encodeToString(profileBytes);
                fullNameReal = userRs.getString("FULL_NAME");
                userNameReal = userRs.getString("USER_NAME");
            }
            userRs.close();
            userStmt.close();

            // For anonymous posts, override personal info
            if("YES".equalsIgnoreCase(hideIdentity)) {
                crime.put("displayName", "Anonymous");
                crime.put("displayUsername", "");
                crime.put("profileImg", "");
            } else {
                crime.put("displayName", fullNameReal);
                crime.put("displayUsername", "@" + userNameReal);
                crime.put("profileImg", profileImg);
            }

            crimeList.add(crime);
        }
        crimesRs.close();
        ps.close();
        
    } catch (Exception e) {
        out.println("<p class='message error'>Database Error: " + e.getMessage() + "</p>");
    } finally {
        try { if (conn != null) conn.close(); } catch (SQLException e) { /* ignore */ }
    }
%>


<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
    <title>User Home</title>
    
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-updatecrime">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>

<div class="navbar">
    <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUserName %></span>
    </div>
    <div class="top-right-buttons">
        <a href="ReportSub.jsp">Report_Crime</a>
        <a href="MyReports.jsp">My Reports</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="Settings.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
<h2>All Reported Crime Incidents</h2>
<input type="text" id="searchInput" class="search-bar" placeholder="Search by location..." onkeyup="filterCrimes()">

<% if (!crimeList.isEmpty()) {
    for (Map<String,Object> crime : crimeList) {
        String displayName = (String) crime.get("displayName");
%>
<div class="crime-container">
    <% String profileImg = (String) crime.get("profileImg"); %>
    <% if(displayName.equals("Anonymous")) { %>
        <img src="images/default.png" class="profile-image" alt="Anonymous"/>
    <% } else if(profileImg != null && !profileImg.isEmpty()) { %>
        <img src="data:image/jpeg;base64,<%= profileImg %>" class="profile-image" alt="Profile"/>
    <% } else { %>
        <img src="images/default.png" class="profile-image" alt="Default"/>
    <% } %>

    <h3><%= displayName %><small class="report-username"><%= crime.get("displayUsername") %></small></h3>
    <% if(!displayName.equals("Anonymous")) { %>
        <span class="body-small"></span>
    <% } %>

    <p><strong>Category:</strong> <%= crime.get("category") %></p>
    <p class="crime-location"><strong>Location:</strong> <%= crime.get("fullLocation") %></p>
    <p><strong>Date:</strong> <%= crime.get("date") %></p>
    <p><strong>Status:</strong> <%= crime.get("status") %></p>
    <p><strong>Description:</strong> <%= crime.get("description") %></p>

    <% String demoImg = (String) crime.get("demoImg"); %>
    <% if(demoImg != null && !demoImg.isEmpty()) { %>
        <img src="data:image/jpeg;base64,<%= demoImg %>" class="crime-image" alt="Crime Image"/>
    <% } else { %>
        <p><i>No crime image uploaded.</i></p>
    <% } %>
</div>
<% } } else { %>
    <p class="text-center">No reported crimes found.</p>
<% } %>
</div>

<script>
function toggleMenu() {
    document.getElementById("dropdownMenu").classList.toggle("show");
}
function filterCrimes() {
    const input = document.getElementById("searchInput").value.toLowerCase();
    const containers = document.getElementsByClassName("crime-container");
    for (let i = 0; i < containers.length; i++) {
        const locationElement = containers[i].querySelector(".crime-location");
        containers[i].style.display = locationElement.innerText.toLowerCase().includes(input) ? "block" : "none";
    }
}
</script>
</body>
</html>