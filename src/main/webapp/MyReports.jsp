<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.*, java.util.Base64" %>
<%
    String currentUser = (String) session.getAttribute("username");
    byte[] imageBytes = null;
    List<Map<String, Object>> crimeList = new ArrayList<>();

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        Connection conn = DriverManager.getConnection(
            "jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

        // Get user profile picture
        PreparedStatement stmt = conn.prepareStatement(
            "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?");
        stmt.setString(1, currentUser);
        ResultSet rs = stmt.executeQuery();
        if(rs.next()) {
            Blob blob = rs.getBlob("PROFILE_PICTURE");
            if(blob != null) {
                InputStream is = blob.getBinaryStream();
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                byte[] buffer = new byte[1024];
                int bytesRead;
                while((bytesRead = is.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
                imageBytes = os.toByteArray();
                is.close();
            }
        }
        rs.close();
        stmt.close();

        // Fetch all crimes of current user
        PreparedStatement ps = conn.prepareStatement(
            "SELECT * FROM REPORTED_CRIMES WHERE USER_NAME=? ORDER BY REPORT_ID DESC");
        ps.setString(1, currentUser);
        ResultSet crimesRs = ps.executeQuery();

        while(crimesRs.next()) {
            Map<String,Object> crime = new HashMap<>();
            crime.put("crimeId", crimesRs.getInt("REPORT_ID"));
            crime.put("fullName", crimesRs.getString("FULL_NAME"));
            crime.put("category", crimesRs.getString("CATEGORY"));
            crime.put("description", crimesRs.getString("DESCRIPTION"));
            crime.put("status", crimesRs.getString("STATUS"));
            java.sql.Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
            String dateOnly = (ts != null) ? new java.text.SimpleDateFormat("yyyy-MM-dd").format(ts) : "";
            crime.put("date", dateOnly);
            crime.put("hideIdentity", crimesRs.getString("HIDE_IDENTITY"));
            String zilla = crimesRs.getString("ZILLA");
            String upazilla = crimesRs.getString("UPAZILLA");
            String policeStation = crimesRs.getString("POLICE_STATION");
            String roadName = crimesRs.getString("ROAD_NAME");
            String roadNo = crimesRs.getString("ROAD_NO");
            crime.put("fullLocation", zilla + ", " + upazilla + ", " + policeStation + ", " + roadName + ", Road No: " + roadNo);
            byte[] demoBytes = crimesRs.getBytes("DEMO_PICTURE");
            crime.put("demoImg", (demoBytes != null) ? Base64.getEncoder().encodeToString(demoBytes) : "");
            crimeList.add(crime);
        }

        crimesRs.close();
        ps.close();
        conn.close();
    } catch(Exception e) {
        out.println("<p style='color:red'>Database Error: "+e.getMessage()+"</p>");
    }
%>

<html>
<head>
    <title>My Reported Crimes</title>
    <style>
        body { margin:0; padding:0;
            background: url("images/adminMan.png") no-repeat center center fixed; background-size:cover; font-family:Arial,sans-serif; color:white; }
        .navbar { background-color:#FF8C00; padding:14px 20px; display:flex; justify-content:space-between; }
        .menu-icon { font-size:26px; cursor:pointer; position:relative; top:10px; }
        .dropdown { position:absolute; top:60px; right:20px; background-color:white; color:black; border-radius:6px; display:none; flex-direction:column; min-width:180px; z-index:999; }
        .dropdown a { padding:12px 16px; text-decoration:none; color:#333; border-bottom:1px solid #eee; }
        .dropdown a:hover { background-color:#f2f2f2; }
        .show { display:flex; }
        .user-info { display:inline-flex; align-items:center; gap:10px; }
        .user-pic { width:50px; height:50px; border-radius:50%; object-fit:cover; border:2px solid #fff; }
        .user-name { font-weight:bold; color:white; font-size:25px; }
        h2 { text-align:center; margin:20px 0; color:black; }
        .crime-container { border:1px solid #ccc; padding:15px; margin:25px auto; border-radius:10px; background-color:#f2f2f2; color:black; width:80%; max-width:800px; box-shadow:0 0 10px rgba(0,0,0,0.2); position:relative; }
        .profile-image { width:60px; height:60px; object-fit:cover; border-radius:50%; float:left; margin-right:15px; border:2px solid #007BFF; }
        .crime-image { max-width:400px; max-height:300px; display:block; margin-top:15px; border-radius:8px; }
        .top-right-buttons { position:absolute; top:30px; left:65%; transform:translateX(0%); }
        .top-right-buttons a { background-color:#005F5F; color:white; padding:8px 20px; text-decoration:none; border-radius:5px; margin-right:10px; }
        .search-bar { width:60%; max-width:500px; margin:0 auto 20px auto; display:block; padding:10px 15px; border-radius:6px; border:1px solid #ccc; font-size:14px; }
        .edit-dropdown { display:none; position:absolute; right:0; top:35px; background-color:#fff; color:#000; border-radius:6px; box-shadow:0 2px 5px rgba(0,0,0,0.2); min-width:160px; z-index:10; }
        .edit-dropdown.show-edit { display:block; }
        .edit-dropdown a { display:block; padding:10px; text-decoration:none; color:#333; border-bottom:1px solid #eee; }
        .edit-dropdown a:last-child { border-bottom:none; color:red; }
        .edit-dropdown a:hover { background-color:#f2f2f2; }
         .content-box {
            background-color: rgba(255, 255, 255, 0.95);
            padding: 30px;
            border-radius: 10px;
            max-width: 1200px;
            margin: 40px auto;
            color: black;
        }
        .edit-btn { background-color:#005F5F; color:white; border:none; padding:6px 12px; border-radius:4px; cursor:pointer; }
        #notification { position:fixed; top:50%; left:50%; transform:translate(-50%,-50%); background-color:#005F5F; color:white; padding:15px 30px; border-radius:8px; box-shadow:0 0 10px rgba(0,0,0,0.5); font-size:18px; z-index:1000; text-align:center; display:none; }
    </style>
</head>
<body>
<div class="navbar">
    <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>
    <div class="top-right-buttons">
        <a href="UserHome.jsp">User Dashboard</a>
        <a href="ReportSub.jsp">Report A Crime</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="Settings.jsp">Settings</a>
        <a href="Notifications.jsp">Notifications</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>
<div id="notification"></div>
<div class="content-box">
<h2>My Reported Crimes</h2>
<input type="text" id="searchInput" class="search-bar" placeholder="Search by location..." onkeyup="filterCrimes()">

<% for(Map<String,Object> crime : crimeList) { 
        int crimeId = (int) crime.get("crimeId");
        String hideIdentity = (String) crime.get("hideIdentity");
        boolean isAnonymous = "yes".equalsIgnoreCase(hideIdentity);
        String displayName = isAnonymous ? "Anonymous" : (String) crime.get("fullName");
        String profileImgSrc = isAnonymous ? "images/default.png" : (imageBytes != null ? "data:image/jpeg;base64,"+Base64.getEncoder().encodeToString(imageBytes) : "images/default.png");
%>
<div class="crime-container" id="crime<%= crimeId %>">
    <!-- Edit Button -->
    <div style="position:absolute; top:10px; right:10px;">
        <button class="edit-btn" onclick="toggleEditMenu('editMenu<%= crimeId %>')">Edit ▼</button>
        <div id="editMenu<%= crimeId %>" class="edit-dropdown" style="position:absolute; top:35px; right:0;">
            <a href="#" onclick="toggleIdentity(<%= crimeId %>); return false;"><%= isAnonymous ? "Display Identity" : "Hide Identity" %></a>
            <a href="#" onclick="editLocation(<%= crimeId %>); return false;">Edit Location</a>
            <a href="#" onclick="editDate(<%= crimeId %>); return false;">Edit Date</a>
            <a href="#" onclick="editDescription(<%= crimeId %>); return false;">Edit Description</a>
            <a href="#" onclick="deleteCrime(<%= crimeId %>); return false;">Delete Post</a>
        </div>
    </div>

    <img src="<%= profileImgSrc %>" class="profile-image" id="profile<%= crimeId %>" alt="Profile Picture">
    <h3 id="name<%= crimeId %>"><%= displayName %> <% if(!isAnonymous){ %> (Username: <%= currentUser %>) <% } %></h3>
    <p><strong>Category:</strong> <%= crime.get("category") %></p>
    <p><strong>Location:</strong> <span id="loc<%= crimeId %>"><%= crime.get("fullLocation") %></span></p>
    <p><strong>Date:</strong> <span id="date<%= crimeId %>"><%= crime.get("date") %></span></p>
    <p id="desc<%= crimeId %>"><strong>Description:</strong> <%= crime.get("description") %></p>
    <p><strong>Status:</strong> <%= crime.get("status") %></p>
    <% String demoImg = (String) crime.get("demoImg"); %>
    <% if(!demoImg.isEmpty()) { %>
        <img src="data:image/jpeg;base64,<%= demoImg %>" class="crime-image">
    <% } else { %>
        <p><i>No crime image uploaded.</i></p>
    <% } %>
</div>
<% } %>
</div>
<script>
function toggleMenu() {
    document.getElementById("dropdownMenu").classList.toggle("show");
}

function toggleEditMenu(id){
    document.querySelectorAll('.edit-dropdown').forEach(dd => { if(dd.id!==id) dd.classList.remove('show-edit'); });
    document.getElementById(id).classList.toggle('show-edit');
}

document.addEventListener('click', function(event){
    if(!event.target.matches('.edit-btn')){
        document.querySelectorAll('.edit-dropdown').forEach(dd => dd.classList.remove('show-edit'));
    }
});

function toggleIdentity(crimeId){
    const nameEl = document.getElementById("name"+crimeId);
    const profileEl = document.getElementById("profile"+crimeId);
    const editMenu = document.getElementById("editMenu"+crimeId);
    const identityLink = editMenu.querySelector('a');

    let newValue = "yes";
    if(nameEl.innerText.includes("Anonymous")){
        nameEl.innerHTML = "<%= currentUser %> (Username: <%= currentUser %>)";
        profileEl.src = "<%= (imageBytes != null) ? "data:image/jpeg;base64,"+Base64.getEncoder().encodeToString(imageBytes) : "images/default.png" %>";
        identityLink.innerText = "Hide Identity";
        newValue = "no";
    } else {
        nameEl.innerHTML = "Anonymous";
        profileEl.src = "images/default.png";
        identityLink.innerText = "Display Identity";
        newValue = "yes";
    }

    const xhr = new XMLHttpRequest();
    xhr.open("GET", "UpdateCrime.jsp?action=toggleIdentity&crimeId="+crimeId+"&value="+newValue, true);
    xhr.send();
}

function editLocation(crimeId){
    const newLocation = prompt("Enter new location (Zilla, Upazilla, Police Station, Road Name, Road No):");
    if(!newLocation) return;
    document.getElementById("loc"+crimeId).innerText = newLocation;
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "UpdateCrime.jsp?action=updateLocation&crimeId="+crimeId+"&value="+encodeURIComponent(newLocation), true);
    xhr.onload = function(){ if(xhr.responseText.trim()==="success") showNotification("Location updated successfully!"); else showNotification("Error updating location: "+xhr.responseText); };
    xhr.send();
}

function editDate(crimeId){
    const newDate = prompt("Enter new date (YYYY-MM-DD):");
    if(!newDate) return;
    document.getElementById("date"+crimeId).innerText = newDate;
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "UpdateCrime.jsp?action=updateDate&crimeId="+crimeId+"&value="+encodeURIComponent(newDate), true);
    xhr.onload = function(){ if(xhr.responseText.trim()==="success") showNotification("Date updated successfully!"); else showNotification("Error updating date: "+xhr.responseText); };
    xhr.send();
}

function deleteCrime(crimeId){
    if(!confirm("Are you sure you want to delete this report?")) return;
    const container = document.getElementById("crime"+crimeId);
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "UpdateCrime.jsp?action=deleteCrime&crimeId="+crimeId, true);
    xhr.onload = function(){ if(xhr.responseText.trim()==="success") container.remove(); else showNotification("Error deleting: "+xhr.responseText); };
    xhr.send();
}

function filterCrimes(){
    let input = document.getElementById("searchInput").value.toLowerCase();
    let crimes = document.querySelectorAll(".crime-container");
    crimes.forEach(c => {
        let loc = c.querySelector("span") ? c.querySelector("span").innerText.toLowerCase() : "";
        c.style.display = loc.includes(input) ? "" : "none";
    });
}

function editDescription(crimeId){
    const descEl = document.getElementById("desc"+crimeId);
    let currentText = descEl.innerText.replace("Description:","").trim();
    const newDesc = prompt("Enter new description:", currentText);
    if(!newDesc) return;
    descEl.innerHTML = "<strong>Description:</strong> " + newDesc;
    const xhr = new XMLHttpRequest();
    xhr.open("GET", "UpdateCrime.jsp?action=updateDescription&crimeId="+crimeId+"&value="+encodeURIComponent(newDesc), true);
    xhr.onload = function(){ if(xhr.responseText.trim()==="success") showNotification("Description updated successfully!"); else showNotification("Error updating description: "+xhr.responseText); };
    xhr.send();
}

function showNotification(message,duration=3000){
    const notif = document.getElementById("notification");
    notif.innerText = message;
    notif.style.display="block";
    setTimeout(()=>{ notif.style.display="none"; }, duration);
}
</script>
</body>
</html>
