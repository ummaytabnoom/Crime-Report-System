<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>

<%
    String currentUser = (String) session.getAttribute("username");
    Integer currentUserId = (Integer) session.getAttribute("userId");
    String userRole = (String) session.getAttribute("userRole");

    boolean isAdmin = "admin".equals(userRole);
    boolean isPolice = "police".equals(userRole);

    // ================= POLICE STATUS UPDATE HANDLING =================
    if (isPolice &&
            request.getParameter("crimeId") != null &&
            request.getParameter("newStatus") != null) {

        int crimeId = Integer.parseInt(request.getParameter("crimeId"));
        String newStatus = request.getParameter("newStatus");

        Connection updateConn = null;
        PreparedStatement updatePs = null;

        try {
            Class.forName("oracle.jdbc.OracleDriver");

            updateConn = DriverManager.getConnection(
                    "jdbc:oracle:thin:@localhost:1521:XE",
                    "system",
                    "a12345");

            // Updates the status and logs which police user performed the upgrade action
            updatePs = updateConn.prepareStatement(
                    "UPDATE REPORTED_CRIMES SET STATUS=?, UPGRADED_BY=? WHERE CRIME_ID=?");

            updatePs.setString(1, newStatus);
            updatePs.setString(2, currentUser);
            updatePs.setInt(3, crimeId);

            updatePs.executeUpdate();

        } catch(Exception ex) {
            out.println("<p style='color:red;'>Status Update Failed: "
                    + ex.getMessage() + "</p>");
        } finally {
            if(updatePs != null) updatePs.close();
            if(updateConn != null) updateConn.close();
        }
    }

    byte[] imageBytes = null;
    List<Map<String,Object>> crimeList = new ArrayList<>();

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        Connection conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:XE",
                "system",
                "a12345");

        // ================= CURRENT USER PROFILE DATA =================
        PreparedStatement stmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?");

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

        // ================= GET APPROVED CRIME RECORDS ONLY =================
        // Restricts entries to items processed through the Admin vetting panel (ACCEPTED_BY column populated)
        PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM REPORTED_CRIMES WHERE ACCEPTED_BY IS NOT NULL ORDER BY CRIME_ID DESC");

        ResultSet crimesRs = ps.executeQuery();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

        while (crimesRs.next()) {
            Map<String, Object> crime = new HashMap<>();
            String hideIdentity = crimesRs.getString("HIDE_IDENTITY");

            crime.put("crimeId", crimesRs.getInt("CRIME_ID"));
            crime.put("userName", crimesRs.getString("USER_NAME"));
            crime.put("fullName", crimesRs.getString("FULL_NAME"));
            crime.put("category", crimesRs.getString("CATEGORY"));
            
            // Reading CLOB safely
            Reader clobReader = crimesRs.getCharacterStream("DESCRIPTION");
            if (clobReader != null) {
                StringBuilder sb = new StringBuilder();
                char[] charBuf = new char[1024];
                int charsRead;
                while ((charsRead = clobReader.read(charBuf)) != -1) {
                    sb.append(charBuf, 0, charsRead);
                }
                crime.put("description", sb.toString());
            } else {
                crime.put("description", "");
            }

            crime.put("status", crimesRs.getString("STATUS"));
            crime.put("acceptedBy", crimesRs.getString("ACCEPTED_BY"));
            crime.put("upgradedBy", crimesRs.getString("UPGRADED_BY"));

            java.sql.Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
            String formattedDate = (ts != null) ? sdf.format(ts) : "";
            crime.put("date", formattedDate);

            String zilla = crimesRs.getString("ZILLA");
            String upazilla = crimesRs.getString("UPAZILLA");
            String policeStation = crimesRs.getString("POLICE_STATION");
            String area = crimesRs.getString("AREA");
            String roadName = crimesRs.getString("ROAD_NAME");
            String roadNo = crimesRs.getString("ROAD_NO");

            // Format address dynamically handling the updated schema properties
            String areaPart = (area != null && !area.trim().isEmpty()) ? area + ", " : "";
            crime.put("fullLocation",
                    zilla + ", " +
                    upazilla + ", " +
                    policeStation + ", " +
                    areaPart +
                    roadName + ", Road No: " +
                    roadNo);

         // Fetch media file and media type
            byte[] mediaBytes = crimesRs.getBytes("MEDIA_FILE");
            String mediaType = crimesRs.getString("MEDIA_TYPE");

            crime.put("mediaType", mediaType);

            if (mediaBytes != null) {
                crime.put("mediaData", Base64.getEncoder().encodeToString(mediaBytes));
            } else {
                crime.put("mediaData", "");
            }

            // ================= BACKEND INVESTIGATING REPORTER CONTACTS =================
            PreparedStatement userStmt = conn.prepareStatement(
                    "SELECT PROFILE_PICTURE, MOBILE, FULL_NAME, USER_NAME " +
                    "FROM REGISTERED_USERS WHERE USER_NAME=?");

            userStmt.setString(1, crimesRs.getString("USER_NAME"));
            ResultSet userRs = userStmt.executeQuery();

            String profileImg = "";
            String mobileNo = "";
            String fullNameReal = "";
            String userNameReal = "";

            if (userRs.next()) {
                byte[] profileBytes = userRs.getBytes("PROFILE_PICTURE");

                if (profileBytes != null) {
                    profileImg = Base64.getEncoder().encodeToString(profileBytes);
                }

                mobileNo = userRs.getString("MOBILE");
                fullNameReal = userRs.getString("FULL_NAME");
                userNameReal = userRs.getString("USER_NAME");
            }

            userRs.close();
            userStmt.close();

            crime.put("profileImg", profileImg);
            crime.put("mobileNo", mobileNo);
            crime.put("fullName", fullNameReal);
            crime.put("userName", userNameReal);
            crime.put("hideIdentity", hideIdentity);

            if ("YES".equalsIgnoreCase(hideIdentity)) {
                crime.put("displayName", "Anonymous");
                crime.put("displayUsername", "");
            } else {
                crime.put("displayName", fullNameReal);
                crime.put("displayUsername", " (Username: " + userNameReal + ")");
            }

            crimeList.add(crime);
        }

        crimesRs.close();
        ps.close();
        conn.close();

    } catch (Exception e) {
        out.println("<p style='color:red;'>Database Error: " + e.getMessage() + "</p>");
    }
%>

<!DOCTYPE html>
<html>
<head>
<title>User Home</title>
<style>
body{
    margin:0;
    padding:0;
    background:url("images/adminMan.png") no-repeat center center fixed;
    background-size:cover;
    font-family:Arial,sans-serif;
    color:white;
}
.navbar{
    background-color:#FF8C00;
    padding:14px 20px;
    display:flex;
    justify-content:space-between;
}
.menu-icon{
    font-size:26px;
    cursor:pointer;
    position:relative;
    top:10px;
}
.dropdown{
    position:absolute;
    top:60px;
    right:20px;
    background-color:white;
    color:black;
    border-radius:6px;
    display:none;
    flex-direction:column;
    min-width:180px;
    z-index:999;
}
.dropdown a{
    padding:12px 16px;
    text-decoration:none;
    color:#333;
    border-bottom:1px solid #eee;
}
.dropdown a:hover{ background-color:#f2f2f2; }
.show{ display:flex; }
.user-info{
    display:inline-flex;
    align-items:center;
    gap:10px;
}
.user-pic{
    width:50px;
    height:50px;
    border-radius:50%;
    object-fit:cover;
    border:2px solid #fff;
}
.user-name{
    font-weight:bold;
    color:white;
    font-size:25px;
}
.crime-container{
    border:1px solid #ccc;
    padding:15px;
    margin:25px auto;
    border-radius:10px;
    background-color:#f2f2f2;
    color:black;
    width:80%;
    max-width:800px;
    box-shadow:0 0 10px rgba(0,0,0,0.2);
}
.profile-image{
    width:60px;
    height:60px;
    object-fit:cover;
    border-radius:50%;
    float:left;
    margin-right:15px;
    border:2px solid #007BFF;
}
.crime-image{
    width:100%;
    max-width:600px;
    height:auto;
    display:block;
    margin-top:15px;
    border-radius:8px;
}
.top-right-buttons{
    position:absolute;
    top:30px;
    left:75%;
}
.top-right-buttons a{
    background-color:#005F5F;
    color:white;
    padding:8px 20px;
    text-decoration:none;
    border-radius:5px;
    margin-right:10px;
}
.search-bar{
    width:60%;
    max-width:650px;
    margin:0 auto 25px auto;
    background:#f5f5f5;
    border:1px solid #dcdcdc;
    border-radius:8px;
    padding:12px 18px;
    display:flex;
    align-items:center;
    gap:12px;
    box-sizing:border-box;
}
.search-bar input[type="text"]{
    flex-grow:1;
    padding:12px 15px;
    border-radius:6px;
    border:1px solid #ccc;
    font-size:14px;
    outline:none;
    background:white;
    box-sizing:border-box;
}
.search-bar input[type="text"]:focus{
    border-color:#007BFF;
    box-shadow:0 0 5px rgba(0,123,255,0.3);
}
.search-bar button{
    padding:11px 22px;
    border:none;
    border-radius:6px;
    background-color:#007BFF;
    color:white;
    font-size:14px;
    cursor:pointer;
    transition:0.3s ease;
}
.search-bar button:hover{ background-color:#0056b3; }
.content-box{
    background-color:rgba(255,255,255,0.95);
    padding:30px;
    border-radius:10px;
    max-width:1200px;
    margin:40px auto;
    color:black;
}
h2{
    text-align:center;
    margin-bottom:20px;
    color:black;
}
.user-info-btn{
    background-color:#007BFF;
    color:white;
    padding:6px 16px;
    border:none;
    border-radius:20px;
    cursor:pointer;
    font-weight:bold;
}
.status-btn-container{
    margin-top:15px;
    display: flex;
    gap: 10px;
}
.status-btn{
    padding:8px 16px;
    border:none;
    border-radius:6px;
    color:white;
    font-weight:bold;
    cursor:pointer;
}
.pending-btn{ background-color:orange; }
.ongoing-btn{ background-color:#007BFF; }
.resolved-btn{ background-color:green; }

#userModal{
    display:none;
    position:fixed;
    top:0;
    left:0;
    width:100%;
    height:100%;
    background:rgba(0,0,0,0.5);
    justify-content:center;
    align-items:center;
    z-index:1000;
}
#userModalContent{
    background:white;
    padding:30px;
    border-radius:15px;
    max-width:400px;
    text-align:center;
    color:black;
}
</style>
</head>

<body>

<div class="navbar">
    <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>">
        <% } else { %>
            <img class="user-pic" src="images/default.png">
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>

    <div class="top-right-buttons">
        <a href="MyReports.jsp">My Reports</a>
        <a href="ReportSub.jsp">Report Crime</a>
    </div>

    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <% if(isAdmin){ %>
            <a href="AdminsHome.jsp">Admin Panel</a>
        <% } %>
        <% if(isPolice){ %>
            <a href="PoliceHome.jsp">Police Panel</a>
        <% } %>
        <a href="Settings.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
<h2>All Approved Crime Incidents</h2>

<div class="search-bar">
    <input type="text" id="searchInput" placeholder="Search by location..." onkeyup="filterCrimes()">
    <button type="button" onclick="filterCrimes()">Search</button>
</div>

<%
if (crimeList != null && !crimeList.isEmpty()) {
    for (Map<String,Object> crime : crimeList) {
        String displayName = (String) crime.get("displayName");
        String hideIdentity = (String) crime.get("hideIdentity");
        String currentStatus = (String) crime.get("status");
        String approvedAdmin = (String) crime.get("acceptedBy");
        String updatingOfficer = (String) crime.get("upgradedBy");
%>

<div class="crime-container">
    <% 
    String profileImg = (String) crime.get("profileImg");
    if ("YES".equalsIgnoreCase(hideIdentity)) { 
    %>
        <img src="images/default.png" class="profile-image">
    <% } else if (profileImg != null && !profileImg.isEmpty()) { %>
        <img src="data:image/jpeg;base64,<%= profileImg %>" class="profile-image">
    <% } else { %>
        <img src="images/default.png" class="profile-image">
    <% } %>

    <h3>
    <% if("Anonymous".equals(displayName)) { %>
        <% if(isAdmin || isPolice){ %>
            <button class="user-info-btn" onclick="showUserInfo(
                '<%= crime.get("realFullName") %>',
                '<%= crime.get("realUsername") %>',
                '<%= crime.get("mobileNo") %>',
                '<%= crime.get("profileImg") %>')">
                Anonymous (View Info)
            </button>
        <% } else { %>
            <span style="background:#6c757d; color:white; padding:6px 16px; border-radius:20px; font-weight:bold; display:inline-block;">
                Anonymous
            </span>
        <% } %>
    <% } else { %>
        <%= displayName %>
        <%= crime.get("displayUsername") %>
        <span style="color:gray; font-size:14px;">| Mobile: <%= crime.get("mobileNo") %></span>
    <% } %>
    </h3>

    <p><strong>Category:</strong> <%= crime.get("category") %></p>
    <p class="crime-location"><strong>Location:</strong> <%= crime.get("fullLocation") %></p>
    <p><strong>Date:</strong> <%= crime.get("date") %></p>
    <p><strong>Description:</strong> <%= crime.get("description") %></p>
    <p><strong>Status:</strong> <%= currentStatus %></p>
    
    <%-- Metadata tags reporting vetting accountability --%>
    <p style="font-size:13px; color:#555; margin-top:-5px;">
        <span style="margin-right:15px;"><strong>Vetted By:</strong> <%= approvedAdmin %></span>
        <% if(updatingOfficer != null && !updatingOfficer.trim().isEmpty()) { %>
            <span><strong>Assigned Officer:</strong> <%= updatingOfficer %></span>
        <% } %>
    </p>

 <%
String mediaData = (String) crime.get("mediaData");
String mediaType = (String) crime.get("mediaType");

if (mediaData != null && !mediaData.isEmpty()) {

    if (mediaType != null && mediaType.startsWith("image/")) {
%>

        <img src="data:<%=mediaType%>;base64,<%=mediaData%>" class="crime-image">

<%
    } else if (mediaType != null && mediaType.startsWith("video/")) {
%>

        <video class="crime-video" controls width="350">
            <source src="data:<%=mediaType%>;base64,<%=mediaData%>" type="<%=mediaType%>">
            Your browser does not support the video tag.
        </video>

<%
    } else {
%>

        <p><i>Unsupported media type.</i></p>

<%
    }

} else {
%>

    <p><i>No media uploaded.</i></p>

<%
}
%>
    
</div>

<%
    }
} else {
%>
<p style="text-align:center; color:black; font-size:18px;">No approved crime records found.</p>
<%
}
%>
</div>

<div id="userModal">
    <div id="userModalContent">
        <img id="modalProfileImg" src="" style="width:80px; height:80px; border-radius:50%; margin:0 auto 10px auto; display:block;">
        <h3>User Information</h3>
        <p id="modalFullName"></p>
        <p id="modalUsername"></p>
        <p id="modalMobile"></p>
        <button onclick="closeModal()" style="padding: 6px 18px; cursor: pointer;">Close</button>
    </div>
</div>

<script>
function showUserInfo(fullName, userName, mobile, profileImg){
    const imgEl = document.getElementById("modalProfileImg");
    if(profileImg && profileImg !== ""){
        imgEl.src = "data:image/jpeg;base64," + profileImg;
    } else {
        imgEl.src = "images/default.png";
    }
    document.getElementById("modalFullName").innerText = "Full Name: " + fullName;
    document.getElementById("modalUsername").innerText = "Username: " + userName;
    document.getElementById("modalMobile").innerText = "Mobile No: " + mobile;
    document.getElementById("userModal").style.display = "flex";
}

function closeModal(){
    document.getElementById("userModal").style.display = "none";
}

function toggleMenu(){
    document.getElementById("dropdownMenu").classList.toggle("show");
}

function filterCrimes() {
    const input = document.getElementById("searchInput").value.toLowerCase();
    const containers = document.getElementsByClassName("crime-container");

    for (let i = 0; i < containers.length; i++) {
        const text = containers[i].innerText.toLowerCase();
        containers[i].style.display = text.includes(input) ? "block" : "none";
    }
}

window.onclick = function(event) {
    if (!event.target.matches('.menu-icon')) {
        let dropdown = document.getElementById("dropdownMenu");
        if (dropdown.classList.contains("show")) {
            dropdown.classList.remove("show");
        }
    }
}
</script>
</body>
</html>