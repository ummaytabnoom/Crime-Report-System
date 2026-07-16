<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.*, java.util.Base64" %>

<%
String currentUser = (String) session.getAttribute("username");
String userRole = (String) session.getAttribute("userRole");
boolean isAdmin = "admin".equals(userRole);
boolean isPolice = "police".equalsIgnoreCase(userRole);
String username = (String) session.getAttribute("username");

// Redirect to login if session has timed out
if (currentUser == null) {
    response.sendRedirect("Login.jsp");
    return;
}

byte[] imageBytes = null;
List<Map<String, Object>> crimeList = new ArrayList<>();

Connection conn = null;

/* =========================================================
   DATABASE ACTIONS (AJAX POST ENDPOINTS)
========================================================= */
String action = request.getParameter("action");

if(action != null){

    response.setContentType("text/plain");

    try{
        Class.forName("oracle.jdbc.OracleDriver");
        conn = DriverManager.getConnection(
            "jdbc:oracle:thin:@localhost:1521:XE",
            "system",
            "a12345"
        );
        
        conn.setAutoCommit(true);

        int crimeId = Integer.parseInt(request.getParameter("crimeId"));
        PreparedStatement ps = null;

        // FIXED BACKEND VERIFICATION LAYER: Checking the real column 'ACCEPTED'
        PreparedStatement checkStatusPs = conn.prepareStatement(
            "SELECT ACCEPTED FROM REPORTED_CRIMES WHERE CRIME_ID=? AND USER_NAME=?"
        );
        checkStatusPs.setInt(1, crimeId);
        checkStatusPs.setString(2, currentUser);
        ResultSet statusRs = checkStatusPs.executeQuery();
        
        boolean recordIsLocked = false;
        if(statusRs.next()){
            String currentAcceptedVal = statusRs.getString("ACCEPTED");
            if(currentAcceptedVal != null) {
                String cleanVal = currentAcceptedVal.replaceAll("\\s+", "").toLowerCase();
                if(cleanVal.contains("accepted") && !cleanVal.contains("notaccepted")) {
                    recordIsLocked = true;
                }
            }
        }
        statusRs.close();
        checkStatusPs.close();

        // If the report is already accepted, deny edit operations completely
        if(recordIsLocked && !"deleteCrime".equals(action)) {
            out.print("LOCKED: This report has already been accepted by an administrator and can no longer be edited.");
            try{ if(conn != null) conn.close(); }catch(Exception e){}
            return;
        }

        /* DELETE REPORT */
        if("deleteCrime".equals(action)){
            ps = conn.prepareStatement(
                "DELETE FROM REPORTED_CRIMES WHERE CRIME_ID=? AND USER_NAME=?"
            );
            ps.setInt(1, crimeId);
            ps.setString(2, currentUser);

            int rows = ps.executeUpdate();
            out.print(rows > 0 ? "success" : "Delete failed. You might not own this report.");
        }

        /* UPDATE DESCRIPTION */
        else if("updateDescription".equals(action)){
            String value = request.getParameter("value");
            ps = conn.prepareStatement(
                "UPDATE REPORTED_CRIMES SET DESCRIPTION=? WHERE CRIME_ID=? AND USER_NAME=?"
            );
            ps.setString(1, value);
            ps.setInt(2, crimeId);
            ps.setString(3, currentUser);

            int rows = ps.executeUpdate();
            out.print(rows > 0 ? "success" : "Update failed");
        }

        /* UPDATE DATE */
        else if("updateDate".equals(action)){
            String value = request.getParameter("value").replace("/", "-").trim();
            ps = conn.prepareStatement(
                "UPDATE REPORTED_CRIMES SET DATE_OF_INCIDENT=? WHERE CRIME_ID=? AND USER_NAME=?"
            );
            ps.setDate(1, java.sql.Date.valueOf(value));
            ps.setInt(2, crimeId);
            ps.setString(3, currentUser);

            int rows = ps.executeUpdate();
            out.print(rows > 0 ? "success" : "Date update failed");
        }

        /* UPDATE LOCATION split into standard schema values including AREA */
        else if("updateLocation".equals(action)){
            String value = request.getParameter("value");
            // Change split delimiter to pipe (|) and escape it (\\|) because it is a regex
            String[] parts = value.split("\\|"); 
            
            String zilla = parts.length > 0 ? parts[0].trim() : "N/A";
            String upazilla = parts.length > 1 ? parts[1].trim() : "N/A";
            String area = parts.length > 2 ? parts[2].trim() : "N/A";
            String policeStation = parts.length > 3 ? parts[3].trim() : "N/A";
            String roadName = parts.length > 4 ? parts[4].trim() : "N/A";
            String roadNo = parts.length > 5 ? parts[5].trim() : "N/A";

            // Make sure your database table includes the AREA column
            ps = conn.prepareStatement(
                "UPDATE REPORTED_CRIMES SET ZILLA=?, UPAZILLA=?, AREA=?, POLICE_STATION=?, ROAD_NAME=?, ROAD_NO=? WHERE CRIME_ID=? AND USER_NAME=?"
            );
            ps.setString(1, zilla);
            ps.setString(2, upazilla);
            ps.setString(3, area);
            ps.setString(4, policeStation);
            ps.setString(5, roadName);
            ps.setString(6, roadNo);
            ps.setInt(7, crimeId);
            ps.setString(8, currentUser);

            int rows = ps.executeUpdate();
            out.print(rows > 0 ? "success" : "Location update failed");
        }

        /* UPDATE CATEGORY */
        else if("updateCategory".equals(action)){
            String value = request.getParameter("value");
            ps = conn.prepareStatement(
                "UPDATE REPORTED_CRIMES SET CATEGORY=? WHERE CRIME_ID=? AND USER_NAME=?"
            );
            ps.setString(1, value);
            ps.setInt(2, crimeId);
            ps.setString(3, currentUser);

            int rows = ps.executeUpdate();
            out.print(rows > 0 ? "success" : "Category update failed");
        }

        /* TOGGLE IDENTITY */
        else if("toggleIdentity".equals(action)){
            String value = request.getParameter("value");
            ps = conn.prepareStatement(
                "UPDATE REPORTED_CRIMES SET HIDE_IDENTITY=? WHERE CRIME_ID=? AND USER_NAME=?"
            );
            ps.setString(1, value);
            ps.setInt(2, crimeId);
            ps.setString(3, currentUser);

            int rows = ps.executeUpdate();
            out.print(rows > 0 ? "success" : "Identity update failed");
        }

        if(ps != null) ps.close();

    }catch(Exception e){
        out.print("ERROR: " + e.getMessage());
    }
    finally{
        try{ if(conn != null) conn.close(); }catch(Exception e){}
    }
    return;
}

/* =========================================================
   INITIAL DATA LOAD LAYOUT
========================================================= */
try {
    Class.forName("oracle.jdbc.OracleDriver");
    conn = DriverManager.getConnection(
        "jdbc:oracle:thin:@localhost:1521:XE",
        "system",
        "a12345"
    );

    /* LOAD CURRENT USER PROFILE PICTURE */
    PreparedStatement stmt = conn.prepareStatement(
        "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?"
    );
    stmt.setString(1, currentUser);
    ResultSet rs = stmt.executeQuery();

    if(rs.next()){
        Blob blob = rs.getBlob("PROFILE_PICTURE");
        if(blob != null){
            InputStream is = blob.getBinaryStream();
            ByteArrayOutputStream os = new ByteArrayOutputStream();
            byte[] buffer = new byte[1024];
            int bytesRead;
            while((bytesRead = is.read(buffer)) != -1){
                os.write(buffer, 0, bytesRead);
            }
            imageBytes = os.toByteArray();
            is.close();
        }
    }
    rs.close();
    stmt.close();

    /* LOAD CRIMES POSTED BY THE LOGGED IN USER ONLY */
    PreparedStatement ps = conn.prepareStatement(
        "SELECT * FROM REPORTED_CRIMES WHERE USER_NAME=? ORDER BY CRIME_ID DESC"
    );
    ps.setString(1, currentUser);
    ResultSet crimesRs = ps.executeQuery();

    while(crimesRs.next()){
        Map<String,Object> crime = new HashMap<>();
        crime.put("crimeId", crimesRs.getInt("CRIME_ID"));
        crime.put("fullName", crimesRs.getString("FULL_NAME"));
        crime.put("category", crimesRs.getString("CATEGORY"));
        crime.put("status", crimesRs.getString("STATUS"));
        crime.put("hideIdentity", crimesRs.getString("HIDE_IDENTITY"));
        
        crime.put("accepted", crimesRs.getString("ACCEPTED"));

        Reader clobReader = crimesRs.getCharacterStream("DESCRIPTION");
        if (clobReader != null) {
            StringBuilder sb = new StringBuilder();
            char[] charBuf = new char[1024];
            int charsRead;
            while((charsRead = clobReader.read(charBuf)) != -1) {
                sb.append(charBuf, 0, charsRead);
            }
            crime.put("description", sb.toString());
        } else {
            crime.put("description", "");
        }

        java.sql.Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
        String dateOnly = (ts != null) ? new java.text.SimpleDateFormat("yyyy-MM-dd").format(ts) : "";
        crime.put("date", dateOnly);

        String zilla = crimesRs.getString("ZILLA");
        String upazilla = crimesRs.getString("UPAZILLA");
        String area = crimesRs.getString("AREA"); // RETRIEVING AREA COLUMN
        String policeStation = crimesRs.getString("POLICE_STATION");
        String roadName = crimesRs.getString("ROAD_NAME");
        String roadNo = crimesRs.getString("ROAD_NO");

        // Display Area safely inside the full location sequence string
        crime.put("fullLocation", zilla + ", " + upazilla + ", " + (area != null ? area : "N/A") + ", " + policeStation + ", " + roadName + ", Road No: " + roadNo);

     // Fetch media file and media type
        byte[] mediaBytes = crimesRs.getBytes("MEDIA_FILE");
        String mediaType = crimesRs.getString("MEDIA_TYPE");

        crime.put("mediaType", mediaType);

        if (mediaBytes != null) {
            crime.put("mediaData", Base64.getEncoder().encodeToString(mediaBytes));
        } else {
            crime.put("mediaData", "");
        }
        crimeList.add(crime);
    }
    crimesRs.close();
    ps.close();
    conn.close();

}catch(Exception e){
    out.println("<h3 style='color:red'>Initialization Error: " + e.getMessage() + "</h3>");
}
%>

<!DOCTYPE html>
<html>
<head>
<title>My Reported Crimes</title>
<style>
body{
    margin:0;
    padding:0;
    background:url("images/adminMan.png") no-repeat center center fixed;
    background-size:cover;
    font-family:Arial,sans-serif;
}
.navbar{
    background:#FF8C00;
    padding:14px 20px;
    display:flex;
    justify-content:space-between;
    align-items:center;
}
.user-info{
    display:flex;
    align-items:center;
    gap:10px;
}
.user-pic{
    width:50px;
    height:50px;
    border-radius:50%;
    object-fit:cover;
    border:2px solid white;
}
.user-name{
    font-size:24px;
    font-weight:bold;
    color:white;
}
  .top-right-buttons {
            position: absolute;
            top: 20px;
            left: 80%;
            transform: translateX(-50%);
            display: flex;
            gap: 20px;
        }
.top-right-buttons a{
    background:#005F5F;
    color:white;
    padding:8px 15px;
    border-radius:5px;
    text-decoration:none;
    margin-right:10px;
}
.menu-icon{
    font-size:28px;
    cursor:pointer;
    color:white;
}
.dropdown{
    position:absolute;
    top:60px;
    right:20px;
    background:white;
    display:none;
    flex-direction:column;
    min-width:180px;
    border-radius:8px;
    overflow:hidden;
    z-index:999;
}
.dropdown a{
    padding:12px;
    text-decoration:none;
    color:black;
    border-bottom:1px solid #eee;
}
.dropdown a:hover{
    background:#f2f2f2;
}
.show{
    display:flex;
}
.content-box{
    background:rgba(255,255,255,0.95);
    max-width:1200px;
    margin:40px auto;
    padding:30px;
    border-radius:12px;
}
h2{
    text-align:center;
}
.search-bar{
    width:60%;
    margin:auto;
    display:flex;
    gap:10px;
    margin-bottom:25px;
}
.search-bar input{
    flex:1;
    padding:12px;
}
.search-bar button{
    padding:12px 20px;
    background:#007BFF;
    color:white;
    border:none;
    cursor:pointer;
}
.crime-container{
    background:#f2f2f2;
    padding:20px;
    border-radius:10px;
    margin-bottom:25px;
    position:relative;
    color:black;
}
.profile-image{
    width:60px;
    height:60px;
    border-radius:50%;
    object-fit:cover;
}
.crime-image{
    max-width:400px;
    margin-top:15px;
    border-radius:8px;
}
.edit-btn{
    background:#005F5F;
    color:white;
    border:none;
    padding:8px 12px;
    border-radius:5px;
    cursor:pointer;
}
.edit-dropdown{
    display:none;
    position:absolute;
    right:0;
    top:35px;
    background:white;
    border-radius:8px;
    overflow:hidden;
    min-width:180px;
    box-shadow:0 2px 8px rgba(0,0,0,0.3);
}
.show-edit{
    display:block;
}
.edit-dropdown a{
    display:block;
    padding:12px;
    text-decoration:none;
    color:black;
    border-bottom:1px solid #eee;
}
.edit-dropdown a:hover{
    background:#f2f2f2;
}
#notification{
    position:fixed;
    top:30px;
    right:30px;
    background:#005F5F;
    color:white;
    padding:15px 25px;
    border-radius:8px;
    display:none;
    z-index:9999;
}
.crime-image,
.crime-video {
    max-width: 350px;
    max-height: 300px;
    border-radius: 8px;
    margin-top: 10px;
}
</style>
</head>

<body>

<div class="navbar">
    <div class="user-info">
        <% if(imageBytes != null){ %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>">
        <% } else { %>
            <img class="user-pic" src="images/default.png">
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>

    <div class="top-right-buttons">
        <a href="UserHome.jsp">Dashboard</a>
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

<div id="notification"></div>

<div class="content-box">
    <h2>My Reported Crimes</h2>
    <div class="search-bar">
        <input type="text" id="searchInput" placeholder="Search by location..." onkeyup="filterCrimes()">
        <button onclick="filterCrimes()">Search</button>
    </div>

    <%
    for(Map<String,Object> crime : crimeList){
        int crimeId = (int) crime.get("crimeId");
        String hideIdentity = (String) crime.get("hideIdentity");
        String currentStatus = (String) crime.get("status");
        String acceptedField = (String) crime.get("accepted");
        boolean isAnonymous = "yes".equalsIgnoreCase(hideIdentity);
        
        boolean isAccepted = false;
        if(acceptedField != null) {
            String cleanField = acceptedField.replaceAll("\\s+", "").toLowerCase();
            if(cleanField.contains("accepted") && !cleanField.contains("notaccepted")) {
                isAccepted = true;
            }
        }

        String displayName = isAnonymous ? "Anonymous" : (String) crime.get("fullName");
        String profileImgSrc = isAnonymous ? "images/default.png" : 
            (imageBytes != null ? "data:image/jpeg;base64,"+Base64.getEncoder().encodeToString(imageBytes) : "images/default.png");
    %>

    <div class="crime-container" id="crime<%= crimeId %>">
        <div style="position:absolute; top:10px; right:10px;">
            <% if(!isAccepted) { %>
                <button class="edit-btn" onclick="toggleEditMenu('editMenu<%= crimeId %>')">Edit ▼</button>
                <div id="editMenu<%= crimeId %>" class="edit-dropdown">
                    <a href="#" onclick="toggleIdentity(<%= crimeId %>); return false;"> <%= isAnonymous ? "Display Identity" : "Hide Identity" %></a>
                    <a href="#" onclick="editCategory(<%= crimeId %>); return false;">Edit Category</a>
                    <a href="#" onclick="editLocation(<%= crimeId %>); return false;">Edit Location/Area</a>
                    <a href="#" onclick="editDate(<%= crimeId %>); return false;">Edit Date</a>
                    <a href="#" onclick="editDescription(<%= crimeId %>); return false;">Edit Description</a>
                    <a href="#" onclick="deleteCrime(<%= crimeId %>); return false;">Delete Post</a>
                </div>
            <% } else { %>
                <span style="background:#28a745; color:white; padding:6px 12px; border-radius:5px; font-weight:bold; font-size:13px; display:inline-block; box-shadow: 0 1px 3px rgba(0,0,0,0.2);">✓ Approved & Locked</span>
            <% } %>
        </div>

        <img src="<%= profileImgSrc %>" class="profile-image" id="profile<%= crimeId %>">

<h3 id="name<%= crimeId %>"
    data-fullname="<%= crime.get("fullName") %>">
    <%= displayName %>
</h3>
        <p><strong>Category:</strong> <span id="cat<%= crimeId %>"><%= crime.get("category") %></span></p>
        <p><strong>Location:</strong> <span id="loc<%= crimeId %>"><%= crime.get("fullLocation") %></span></p>
        <p><strong>Date:</strong> <span id="date<%= crimeId %>"><%= crime.get("date") %></span></p>
        <p id="desc<%= crimeId %>"><strong>Description:</strong> <span id="descSpan<%= crimeId %>"><%= crime.get("description") %></span></p>
        <p><strong>Verification:</strong> <span style="font-weight:bold; color: <%= isAccepted ? "#28a745" : "#dc3545" %>;"><%= acceptedField %></span></p>
        <p><strong>Status:</strong> <%= currentStatus %></p>
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
    %>
</div>

<script>
function toggleMenu(){
    document.getElementById("dropdownMenu").classList.toggle("show");
}

function toggleEditMenu(id){
    document.querySelectorAll('.edit-dropdown').forEach(dd=>{
        if(dd.id!==id){ dd.classList.remove('show-edit'); }
    });
    document.getElementById(id).classList.toggle('show-edit');
}

document.addEventListener('click', function(event){
    if(!event.target.closest('.edit-btn')){
        document.querySelectorAll('.edit-dropdown').forEach(dd=>dd.classList.remove('show-edit'));
    }
});

function sendRequest(params, successCallback){
    const xhr = new XMLHttpRequest();
    xhr.open("POST", "<%= request.getRequestURI() %>", true);
    xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
    xhr.onreadystatechange = function(){
        if(xhr.readyState === 4){
            let response = xhr.responseText.trim();
            if(xhr.status === 200){
                console.log("Server Response:", response); // ADD THIS LINE
                if(response === "success"){
                    successCallback();
                } else if(response.startsWith("LOCKED:")){
                    alert(response.replace("LOCKED:", ""));
                    window.location.reload(); 
                } else {
                    showNotification(response);
                }
            } else {
                showNotification("Server Connection Error: Status " + xhr.status);
            }
        }
    };
    xhr.send(params);
}

function toggleIdentity(crimeId){

    const nameEl = document.getElementById("name" + crimeId);
    const profileEl = document.getElementById("profile" + crimeId);
    const identityLink = document.querySelector("#editMenu" + crimeId + " a");

    const fullName = nameEl.dataset.fullname;

    let newValue = nameEl.innerText.trim() === "Anonymous" ? "no" : "yes";

    sendRequest(
        "action=toggleIdentity&crimeId=" + crimeId + "&value=" + newValue,
        function(){

            if(newValue === "no"){

                // Show FULL NAME
                nameEl.innerHTML = fullName;

                profileEl.src =
                    "<%= (imageBytes != null)
                    ? "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(imageBytes)
                    : "images/default.png" %>";

                identityLink.innerText = "Hide Identity";

            }else{

                nameEl.innerHTML = "Anonymous";
                profileEl.src = "images/default.png";
                identityLink.innerText = "Display Identity";

            }

            showNotification("Identity updated successfully!");
        }
    );
}

function editCategory(crimeId) {
    const catSpan = document.getElementById("cat" + crimeId);
    let currentCat = catSpan.innerText.trim();
    const originalHTML = catSpan.innerHTML;

    let categories = ["Robbery", "Theft", "Assault", "Fraud", "Cybercrime", "Harassment", "Murder", "Other"];
    let optionsHtml = "";
    
    for(let i = 0; i < categories.length; i++) {
        let cat = categories[i];
        let selectedAttr = (cat.toLowerCase() === currentCat.toLowerCase()) ? "selected" : "";
        optionsHtml += "<option value='" + cat + "' " + selectedAttr + ">" + cat + "</option>";
    }

    catSpan.innerHTML = 
        "<div style='background:#fff; padding:12px; border:1px solid #ccc; border-radius:6px; margin-top:5px; display:inline-block; width:100%; box-sizing:border-box;'>" +
            "<label style='font-weight:bold; color:#333; margin-right:10px;'>Select Category:</label>" +
            "<select id='editCatSel" + crimeId + "' style='padding:6px; border:1px solid #ccc; border-radius:4px; width:50%; margin-bottom:10px;'>" +
                optionsHtml +
            "</select>" +
            "<br>" +
            "<button type='button' id='saveCatBtn" + crimeId + "' style='background:#005F5F; color:white; border:none; padding:5px 12px; border-radius:4px; cursor:pointer; font-weight:bold;'>Save</button>" +
            "<button type='button' id='cancelCatBtn" + crimeId + "' style='background:#888; color:white; border:none; padding:5px 12px; border-radius:4px; cursor:pointer; font-weight:bold; margin-left:5px;'>Cancel</button>" +
        "</div>";

    document.getElementById("cancelCatBtn" + crimeId).onclick = function() { catSpan.innerHTML = originalHTML; };

    document.getElementById("saveCatBtn" + crimeId).onclick = function() {
        let newValue = document.getElementById("editCatSel" + crimeId).value;
        sendRequest(
            "action=updateCategory&crimeId=" + crimeId + "&value=" + encodeURIComponent(newValue),
            function() {
                catSpan.innerText = newValue;
                showNotification("Category updated successfully!");
            }
        );
    };
}

function editLocation(crimeId) {
    const locSpan = document.getElementById("loc" + crimeId);
    let currentText = locSpan.innerText;

    let cleanText = currentText.replace(", Road No:", ",");
    let parts = cleanText.split(",");

    let currentZilla = parts[0] ? parts[0].trim() : "";
    let currentUpazilla = parts[1] ? parts[1].trim() : "";
    let currentArea = parts[2] ? parts[2].trim() : ""; // Extract existing Area values
    let currentPS = parts[3] ? parts[3].trim() : "";
    let currentRoadName = parts[4] ? parts[4].trim() : "";
    let currentRoadNo = parts[5] ? parts[5].trim() : "";

    const originalHTML = locSpan.innerHTML;

    locSpan.innerHTML = 
        "<div style='background: #ffffff; padding: 15px; border: 1px solid #ccc; border-radius: 6px; margin-top: 10px; display: inline-block; width: 100%; box-sizing: border-box; box-shadow: 0 2px 5px rgba(0,0,0,0.1);'>" +
        "<div style='margin-bottom: 8px;'>" +
        "<label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Zilla:</label>" +
        "<select id='editZilla" + crimeId + "' style='width:63%; padding:6px; border:1px solid #ccc; border-radius:4px;' onchange='populateUpazillas(" + crimeId + ")'>" +
            "<option value=''>Select Zilla</option>" +
        "</select>" +
    "</div>" +

    "<div style='margin-bottom: 8px;'>" +
        "<label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Upazilla:</label>" +
        "<select id='editUpazilla" + crimeId + "' style='width:63%; padding:6px; border:1px solid #ccc; border-radius:4px;' onchange='populatePoliceStations(" + crimeId + ")'>" +
            "<option value=''>Select Upazilla</option>" +
        "</select>" +
    "</div>" +

    "<div style='margin-bottom: 8px;'>" +
        "<label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Police Station:</label>" +
        "<select id='editPS" + crimeId + "' style='width:63%; padding:6px; border:1px solid #ccc; border-radius:4px;' onchange='populateAreas(" + crimeId + ")'>" +
            "<option value=''>Select Police Station</option>" +
        "</select>" +
    "</div>" +

    "<div style='margin-bottom: 8px;'>" +
        "<label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Area:</label>" +
        "<select id='editArea" + crimeId + "' style='width:63%; padding:6px; border:1px solid #ccc; border-radius:4px;'>" +
            "<option value=''>Select Area</option>" +
        "</select>" +
    "</div>" +
    "<div style='margin-bottom: 8px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Road Name:</label> <input type='text' id='editRoadName" + crimeId + "' value='" + currentRoadName + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div style='margin-bottom: 12px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Road No:</label> <input type='text' id='editRoadNo" + crimeId + "' value='" + currentRoadNo + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div>" +
                "<button type='button' id='saveLocBtn" + crimeId + "' style='background:#005F5F; color:white; border:none; padding:6px 15px; margin-right:5px; border-radius:4px; cursor:pointer; font-weight:bold;'>Save</button>" +
                "<button type='button' id='cancelLocBtn" + crimeId + "' style='background:#888; color:white; border:none; padding:6px 15px; border-radius:4px; cursor:pointer; font-weight:bold;'>Cancel</button>" +
            "</div>" +
        "</div>";

    document.getElementById("cancelLocBtn" + crimeId).onclick = function() { locSpan.innerHTML = originalHTML; };
 // Populate dropdowns
    populateDistricts(crimeId);

    populateDistricts(crimeId);

    document.getElementById("editZilla" + crimeId).value = currentZilla;
    populateUpazillas(crimeId);

    document.getElementById("editUpazilla" + crimeId).value = currentUpazilla;
    populatePoliceStations(crimeId);

    document.getElementById("editPS" + crimeId).value = currentPS;
    populateAreas(crimeId);

    document.getElementById("editArea" + crimeId).value = currentArea;
    document.getElementById("editArea" + crimeId).value = currentArea;
    document.getElementById("saveLocBtn" + crimeId).onclick = function() {
        let zilla = document.getElementById("editZilla" + crimeId).value.trim();
        let upazilla = document.getElementById("editUpazilla" + crimeId).value.trim();
        let area = document.getElementById("editArea" + crimeId).value.trim();
        let ps = document.getElementById("editPS" + crimeId).value.trim();
        let roadName = document.getElementById("editRoadName" + crimeId).value.trim();
        let roadNo = document.getElementById("editRoadNo" + crimeId).value.trim();

        // Combined string matches order processed inside backend action block
        let compositeValue = zilla + "| " + upazilla + "| " + area + "| " + ps + "| " + roadName + "| " + roadNo;

        sendRequest(
            "action=updateLocation&crimeId=" + crimeId + "&value=" + encodeURIComponent(compositeValue),
            function() {
            	let compositeValue = zilla + "|" + upazilla + "|" + area + "|" + ps + "|" + roadName + "|" + roadNo;
            	showNotification("Location and Area updated successfully!");
            }
        );
    };
}

function editDate(crimeId){
    const dateSpan = document.getElementById("date" + crimeId);
    let currentDate = dateSpan.innerText.trim();
    const originalHTML = dateSpan.innerHTML;

    dateSpan.innerHTML = 
        "<div style='background:#fff; padding:12px; border:1px solid #ccc; border-radius:6px; margin-top:5px; display:inline-block; width:100%; box-sizing:border-box;'>" +
            "<label style='font-weight:bold; color:#333; margin-right:10px;'>Incident Date:</label>" +
            "<input type=" + "'date'" + " id='editDateInput" + crimeId + "' value='" + currentDate + "' style='padding:6px; border:1px solid #ccc; border-radius:4px; width:50%; margin-bottom:10px;'>" +
            "<br>" +
            "<button type='button' id='saveDateBtn" + crimeId + "' style='background:#005F5F; color:white; border:none; padding:5px 12px; border-radius:4px; cursor:pointer; font-weight:bold;'>Save</button>" +
            "<button type='button' id='cancelDateBtn" + crimeId + "' style='background:#888; color:white; border:none; padding:5px 12px; border-radius:4px; cursor:pointer; font-weight:bold; margin-left:5px;'>Cancel</button>" +
        "</div>";

    document.getElementById("cancelDateBtn" + crimeId).onclick = function() { dateSpan.innerHTML = originalHTML; };

    document.getElementById("saveDateBtn" + crimeId).onclick = function() {
        let newValue = document.getElementById("editDateInput" + crimeId).value;
        if(!newValue) return;

        sendRequest(
            "action=updateDate&crimeId=" + crimeId + "&value=" + encodeURIComponent(newValue),
            function(){
                dateSpan.innerText = newValue;
                showNotification("Date updated!");
            }
        );
    };
}

function editDescription(crimeId){
    const descSpan = document.getElementById("descSpan" + crimeId);
    let currentDesc = descSpan.innerText.trim();
    const originalHTML = descSpan.innerHTML;

    descSpan.innerHTML = 
        "<div style='background:#fff; padding:12px; border:1px solid #ccc; border-radius:6px; margin-top:5px; display:block; width:100%; box-sizing:border-box;'>" +
            "<textarea id='editDescText" + crimeId + "' style='width:100%; height:100px; padding:6px; border:1px solid #ccc; border-radius:4px; box-sizing:border-box; margin-bottom:10px; resize:vertical;'>" + currentDesc + "</textarea>" +
            "<br>" +
            "<button type='button' id='saveDescBtn" + crimeId + "' style='background:#005F5F; color:white; border:none; padding:5px 12px; border-radius:4px; cursor:pointer; font-weight:bold;'>Save</button>" +
            "<button type='button' id='cancelDescBtn" + crimeId + "' style='background:#888; color:white; border:none; padding:5px 12px; border-radius:4px; cursor:pointer; font-weight:bold; margin-left:5px;'>Cancel</button>" +
        "</div>";

    document.getElementById("cancelDescBtn" + crimeId).onclick = function() { descSpan.innerHTML = originalHTML; };

    document.getElementById("saveDescBtn" + crimeId).onclick = function() {
        let newValue = document.getElementById("editDescText" + crimeId).value.trim();
        if(!newValue) return;

        sendRequest(
            "action=updateDescription&crimeId=" + crimeId + "&value=" + encodeURIComponent(newValue),
            function(){
                descSpan.innerText = newValue;
                showNotification("Description updated!");
            }
        );
    };
}

function deleteCrime(crimeId){
    if(!confirm("Are you sure you want to delete this report permanently?")) return;

    sendRequest(
        "action=deleteCrime&crimeId=" + crimeId,
        function(){
            document.getElementById("crime"+crimeId).remove();
            showNotification("Report deleted!");
        }
    );
}

function filterCrimes(){
    let input = document.getElementById("searchInput").value.toLowerCase();
    let crimes = document.querySelectorAll(".crime-container");
    crimes.forEach(c=>{
        let loc = c.querySelector("[id^='loc']").innerText.toLowerCase();
        c.style.display = loc.includes(input) ? "block" : "none";
    });
}

function showNotification(message){
    if(message.startsWith("ERROR:") || message.toLowerCase().includes("failed")) {
        alert("Database processing failed:\n" + message);
        return;
    }
    const notif = document.getElementById("notification");
    notif.innerText = message;
    notif.style.display = "block";
    setTimeout(()=>{ notif.style.display = "none"; }, 3000);
}
const locationData = {
		  "Bagerhat": {
		    "Bagerhat Sadar": {
		      "Bagerhat Model Thana": ["Bagerhat Municipality", "Rangdia", "Gotapara", "Khanpur", "Bemarta"]
		    },
		    "Chitalmari": {
		      "Chitalmari Thana": ["Chitalmari Municipality", "Barobaria", "Kolatola", "Shibpur"]
		    },
		    "Fakirhat": {
		      "Fakirhat Thana": ["Fakirhat Municipality", "Betaga", "Lakhpur", "Mulghar"]
		    },
		    "Kachua": {
		      "Kachua Thana": ["Kachua Municipality", "Gopalpur", "Raripara", "Dhopakhali"]
		    },
		    "Mollahat": {
		      "Mollahat Thana": ["Mollahat Municipality", "Gangni", "Kodalia", "Atjuri"]
		    },
		    "Mongla": {
		      "Mongla Thana": ["Mongla Port Area", "Mongla Municipality", "Burirdanga", "Chila"]
		    },
		    "Morrelganj": {
		      "Morrelganj Thana": ["Morrelganj Municipality", "Hoglabunia", "Khaualia", "Putikhali"]
		    },
		    "Rampal": {
		      "Rampal Thana": ["Rampal Municipality", "Baintala", "Perikhali", "Gourambha"]
		    },
		    "Sarankhola": {
		      "Sarankhola Thana": ["Sarankhola Municipality", "Rayenda", "Southkhali", "Khontakata"]
		    }
		  },

		  "Bandarban": {
		    "Bandarban Sadar": {
		      "Bandarban Sadar Thana": ["Bandarban Municipality", "Balaghata", "Rajbila", "Sualok"]
		    },
		    "Alikadam": {
		      "Alikadam Thana": ["Alikadam Municipality", "Kurukpatta", "Chokhyong", "Matamuhuri"]
		    },
		    "Lama": {
		      "Lama Thana": ["Lama Municipality", "Fasiakhali", "Aziznagar", "Sarai"]
		    },
		    "Naikhongchhari": {
		      "Naikhongchhari Thana": ["Naikhongchhari Municipality", "Dochhari", "Ghumdhum", "Baishari"]
		    },
		    "Rowangchhari": {
		      "Rowangchhari Thana": ["Rowangchhari Municipality", "Taracha", "Alikhong", "Kaptala"]
		    },
		    "Ruma": {
		      "Ruma Thana": ["Ruma Municipality", "Galenga", "Paindu", "Remakri"]
		    },
		    "Thanchi": {
		      "Thanchi Thana": ["Thanchi Municipality", "Tindu", "Remakri", "Bolitong"]
		    }
		  },

		  "Barguna": {
		    "Amtali": {
		      "Amtali Thana": ["Amtali Municipality", "Arpangasia", "Atharagasia", "Chawra"]
		    },
		    "Bamna": {
		      "Bamna Thana": ["Bamna Municipality", "Ramna", "Bukabunia", "Doutola"]
		    },
		    "Barguna Sadar": {
		      "Barguna Sadar Thana": ["Barguna Municipality", "Burirchar", "Ayla Patakata", "Fuljhuri"]
		    },
		    "Betagi": {
		      "Betagi Thana": ["Betagi Municipality", "Hosnabad", "Mokamia", "Kazirabad"]
		    },
		    "Patharghata": {
		      "Patharghata Thana": ["Patharghata Municipality", "Kalmegha", "Kakchira", "Nachnapara"]
		    },
		    "Taltali": {
		      "Taltali Thana": ["Taltali Municipality", "Barabagi", "Pancha Koralia", "Nishanbaria"]
		    }
		  },

		  "Barishal": {
		    "Agailjhara": {
		      "Agailjhara Thana": ["Agailjhara Municipality", "Bagdha", "Rajihar", "Gaila"]
		    },
		    "Babuganj": {
		      "Babuganj Thana": ["Babuganj Municipality", "Rahmatpur", "Chandpasha", "Madhabpasha"]
		    },
		    "Bakerganj": {
		      "Bakerganj Thana": ["Bakerganj Municipality", "Charadi", "Kolaskathi", "Nalua"]
		    },
		    "Banaripara": {
		      "Banaripara Thana": ["Banaripara Municipality", "Chakhar", "Uzirpur Road", "Baisari"]
		    },
		    "Barishal Sadar": {
		      "Kotwali Model Thana": ["Barishal City Corporation", "Rupatali", "Kashipur", "Nathullabad"]
		    },
		    "Gournadi": {
		      "Gournadi Thana": ["Gournadi Municipality", "Mahilara", "Batajor", "Sarikal"]
		    },
		    "Hizla": {
		      "Hizla Thana": ["Hizla Municipality", "Memania", "Harinathpur", "Guabaria"]
		    },
		    "Mehendiganj": {
		      "Mehendiganj Thana": ["Mehendiganj Municipality", "Gobindapur", "Lata", "Ulania"]
		    },
		    "Muladi": {
		      "Muladi Thana": ["Muladi Municipality", "Nazirpur", "Kazirchar", "Char Kalekhan"]
		    },
		    "Wazirpur": {
		      "Wazirpur Thana": ["Wazirpur Municipality", "Sholak", "Bamrail", "Jalla"]
		    }
		  },

		  "Bhola": {
		    "Bhola Sadar": {
		      "Bhola Sadar Thana": ["Bhola Municipality", "Rajapur", "Ilisha", "Dighaldi"]
		    },
		    "Borhanuddin": {
		      "Borhanuddin Thana": ["Borhanuddin Municipality", "Kachia", "Sachra", "Deula"]
		    },
		    "Char Fasson": {
		      "Char Fasson Thana": ["Char Fasson Municipality", "Nazirpur", "Aslampur", "Aminabad"]
		    },
		    "Daulatkhan": {
		      "Daulatkhan Thana": ["Daulatkhan Municipality", "Madanpur", "Hajipur", "Charpata"]
		    },
		    "Lalmohan": {
		      "Lalmohan Thana": ["Lalmohan Municipality", "Badarpur", "Dholigournagar", "Kalma"]
		    },
		    "Manpura": {
		      "Manpura Thana": ["Manpura Municipality", "Hazirhat", "South Sakuchia", "Uttar Sakuchia"]
		    },
		    "Tazumuddin": {
		      "Tazumuddin Thana": ["Tazumuddin Municipality", "Chanchra", "Shambhupur", "Sonapur"]
		    }
		  },

		  "Bogura": {
		    "Adamdighi": {
		      "Adamdighi Thana": ["Adamdighi Municipality", "Santahar", "Nashratpur", "Chapai"]
		    },
		    "Bogura Sadar": {
		      "Bogura Sadar Thana": ["Bogura Municipality", "Chelopara", "Malatinagar", "Namuja"]
		    },
		    "Dhunat": {
		      "Dhunat Thana": ["Dhunat Municipality", "Elangi", "Mathurapur", "Gopalnagar"]
		    },
		    "Dhupchanchia": {
		      "Dhupchanchia Thana": ["Dhupchanchia Municipality", "Gobindapur", "Talora", "Chandash"]
		    },
		    "Gabtali": {
		      "Gabtali Thana": ["Gabtali Municipality", "Mahishaban", "Naruamala", "Rameshwarpur"]
		    },
		    "Kahaloo": {
		      "Kahaloo Thana": ["Kahaloo Municipality", "Murail", "Kalai", "Durgapur"]
		    },
		    "Nandigram": {
		      "Nandigram Thana": ["Nandigram Municipality", "Bhatgram", "Thalta", "Burail"]
		    },
		    "Sariakandi": {
		      "Sariakandi Thana": ["Sariakandi Municipality", "Kutubpur", "Kornibari", "Bohail"]
		    },
		    "Shajahanpur": {
		      "Shajahanpur Thana": ["Shajahanpur Municipality", "Majhira", "Amrool", "Aria"]
		    },
		    "Sherpur": {
		      "Sherpur Thana": ["Sherpur Municipality", "Kusumbi", "Khanpur", "Mirzapur"]
		    },
		    "Shibganj": {
		      "Shibganj Thana": ["Shibganj Municipality", "Mokamtala", "Pirab", "Roynagar"]
		    },
		    "Sonatala": {
		      "Sonatala Thana": ["Sonatala Municipality", "Pakulla", "Balua", "Jorgacha"]
		    }
		  },

		  "Brahmanbaria": {
		    "Akhaura": {
		      "Akhaura Thana": ["Akhaura Municipality", "Mogra", "Monionda", "Gangasagar"]
		    },
		    "Ashuganj": {
		      "Ashuganj Thana": ["Ashuganj Municipality", "Durgapur", "Char Chartala", "Lalpur"]
		    },
		    "Bancharampur": {
		      "Bancharampur Thana": ["Bancharampur Municipality", "Ayubpur", "Rupasdi", "Salimabad"]
		    },
		    "Bijoynagar": {
		      "Bijoynagar Thana": ["Bijoynagar Municipality", "Pattan", "Singerbil", "Islampur"]
		    },
		    "Brahmanbaria Sadar": {
		      "Brahmanbaria Sadar Thana": ["Brahmanbaria Municipality", "Medda", "Machihata", "Sultanpur"]
		    },
		    "Kasba": {
		      "Kasba Thana": ["Kasba Municipality", "Kuti", "Bayek", "Mulgram"]
		    },
		    "Nabinagar": {
		      "Nabinagar Thana": ["Nabinagar Municipality", "Bitghar", "Krishnanagar", "Shibpur"]
		    },
		    "Nasirnagar": {
		      "Nasirnagar Thana": ["Nasirnagar Municipality", "Haripur", "Gokarna", "Burishwar"]
		    },
		    "Sarail": {
		      "Sarail Thana": ["Sarail Municipality", "Shahbazpur", "Noagaon", "Pakshimul"]
		    }
		  },

		  "Chandpur": {
		    "Chandpur Sadar": {
		      "Chandpur Model Thana": ["Chandpur Municipality", "Bishnupur", "Rajnagar", "Baburhat"]
		    },
		    "Faridganj": {
		      "Faridganj Thana": ["Faridganj Municipality", "Gobindapur", "Rupsha", "Balithuba"]
		    },
		    "Haimchar": {
		      "Haimchar Thana": ["Haimchar Municipality", "Gazipur", "Nilkamal", "Char Bhairabi"]
		    },
		    "Haziganj": {
		      "Haziganj Thana": ["Haziganj Municipality", "Barkul", "Hatila", "Kalatia"]
		    },
		    "Kachua": {
		      "Kachua Thana": ["Kachua Municipality", "Bitara", "Palakhali", "Ashrafpur"]
		    },
		    "Matlab Dakshin": {
		      "Matlab South Thana": ["Matlab Municipality", "Narayanpur", "Nayergaon", "Upadi"]
		    },
		    "Matlab Uttar": {
		      "Matlab North Thana": ["Matlab Uttar Municipality", "Mohanpur", "Satnal", "Sultanabad"]
		    },
		    "Shahrasti": {
		      "Shahrasti Thana": ["Shahrasti Municipality", "Suchipara", "Tamta", "Rayashree"]
		    }
		  },

		  "Chapai Nawabganj": {
		    "Bholahat": {
		      "Bholahat Thana": ["Bholahat Municipality", "Jambaria", "Chakkirti", "Shibganj Border Area"]
		    },
		    "Gomastapur": {
		      "Gomastapur Thana": ["Rahanpur Municipality", "Boalia", "Parbotipur", "Alinagar"]
		    },
		    "Nachole": {
		      "Nachole Thana": ["Nachole Municipality", "Kosba", "Fatehpur", "Nimtala"]
		    },
		    "Chapai Nawabganj Sadar": {
		      "Chapai Nawabganj Sadar Thana": ["Nawabganj Municipality", "Amnura", "Shahibag", "Islampur"]
		    },
		    "Shibganj": {
		      "Shibganj Thana": ["Shibganj Municipality", "Kansat", "Monakasha", "Baghdanga"]
		    }
		  },

		  "Chattogram": {
		    "Anwara": {
		      "Anwara Thana": ["Anwara Municipality", "Barkal", "Chaturi", "Bairag"]
		    },
		    "Banshkhali": {
		      "Banshkhali Thana": ["Banshkhali Municipality", "Baharchara", "Sadhanpur", "Katharia"]
		    },
		    "Boalkhali": {
		      "Boalkhali Thana": ["Boalkhali Municipality", "Kadhurkhil", "Saroatoli", "Popadia"]
		    },
		    "Chandanaish": {
		      "Chandanaish Thana": ["Chandanaish Municipality", "Satbaria", "Bailtali", "Dhopachhari"]
		    },
		    "Fatikchhari": {
		      "Fatikchhari Thana": ["Fatikchhari Municipality", "Nanupur", "Bhujpur", "Harualchhari"]
		    }
		},
		 "Cumilla": {
			    "Barura": {
			      "Barura Thana": ["Barura Municipality", "Adra", "Poyalgachha", "Galimpur"]
			    },
			    "Brahmanpara": {
			      "Brahmanpara Thana": ["Brahmanpara Municipality", "Shashidal", "Malapara", "Madhabpur"]
			    },
			    "Burichang": {
			      "Burichang Thana": ["Burichang Municipality", "Mokam", "Bakshimul", "Rajapur"]
			    },
			    "Chandina": {
			      "Chandina Thana": ["Chandina Municipality", "Madhaiya", "Joag", "Mahichail"]
			    },
			    "Chauddagram": {
			      "Chauddagram Thana": ["Chauddagram Municipality", "Gunabati", "Batisa", "Cheora"]
			    },
			    "Cumilla Adarsha Sadar": {
			      "Kotwali Model Thana": ["Cumilla City", "Kandirpar", "Racecourse", "Shaktala"]
			    },
			    "Cumilla Sadar Dakshin": {
			      "Sadar Dakshin Thana": ["Paduar Bazar", "Bijoypur", "Barapara", "Suagazi"]
			    },
			    "Daudkandi": {
			      "Daudkandi Thana": ["Daudkandi Municipality", "Eliotganj", "Jinglatali", "Goalmari"]
			    },
			    "Debidwar": {
			      "Debidwar Thana": ["Debidwar Municipality", "Fatehabad", "Rajamehar", "Rasulpur"]
			    },
			    "Homna": {
			      "Homna Thana": ["Homna Municipality", "Mathabhanga", "Nilokhi", "Asadpur"]
			    },
			    "Laksam": {
			      "Laksam Thana": ["Laksam Municipality", "Mudaffarganj", "Ajgara", "Bipulasar"]
			    },
			    "Meghna": {
			      "Meghna Thana": ["Meghna Municipality", "Chalivanga", "Luterchar", "Manikar Char"]
			    },
			    "Monohorganj": {
			      "Monohorganj Thana": ["Monohorganj Municipality", "Hasnabad", "Uttar Hawla", "Bipulasar"]
			    },
			    "Muradnagar": {
			      "Muradnagar Thana": ["Muradnagar Municipality", "Bangra", "Companyganj", "Ramchandrapur"]
			    },
			    "Nangalkot": {
			      "Nangalkot Thana": ["Nangalkot Municipality", "Dhalua", "Mokara", "Roykot"]
			    },
			    "Titas": {
			      "Titas Thana": ["Titas Municipality", "Jagatpur", "Majidpur", "Narandia"]
			    }
			  },

			  "Cox's Bazar": {
			    "Chakaria": {
			      "Chakaria Thana": ["Chakaria Municipality", "Dulahazara", "Harbang", "Badarkhali"]
			    },
			    "Cox's Bazar Sadar": {
			      "Cox's Bazar Model Thana": ["Cox's Bazar Municipality", "Kolatoli", "Jhilongja", "Eidgaon"]
			    },
			    "Kutubdia": {
			      "Kutubdia Thana": ["Kutubdia Municipality", "Ali Akbar Dale", "North Dhurung", "Lemshikhali"]
			    },
			    "Maheshkhali": {
			      "Maheshkhali Thana": ["Maheshkhali Municipality", "Gorakghata", "Kalarmarchhara", "Hoanak"]
			    },
			    "Pekua": {
			      "Pekua Thana": ["Pekua Municipality", "Magnama", "Rajakhali", "Shilkhali"]
			    },
			    "Ramu": {
			      "Ramu Thana": ["Ramu Municipality", "Fatekharkul", "Khuniapalong", "Joarianala"]
			    },
			    "Teknaf": {
			      "Teknaf Model Thana": ["Teknaf Municipality", "Hnila", "Baharchhara", "Shah Porir Dwip"]
			    },
			    "Ukhia": {
			      "Ukhia Thana": ["Ukhia Municipality", "Kutupalong", "Palongkhali", "Rajapalong"]
			    }
			  },

			  "Dhaka": {
			    "Dhamrai": {
			      "Dhamrai Model Thana": ["Dhamrai Municipality", "Nannar", "Kalampur", "Chauhatta"]
			    },
			    "Dohar": {
			      "Dohar Thana": ["Dohar Municipality", "Muksudpur", "Narisha", "Kushumhati"]
			    },
			    "Keraniganj": {
			      "Keraniganj Model Thana": ["Central Keraniganj", "Ruhitpur", "Zinjira", "Kaliganj"],
			      "South Keraniganj Thana": ["South Keraniganj", "Shakta", "Teghoria", "Konda"]
			    },
			    "Nawabganj": {
			      "Nawabganj Thana": ["Nawabganj Municipality", "Bandura", "Agla", "Kalakopa"]
			    },
			    "Savar": {
			      "Savar Model Thana": ["Savar Municipality", "Hemayetpur", "Aminbazar", "Genda"],
			      "Ashulia Thana": ["Ashulia", "Zirabo", "Baipail", "DEPZ Area"]
			    }
			  },

			  "Dinajpur": {
			    "Biral": {
			      "Biral Thana": ["Biral Municipality", "Mongalpur", "Azimpur", "Bijora"]
			    },
			    "Birampur": {
			      "Birampur Thana": ["Birampur Municipality", "Binail", "Katla", "Palashbari"]
			    },
			    "Bochaganj": {
			      "Bochaganj Thana": ["Bochaganj Municipality", "Setabganj", "Ishania", "Mushidhat"]
			    },
			    "Chirirbandar": {
			      "Chirirbandar Thana": ["Chirirbandar Municipality", "Auliapur", "Ranirbandar", "Saitara"]
			    },
			    "Dinajpur Sadar": {
			      "Kotwali Thana": ["Dinajpur Municipality", "Sundarban", "Pulhat", "Balubari"]
			    },
			    "Fulbari": {
			      "Fulbari Thana": ["Fulbari Municipality", "Khayerbari", "Shibnagar", "Daulatpur"]
			    },
			    "Ghoraghat": {
			      "Ghoraghat Thana": ["Ghoraghat Municipality", "Bulakipur", "Palsha", "Singra"]
			    },
			    "Hakimpur": {
			      "Hakimpur Thana": ["Hakimpur Municipality", "Hili", "Boaldar", "Khatta Madhabpara"]
			    },
			    "Kaharole": {
			      "Kaharole Thana": ["Kaharole Municipality", "Sundarpur", "Mukundapur", "Dashmail"]
			    },
			    "Khansama": {
			      "Khansama Thana": ["Khansama Municipality", "Angarpara", "Bhabanipur", "Goaldihi"]
			    },
			    "Nawabganj": {
			      "Nawabganj Thana": ["Nawabganj Municipality", "Daudpur", "Putimara", "Joypur"]
			    },
			    "Parbatipur": {
			      "Parbatipur Thana": ["Parbatipur Municipality", "Hamidpur", "Mostafapur", "Monmothpur"]
			    }
			  },

			  "Faridpur": {
			    "Alfadanga": {
			      "Alfadanga Thana": ["Alfadanga Municipality", "Gopalpur", "Tagarbanda", "Panchuria"]
			    },
			    "Bhanga": {
			      "Bhanga Thana": ["Bhanga Municipality", "Azimnagar", "Choumukha", "Kaijuri"]
			    },
			    "Boalmari": {
			      "Boalmari Thana": ["Boalmari Municipality", "Rupapat", "Chatul", "Shekhar"]
			    },
			    "Charbhadrasan": {
			      "Charbhadrasan Thana": ["Charbhadrasan Municipality", "Gazirtek", "Char Harirampur", "Sadar Char"]
			    },
			    "Faridpur Sadar": {
			      "Kotwali Thana": ["Faridpur Municipality", "Ambikapur", "Kanaipur", "North Channel"]
			    },
			    "Madhukhali": {
			      "Madhukhali Thana": ["Madhukhali Municipality", "Megchami", "Bagat", "Raipur"]
			    },
			    "Nagarkanda": {
			      "Nagarkanda Thana": ["Nagarkanda Municipality", "Kodalia", "Talma", "Laskardia"]
			    },
			    "Sadarpur": {
			      "Sadarpur Thana": ["Sadarpur Municipality", "Charnasirpur", "Krishnapur", "Akotter Char"]
			    },
			    "Saltha": {
			      "Saltha Thana": ["Saltha Municipality", "Atghar", "Ballabhdi", "Sonapur"]
			    }
			  },
			  "Feni": {
				    "Chhagalnaiya": {
				      "Chhagalnaiya Thana": ["Chhagalnaiya Municipality", "Mahamaya", "Radhanagar", "Ghopal"]
				    },
				    "Daganbhuiyan": {
				      "Daganbhuiyan Thana": ["Daganbhuiyan Municipality", "Matubhuiyan", "Rajapur", "Yakubpur"]
				    },
				    "Feni Sadar": {
				      "Feni Model Thana": ["Feni Municipality", "Lemua", "Fazilpur", "Baligaon"]
				    },
				    "Fulgazi": {
				      "Fulgazi Thana": ["Fulgazi Municipality", "Munshirhat", "Anandapur", "Darbarpur"]
				    },
				    "Parshuram": {
				      "Parshuram Thana": ["Parshuram Municipality", "Mirzanagar", "Chitholia", "Boxmahmud"]
				    },
				    "Sonagazi": {
				      "Sonagazi Thana": ["Sonagazi Municipality", "Char Chandia", "Motiganj", "Amirabad"]
				    }
				  },

				  "Gaibandha": {
				    "Fulchhari": {
				      "Fulchhari Thana": ["Fulchhari Municipality", "Erendabari", "Konchipara", "Gazaria"]
				    },
				    "Gaibandha Sadar": {
				      "Gaibandha Thana": ["Gaibandha Municipality", "Kamarjani", "Malibari", "Ballamjhar"]
				    },
				    "Gobindaganj": {
				      "Gobindaganj Thana": ["Gobindaganj Municipality", "Mahimaganj", "Shalmara", "Kamardaha"]
				    },
				    "Palashbari": {
				      "Palashbari Thana": ["Palashbari Municipality", "Harinathpur", "Kishoregari", "Betkapa"]
				    },
				    "Sadullapur": {
				      "Sadullapur Thana": ["Sadullapur Municipality", "Naldanga", "Bonarpara", "Faridpur"]
				    },
				    "Saghata": {
				      "Saghata Thana": ["Saghata Municipality", "Bharatkhali", "Jumarbari", "Kamalerpara"]
				    },
				    "Sundarganj": {
				      "Sundarganj Thana": ["Sundarganj Municipality", "Bamandanga", "Haripur", "Kapasia"]
				    }
				  },

				  "Gazipur": {
				    "Gazipur Sadar": {
				      "Gazipur Sadar Thana": ["Gazipur Sadar Municipality", "Bason", "Kashimpur", "Konabari", "Pubail", "Joydebpur"]
				    },
				    "Kaliakair": {
				      "Kaliakair Thana": ["Kaliakair Municipality", "Chandra", "Baria", "Safipur", "Mouchak", "Sutrapur"]
				    },
				    "Kaliganj": {
				      "Kaliganj Thana": ["Kaliganj Municipality", "Tumulia", "Jamgora", "Vawal", "Nagori", "Dhaliora"]
				    },
				    "Kapasia": {
				      "Kapasia Thana": ["Kapasia Municipality", "Rayed", "Targaon", "Chandpur", "Singhasree", "Barishab"]
				    },
				    "Sreepur": {
				      "Sreepur Thana": ["Sreepur Municipality", "Bormi", "Maona", "Rajendrapur", "Gosinga", "Telihati"]
				    }
				  },

				  "Gopalganj": {
				    "Gopalganj Sadar": {
				      "Gopalganj Thana": ["Gopalganj Municipality", "Ulpur", "Karpara", "Borashi"]
				    },
				    "Kashiani": {
				      "Kashiani Thana": ["Kashiani Municipality", "Fukra", "Bethuri", "Maheshpur"]
				    },
				    "Kotalipara": {
				      "Kotalipara Thana": ["Kotalipara Municipality", "Pinjuri", "Kandi", "Hiron"]
				    },
				    "Muksudpur": {
				      "Muksudpur Thana": ["Muksudpur Municipality", "Jalirpar", "Batikamari", "Gobindapur"]
				    },
				    "Tungipara": {
				      "Tungipara Thana": ["Tungipara Municipality", "Patgati", "Gopalpur", "Dumuria"]
				    }
				  },

				  "Habiganj": {
				    "Ajmiriganj": {
				      "Ajmiriganj Thana": ["Ajmiriganj Municipality", "Shibpasha", "Jolsukha", "Kakailseo"]
				    },
				    "Bahubal": {
				      "Bahubal Thana": ["Bahubal Municipality", "Putijuri", "Lamatashi", "Mirpur"]
				    },
				    "Baniachong": {
				      "Baniachong Thana": ["Baniachong Municipality", "Muradpur", "Daulatpur", "Sujatpur"]
				    },
				    "Chunarughat": {
				      "Chunarughat Thana": ["Chunarughat Municipality", "Shayestaganj Road", "Gazipur", "Ranigaon"]
				    },
				    "Habiganj Sadar": {
				      "Habiganj Sadar Thana": ["Habiganj Municipality", "Laskarpur", "Richi", "Teghoria"]
				    },
				    "Lakhai": {
				      "Lakhai Thana": ["Lakhai Municipality", "Bamoi", "Muriauk", "Karab"]
				    },
				    "Madhabpur": {
				      "Madhabpur Thana": ["Madhabpur Municipality", "Jagadishpur", "Shahjahanpur", "Bulla"]
				    },
				    "Nabiganj": {
				      "Nabiganj Thana": ["Nabiganj Municipality", "Inathganj", "Debpara", "Aushkandi"]
				    },
				    "Shayestaganj": {
				      "Shayestaganj Thana": ["Shayestaganj Municipality", "Olipur", "Nurpur", "Chargaon"]
				    }
				  },
				  "Jamalpur": {
					    "Bakshiganj": {
					      "Bakshiganj Thana": ["Bakshiganj Municipality", "Merurchar", "Nilakhia", "Battajore"]
					    },
					    "Dewanganj": {
					      "Dewanganj Thana": ["Dewanganj Municipality", "Char Amkhawa", "Dangdhara", "Bahadurabad"]
					    },
					    "Islampur": {
					      "Islampur Thana": ["Islampur Municipality", "Gaibandha", "Palbandha", "Noarpara"]
					    },
					    "Jamalpur Sadar": {
					      "Jamalpur Sadar Thana": ["Jamalpur Municipality", "Narundi", "Titpalla", "Meshta"]
					    },
					    "Madarganj": {
					      "Madarganj Thana": ["Madarganj Municipality", "Balijuri", "Jorekhali", "Karaichara"]
					    },
					    "Melandaha": {
					      "Melandaha Thana": ["Melandaha Municipality", "Adra", "Durmut", "Mahmudpur"]
					    },
					    "Sarishabari": {
					      "Sarishabari Thana": ["Sarishabari Municipality", "Pingna", "Aona", "Satpoa"]
					    }
					  },

					  "Jashore": {
					    "Abhaynagar": {
					      "Abhaynagar Thana": ["Noapara Municipality", "Sundali", "Prembag", "Siddhipasha"]
					    },
					    "Bagherpara": {
					      "Bagherpara Thana": ["Bagherpara Municipality", "Narikelbaria", "Dhupkhali", "Jadabpur"]
					    },
					    "Chaugachha": {
					      "Chaugachha Thana": ["Chaugachha Municipality", "Hakimpur", "Narayanpur", "Patibila"]
					    },
					    "Jhikargachha": {
					      "Jhikargachha Thana": ["Jhikargachha Municipality", "Godkhali", "Panisara", "Magura"]
					    },
					    "Keshabpur": {
					      "Keshabpur Thana": ["Keshabpur Municipality", "Sagardari", "Trimohini", "Majidpur"]
					    },
					    "Jashore Sadar": {
					      "Kotwali Thana": ["Jashore Municipality", "Arabpur", "Chanchra", "Upashahar"]
					    },
					    "Manirampur": {
					      "Manirampur Thana": ["Manirampur Municipality", "Bhojgati", "Kultia", "Rajganj"]
					    },
					    "Sharsha": {
					      "Sharsha Thana": ["Benapole Municipality", "Navaron", "Bagachra", "Putkhali"]
					    }
					  },

					  "Jhalokathi": {
					    "Jhalokathi Sadar": {
					      "Jhalokathi Thana": ["Jhalokathi Municipality", "Keora", "Gabkhan", "Baukathi"]
					    },
					    "Kathalia": {
					      "Kathalia Thana": ["Kathalia Municipality", "Amua", "Patikhalghata", "Shouljalia"]
					    },
					    "Nalchity": {
					      "Nalchity Thana": ["Nalchity Municipality", "Kushangal", "Magar", "Subidpur"]
					    },
					    "Rajapur": {
					      "Rajapur Thana": ["Rajapur Municipality", "Galua", "Mathbari", "Saturia"]
					    }
					  },

					  "Jhenaidah": {
					    "Harinakunda": {
					      "Harinakunda Thana": ["Harinakunda Municipality", "Kapashatia", "Taherhuda", "Raghunathpur"]
					    },
					    "Jhenaidah Sadar": {
					      "Jhenaidah Sadar Thana": ["Jhenaidah Municipality", "Paglakanai", "Porahati", "Ganna"]
					    },
					    "Kaliganj": {
					      "Kaliganj Thana": ["Kaliganj Municipality", "Barobazar", "Rakhalgachhi", "Sundarpur"]
					    },
					    "Kotchandpur": {
					      "Kotchandpur Thana": ["Kotchandpur Municipality", "Elangi", "Baluhar", "Sabdalpur"]
					    },
					    "Maheshpur": {
					      "Maheshpur Thana": ["Maheshpur Municipality", "Nepa", "Shyamkur", "Swaruppur"]
					    },
					    "Shailkupa": {
					      "Shailkupa Thana": ["Shailkupa Municipality", "Kancherkol", "Tribeni", "Dudhsar"]
					    }
					  },

					  "Joypurhat": {
					    "Akkelpur": {
					      "Akkelpur Thana": ["Akkelpur Municipality", "Tilakpur", "Raykali", "Rukindipur"]
					    },
					    "Joypurhat Sadar": {
					      "Joypurhat Sadar Thana": ["Joypurhat Municipality", "Bhadsa", "Dogachi", "Puranapail"]
					    },
					    "Kalai": {
					      "Kalai Thana": ["Kalai Municipality", "Punot", "Matrai", "Udaypur"]
					    },
					    "Khetlal": {
					      "Khetlal Thana": ["Khetlal Municipality", "Mamudpur", "Borail", "Krishnanagar"]
					    },
					    "Panchbibi": {
					      "Panchbibi Thana": ["Panchbibi Municipality", "Aymarasulpur", "Bagjana", "Mohipur"]
					    }
					  },    	    															
						  "Khagrachhari": {
							    "Dighinala": {
							      "Dighinala Thana": ["Dighinala Municipality", "Babuchhara", "Boalkhali", "Kabakhali"]
							    },
							    "Khagrachhari Sadar": {
							      "Khagrachhari Sadar Thana": ["Khagrachhari Municipality", "Perachhara", "Golabari", "Shalbon"]
							    },
							    "Lakshmichhari": {
							      "Lakshmichhari Thana": ["Lakshmichhari Municipality", "Dulyatali", "Barmachhari", "Shantipur"]
							    },
							    "Mahalchhari": {
							      "Mahalchhari Thana": ["Mahalchhari Municipality", "Mobachhari", "Sindukchhari", "Maischhari"]
							    },
							    "Manikchhari": {
							      "Manikchhari Thana": ["Manikchhari Municipality", "Batnatali", "Baranala", "Tintahari"]
							    },
							    "Matiranga": {
							      "Matiranga Thana": ["Matiranga Municipality", "Belchhari", "Taindong", "Tubalchhari"]
							    },
							    "Panchhari": {
							      "Panchhari Thana": ["Panchhari Municipality", "Latiban", "Logang", "Ultachhari"]
							    },
							    "Ramgarh": {
							      "Ramgarh Thana": ["Ramgarh Municipality", "Hafchhari", "Patachhara", "Rabarbagh"]
							    },
							    "Guimara": {
							      "Guimara Thana": ["Guimara Municipality", "Sindukchhari", "Hafchhari", "Jaliyapara"]
							    }
							  },

							  "Khulna": {
							    "Batiaghata": {
							      "Batiaghata Thana": ["Batiaghata Municipality", "Amirpur", "Gangarampur", "Surkhali"]
							    },
							    "Dacope": {
							      "Dacope Thana": ["Dacope Municipality", "Bajua", "Laudob", "Kamarkhola"]
							    },
							    "Dumuria": {
							      "Dumuria Thana": ["Dumuria Municipality", "Kharnia", "Atlia", "Gutudia"]
							    },
							    "Dighalia": {
							      "Dighalia Thana": ["Dighalia Municipality", "Senhati", "Atra", "Jogipole"]
							    },
							    "Koyra": {
							      "Koyra Thana": ["Koyra Municipality", "Maharajpur", "Bagali", "Amadi"]
							    },
							    "Paikgachha": {
							      "Paikgachha Thana": ["Paikgachha Municipality", "Haridhali", "Gadaipur", "Kapilmuni"]
							    },
							    "Phultala": {
							      "Phultala Thana": ["Phultala Municipality", "Jamira", "Damodar", "Atra Ghilatala"]
							    },
							    "Rupsa": {
							      "Rupsa Thana": ["Rupsa Municipality", "Naihati", "Shrifaltala", "T. S. Bazar"]
							    },
							    "Terokhada": {
							      "Terokhada Thana": ["Terokhada Municipality", "Ajgara", "Barasat", "Sachiadah"]
							    },
							    "Khulna Sadar": {
							      "Khalishpur Thana": ["Khalishpur", "Doulatpur", "Atra Industrial Area", "Mujgunni"],
							      "Sonadanga Model Thana": ["Sonadanga", "Boyra", "Shibbari", "Moylapota"],
							      "Kotwali Thana": ["Khulna City", "Royal Mor", "Khan Jahan Ali Road", "Tutpara"]
							    }
							  },

							  "Kishoreganj": {
							    "Austagram": {
							      "Austagram Thana": ["Austagram Municipality", "Bangalpara", "Kastul", "Kalma"]
							    },
							    "Bajitpur": {
							      "Bajitpur Thana": ["Bajitpur Municipality", "Hilchia", "Pirijpur", "Sararchar"]
							    },
							    "Bhairab": {
							      "Bhairab Thana": ["Bhairab Municipality", "Aganagar", "Kalikaprasad", "Shibpur"]
							    },
							    "Hossainpur": {
							      "Hossainpur Thana": ["Hossainpur Municipality", "Gobindapur", "Jinari", "Araibaria"]
							    },
							    "Itna": {
							      "Itna Thana": ["Itna Municipality", "Elongjuri", "Baidyer Bazar", "Joysiddi"]
							    },
							    "Karimganj": {
							      "Karimganj Thana": ["Karimganj Municipality", "Dehunda", "Joyka", "Gundhar"]
							    },
							    "Katiadi": {
							      "Katiadi Thana": ["Katiadi Municipality", "Masua", "Mumurdia", "Lohajuri"]
							    },
							    "Kishoreganj Sadar": {
							      "Kishoreganj Model Thana": ["Kishoreganj Municipality", "Botrish", "Maria", "Nilganj"]
							    },
							    "Kuliarchar": {
							      "Kuliarchar Thana": ["Kuliarchar Municipality", "Faridpur", "Gobaria Abdullahpur", "Salua"]
							    },
							    "Mithamain": {
							      "Mithamain Thana": ["Mithamain Municipality", "Ghagra", "Dhaki", "Keowarjor"]
							    },
							    "Nikli": {
							      "Nikli Thana": ["Nikli Municipality", "Dampara", "Singpur", "Chatirchar"]
							    },
							    "Pakundia": {
							      "Pakundia Thana": ["Pakundia Municipality", "Burudia", "Narandi", "Hosendi"]
							    },
							    "Tarail": {
							      "Tarail Thana": ["Tarail Municipality", "Damiha", "Rauti", "Talganga"]
							    }
							  },

							  "Kurigram": {
							    "Bhurungamari": {
							      "Bhurungamari Thana": ["Bhurungamari Municipality", "Andharijhar", "Bangasonahat", "Boldia"]
							    },
							    "Char Rajibpur": {
							      "Rajibpur Thana": ["Rajibpur Municipality", "Kodalkati", "Mohanganj", "Balia Mari"]
							    },
							    "Chilmari": {
							      "Chilmari Thana": ["Chilmari Municipality", "Ashtamir Char", "Raniganj", "Ramna"]
							    },
							    "Fulbari": {
							      "Fulbari Thana": ["Fulbari Municipality", "Naodanga", "Shimulbari", "Bhangamor"]
							    },
							    "Kurigram Sadar": {
							      "Kurigram Sadar Thana": ["Kurigram Municipality", "Belgacha", "Ghorialdanga", "Holokhana"]
							    },
							    "Nageshwari": {
							      "Nageshwari Thana": ["Nageshwari Municipality", "Ballaverkhas", "Berubari", "Kachakata"]
							    },
							    "Phulbari": {
							      "Phulbari Thana": ["Phulbari Municipality", "Kashipur", "Balarhat", "Shimulbari"]
							    },
							    "Rajarhat": {
							      "Rajarhat Thana": ["Rajarhat Municipality", "Bidyananda", "Nazimkhan", "Umakhawa"]
							    },
							    "Raomari": {
							      "Raomari Thana": ["Raomari Municipality", "Jadurchar", "Saulmari", "Char Shoulmari"]
							    },
							    "Ulipur": {
							      "Ulipur Thana": ["Ulipur Municipality", "Begumganj", "Buraburi", "Durgapur"]
							    }
							  },

							  "Kushtia": {
							    "Bheramara": {
							      "Bheramara Thana": ["Bheramara Municipality", "Bahadurpur", "Mokarimpur", "Juniadah"]
							    },
							    "Daulatpur": {
							      "Daulatpur Thana": ["Daulatpur Municipality", "Adabaria", "Philipnagar", "Ramkrishnapur"]
							    },
							    "Khoksa": {
							      "Khoksa Thana": ["Khoksa Municipality", "Betbaria", "Janmara", "Osmanpur"]
							    },
							    "Kumarkhali": {
							      "Kumarkhali Thana": ["Kumarkhali Municipality", "Jagannathpur", "Panti", "Kaya"]
							    },
							    "Kushtia Sadar": {
							      "Kushtia Model Thana": ["Kushtia Municipality", "Bottail", "Baradi", "Mojompur"]
							    },
							    "Mirpur": {
							      "Mirpur Thana": ["Mirpur Municipality", "Amla", "Bahalbaria", "Poradaha"]
							    }
							  },
							  "Kurigram": {
								    "Bhurungamari": {
								      "Bhurungamari Thana": ["Bhurungamari Municipality", "Andharijhar", "Bangasonahat", "Paikerchhara"]
								    },
								    "Char Rajibpur": {
								      "Rajibpur Thana": ["Rajibpur Municipality", "Kodalkati", "Mohanganj", "Char Sajai"]
								    },
								    "Chilmari": {
								      "Chilmari Thana": ["Chilmari Municipality", "Raniganj", "Thanahat", "Ramna"]
								    },
								    "Fulbari": {
								      "Fulbari Thana": ["Fulbari Municipality", "Naodanga", "Shimulbari", "Balarhat"]
								    },
								    "Kurigram Sadar": {
								      "Kurigram Sadar Thana": ["Kurigram Municipality", "Belgacha", "Jatrapur", "Holokhana"]
								    },
								    "Nageshwari": {
								      "Nageshwari Thana": ["Nageshwari Municipality", "Ballabherkhas", "Kachakata", "Narayanpur"]
								    },
								    "Phulbari": {
								      "Phulbari Thana": ["Phulbari Municipality", "Kashipur", "Bhangamor", "Shimulbari"]
								    },
								    "Rajarhat": {
								      "Rajarhat Thana": ["Rajarhat Municipality", "Bidyananda", "Nazimkhan", "Ghorialdanga"]
								    },
								    "Raomari": {
								      "Raomari Thana": ["Raomari Municipality", "Saheber Alga", "Jadurchar", "Char Rajibpur Road"]
								    },
								    "Ulipur": {
								      "Ulipur Thana": ["Ulipur Municipality", "Buraburi", "Durgapur", "Tabakpur"]
								    }
								  },

								  "Kushtia": {
								    "Bheramara": {
								      "Bheramara Thana": ["Bheramara Municipality", "Bahadurpur", "Juniadah", "Mokarimpur"]
								    },
								    "Daulatpur": {
								      "Daulatpur Thana": ["Daulatpur Municipality", "Adabaria", "Ramkrishnapur", "Mathurapur"]
								    },
								    "Khoksa": {
								      "Khoksa Thana": ["Khoksa Municipality", "Janipur", "Betbaria", "Osmanpur"]
								    },
								    "Kumarkhali": {
								      "Kumarkhali Thana": ["Kumarkhali Municipality", "Panti", "Sadaki", "Bagulat"]
								    },
								    "Kushtia Sadar": {
								      "Kushtia Model Thana": ["Kushtia Municipality", "Amlapara", "Bottail", "Mojompur"]
								    },
								    "Mirpur": {
								      "Mirpur Thana": ["Mirpur Municipality", "Poradaha", "Ambaria", "Bahalbaria"]
								    }
								  },

								  "Lalmonirhat": {
								    "Aditmari": {
								      "Aditmari Thana": ["Aditmari Municipality", "Bhelabari", "Durgapur", "Mahishkhocha"]
								    },
								    "Hatibandha": {
								      "Hatibandha Thana": ["Hatibandha Municipality", "Goddimari", "Tongbhanga", "Sindurna"]
								    },
								    "Kaliganj": {
								      "Kaliganj Thana": ["Kaliganj Municipality", "Chandrapur", "Kakina", "Tushbhandar"]
								    },
								    "Lalmonirhat Sadar": {
								      "Lalmonirhat Sadar Thana": ["Lalmonirhat Municipality", "Mogalbasa", "Kulaghat", "Harati"]
								    },
								    "Patgram": {
								      "Patgram Thana": ["Patgram Municipality", "Burimari", "Jongra", "Baura"]
								    }
								  },

								  "Lakshmipur": {
								    "Kamalnagar": {
								      "Kamalnagar Thana": ["Kamalnagar Municipality", "Char Kadira", "Ramgati Border Area", "Char Lawrence"]
								    },
								    "Lakshmipur Sadar": {
								      "Lakshmipur Sadar Thana": ["Lakshmipur Municipality", "Chandraganj", "Dalal Bazar", "Mandari"]
								    },
								    "Raipur": {
								      "Raipur Thana": ["Raipur Municipality", "Char Abdullah", "Rakhali", "Char Mohana"]
								    },
								    "Ramganj": {
								      "Ramganj Thana": ["Ramganj Municipality", "Noagaon", "Kanchanpur", "Panpara"]
								    },
								    "Ramgati": {
								      "Ramgati Thana": ["Ramgati Municipality", "Char Alexander", "Char Poragacha", "Hatia Edge"]
								    }
								  },

								  "Madaripur": {
								    "Kalkini": {
								      "Kalkini Thana": ["Kalkini Municipality", "Sahabrampur", "Dasar", "Char Durgapur"]
								    },
								    "Madaripur Sadar": {
								      "Madaripur Sadar Thana": ["Madaripur Municipality", "Panchkhola", "Mostafapur", "Khoksha"]
								    },
								    "Rajoir": {
								      "Rajoir Thana": ["Rajoir Municipality", "Badarpasa", "Haridasdi-Mahendradi", "Isibpur"]
								    },
								    "Shibchar": {
								      "Shibchar Thana": ["Shibchar Municipality", "Kadirpur", "Sannasirchar", "Char Janajat"]
								    }
								  },
								  "Magura": {
									    "Magura Sadar": {
									      "Magura Sadar Thana": ["Magura Municipality", "Jagdal", "Berail", "Hazrapur"]
									    },
									    "Mohammadpur": {
									      "Mohammadpur Thana": ["Mohammadpur Municipality", "Babukhali", "Binodpur", "Nohata"]
									    },
									    "Shalikha": {
									      "Shalikha Thana": ["Shalikha Municipality", "Arpara", "Bunagati", "Gangarampur"]
									    },
									    "Sreepur": {
									      "Sreepur Thana": ["Sreepur Municipality", "Nakol", "Amalsar", "Kadirpara"]
									    }
									  },

									  "Manikganj": {
									    "Daulatpur": {
									      "Daulatpur Thana": ["Daulatpur Municipality", "Bachamara", "Jiongora", "Baghutia"]
									    },
									    "Ghior": {
									      "Ghior Thana": ["Ghior Municipality", "Baniajuri", "Nali", "Paila"]
									    },
									    "Harirampur": {
									      "Harirampur Thana": ["Harirampur Municipality", "Lechraganj", "Azimnagar", "Gopinathpur"]
									    },
									    "Manikganj Sadar": {
									      "Manikganj Sadar Thana": ["Manikganj Municipality", "Garpara", "Betila", "Putail"]
									    },
									    "Saturia": {
									      "Saturia Thana": ["Saturia Municipality", "Baliati", "Dighulia", "Tilli"]
									    },
									    "Shibalaya": {
									      "Shibalaya Thana": ["Shibalaya Municipality", "Aricha", "Teota", "Utholi"]
									    },
									    "Singair": {
									      "Singair Thana": ["Singair Municipality", "Joymontop", "Baldhara", "Jamirta"]
									    }
									  },

									  "Meherpur": {
									    "Gangni": {
									      "Gangni Thana": ["Gangni Municipality", "Kathuli", "Bamundi", "Motmura"]
									    },
									    "Meherpur Sadar": {
									      "Meherpur Sadar Thana": ["Meherpur Municipality", "Amjhupi", "Kutubpur", "Buripota"]
									    },
									    "Mujibnagar": {
									      "Mujibnagar Thana": ["Mujibnagar Municipality", "Monakhali", "Mahajanpur", "Bagowan"]
									    }
									  },

									  "Moulvibazar": {
									    "Barlekha": {
									      "Barlekha Thana": ["Barlekha Municipality", "Dakshin Shahbazpur", "Talimpur", "Nij Bahadurpur"]
									    },
									    "Juri": {
									      "Juri Thana": ["Juri Municipality", "Fultola", "Goaldhara", "Sagornal"]
									    },
									    "Kamalganj": {
									      "Kamalganj Thana": ["Kamalganj Municipality", "Shamshernagar", "Adampur", "Alinagar"]
									    },
									    "Kulaura": {
									      "Kulaura Thana": ["Kulaura Municipality", "Prithimpassa", "Karmadha", "Tilagaon"]
									    },
									    "Moulvibazar Sadar": {
									      "Moulvibazar Sadar Thana": ["Moulvibazar Municipality", "Akhailkura", "Khalilpur", "Mostafapur"]
									    },
									    "Rajnagar": {
									      "Rajnagar Thana": ["Rajnagar Municipality", "Tengra", "Munshibazar", "Panchgaon"]
									    },
									    "Sreemangal": {
									      "Sreemangal Thana": ["Sreemangal Municipality", "Kalighat", "Ashidron", "Sindurkhan"]
									    }
									  },

									  "Munshiganj": {
									    "Gazaria": {
									      "Gazaria Thana": ["Gazaria Municipality", "Baushia", "Bhaberchar", "Guagachia"]
									    },
									    "Lohajang": {
									      "Lohajang Thana": ["Lohajang Municipality", "Mawa", "Medinimandal", "Teotia"]
									    },
									    "Munshiganj Sadar": {
									      "Munshiganj Sadar Thana": ["Munshiganj Municipality", "Panchasar", "Rampal", "Mahakali"]
									    },
									    "Sirajdikhan": {
									      "Sirajdikhan Thana": ["Sirajdikhan Municipality", "Ichhapura", "Keyain", "Basail"]
									    },
									    "Sreenagar": {
									      "Sreenagar Thana": ["Sreenagar Municipality", "Hasara", "Atpara", "Bhagyakul"]
									    },
									    "Tongibari": {
									      "Tongibari Thana": ["Tongibari Municipality", "Abdullapur", "Betka", "Sonarang"]
									    }
									  },"Barishal": {
										    "Agailjhara": {
										        "Agailjhara Thana": ["Agailjhara Municipality", "Bagdha", "Rajihar", "Gaila"]
										      },
										      "Babuganj": {
										        "Babuganj Thana": ["Babuganj Municipality", "Rahmatpur", "Chandpasha", "Madhabpasha"]
										      },
										      "Bakerganj": {
										        "Bakerganj Thana": ["Bakerganj Municipality", "Charadi", "Kolaskathi", "Nalua"]
										      },
										      "Banaripara": {
										        "Banaripara Thana": ["Banaripara Municipality", "Chakhar", "Uzirpur Road", "Baisari"]
										      },
										      "Barishal Sadar": {
										        "Kotwali Model Thana": ["Barishal City Corporation", "Rupatali", "Kashipur", "Nathullabad"]
										      },
										      "Gournadi": {
										        "Gournadi Thana": ["Gournadi Municipality", "Mahilara", "Batajor", "Sarikal"]
										      },
										      "Hizla": {
										        "Hizla Thana": ["Hizla Municipality", "Memania", "Harinathpur", "Guabaria"]
										      },
										      "Mehendiganj": {
										        "Mehendiganj Thana": ["Mehendiganj Municipality", "Gobindapur", "Lata", "Ulania"]
										      },
										      "Muladi": {
										        "Muladi Thana": ["Muladi Municipality", "Nazirpur", "Kazirchar", "Char Kalekhan"]
										      },
										      "Wazirpur": {
										        "Wazirpur Thana": ["Wazirpur Municipality", "Sholak", "Bamrail", "Jalla"]
										      }
										    },

										    "Bhola": {
										      "Bhola Sadar": {
										        "Bhola Sadar Thana": ["Bhola Municipality", "Rajapur", "Ilisha", "Dighaldi"]
										      },
										      "Borhanuddin": {
										        "Borhanuddin Thana": ["Borhanuddin Municipality", "Kachia", "Sachra", "Deula"]
										      },
										      "Char Fasson": {
										        "Char Fasson Thana": ["Char Fasson Municipality", "Nazirpur", "Aslampur", "Aminabad"]
										      },
										      "Daulatkhan": {
										        "Daulatkhan Thana": ["Daulatkhan Municipality", "Madanpur", "Hajipur", "Charpata"]
										      },
										      "Lalmohan": {
										        "Lalmohan Thana": ["Lalmohan Municipality", "Badarpur", "Dholigournagar", "Kalma"]
										      },
										      "Manpura": {
										        "Manpura Thana": ["Manpura Municipality", "Hazirhat", "South Sakuchia", "Uttar Sakuchia"]
										      },
										      "Tazumuddin": {
										        "Tazumuddin Thana": ["Tazumuddin Municipality", "Chanchra", "Shambhupur", "Sonapur"]
										      }
										    },

										    "Jhalokathi": {
										      "Jhalokathi Sadar": {
										        "Jhalokathi Thana": ["Jhalokathi Municipality", "Basanda", "Gabkhan", "Kirtipasha"]
										      },
										      "Kathalia": {
										        "Kathalia Thana": ["Kathalia Municipality", "Amua", "Shouljalia", "Patikhalghata"]
										      },
										      "Nalchity": {
										        "Nalchity Thana": ["Nalchity Municipality", "Subidpur", "Kushangal", "Mollarhat"]
										      },
										      "Rajapur": {
										        "Rajapur Thana": ["Rajapur Municipality", "Bhairabpasha", "Galua", "Saturia"]
										      }
										    },

										    "Patuakhali": {
										      "Bauphal": {
										        "Bauphal Thana": ["Bauphal Municipality", "Kalaiya", "Daspara", "Najirpur"]
										      },
										      "Dashmina": {
										        "Dashmina Thana": ["Dashmina Municipality", "Rangopaldi", "Baharampur", "Alipur"]
										      },
										      "Dumki": {
										        "Dumki Thana": ["Dumki Municipality", "Muradia", "Labukhali", "Auliapur"]
										      },
										      "Galachipa": {
										        "Galachipa Thana": ["Galachipa Municipality", "Chiknikandi", "Gazalia", "Char Biswas"]
										      },
										      "Kalapara": {
										        "Kalapara Thana": ["Kalapara Municipality", "Kuakata", "Lalua", "Mithaganj"]
										      },
										      "Mirzaganj": {
										        "Mirzaganj Thana": ["Mirzaganj Municipality", "Amragachhia", "Rangabali Border Area", "Majidpur"]
										      },
										      "Patuakhali Sadar": {
										        "Patuakhali Sadar Thana": ["Patuakhali Municipality", "Itbaria", "Auliapur", "Bauphal Road Area"]
										      },
										      "Rangabali": {
										        "Rangabali Thana": ["Rangabali Municipality", "Char Montaz", "Choto Baishdia", "Galachipa Edge"]
										      }
										    },

										    "Pirojpur": {
										      "Bhandaria": {
										        "Bhandaria Thana": ["Bhandaria Municipality", "Telikhali", "Dhaoa", "Nesarabad Border Area"]
										      },
										      "Indurkani": {
										        "Indurkani Thana": ["Indurkani Municipality", "Patakata", "Balipara", "Zianagar"]
										      },
										      "Kawkhali": {
										        "Kawkhali Thana": ["Kawkhali Municipality", "Amua", "Sayna Raghunathpur", "Nesarabad Edge"]
										      },
										      "Mathbaria": {
										        "Mathbaria Thana": ["Mathbaria Municipality", "Tikikata", "Tushkhali", "Gulishakhali"]
										      },
										      "Nazirpur": {
										        "Nazirpur Thana": ["Nazirpur Municipality", "Shakharikathi", "Dumuria", "Kawkhali Border Area"]
										      },
										      "Nesarabad": {
										        "Nesarabad Thana": ["Nesarabad Municipality", "Swarupkathi", "Chandipur", "Dumuria Road Area"]
										      },
										      "Pirojpur Sadar": {
										        "Pirojpur Sadar Thana": ["Pirojpur Municipality", "Kawkhali Road Area", "Parerhat", "Sankarpasha"]
										      }
										    },
										    "Barguna": {
										        "Amtali": {
										          "Amtali Thana": ["Amtali Municipality", "Arpangasia", "Atharagasia", "Chawra"]
										        },
										        "Bamna": {
										          "Bamna Thana": ["Bamna Municipality", "Ramna", "Bukabunia", "Doutola"]
										        },
										        "Barguna Sadar": {
										          "Barguna Sadar Thana": ["Barguna Municipality", "Burirchar", "Ayla Patakata", "Fuljhuri"]
										        },
										        "Betagi": {
										          "Betagi Thana": ["Betagi Municipality", "Hosnabad", "Mokamia", "Kazirabad"]
										        },
										        "Patharghata": {
										          "Patharghata Thana": ["Patharghata Municipality", "Kalmegha", "Kakchira", "Nachnapara"]
										        },
										        "Taltali": {
										          "Taltali Thana": ["Taltali Municipality", "Barabagi", "Pancha Koralia", "Nishanbaria"]
										        }
										      },

										      "Bandarban": {
										        "Alikadam": {
										          "Alikadam Thana": ["Alikadam Municipality", "Kurukpatta", "Chokhyong", "Matamuhuri"]
										        },
										        "Bandarban Sadar": {
										          "Bandarban Sadar Thana": ["Bandarban Municipality", "Balaghata", "Rajbila", "Sualok"]
										        },
										        "Lama": {
										          "Lama Thana": ["Lama Municipality", "Fasiakhali", "Aziznagar", "Sarai"]
										        },
										        "Naikhongchhari": {
										          "Naikhongchhari Thana": ["Naikhongchhari Municipality", "Dochhari", "Ghumdhum", "Baishari"]
										        },
										        "Rowangchhari": {
										          "Rowangchhari Thana": ["Rowangchhari Municipality", "Taracha", "Alikhong", "Kaptala"]
										        },
										        "Ruma": {
										          "Ruma Thana": ["Ruma Municipality", "Galenga", "Paindu", "Remakri"]
										        },
										        "Thanchi": {
										          "Thanchi Thana": ["Thanchi Municipality", "Tindu", "Remakri", "Bolitong"]
										        }
										      },

										      "Brahmanbaria": {
										        "Akhaura": {
										          "Akhaura Thana": ["Akhaura Municipality", "Mogra", "Monionda", "Gangasagar"]
										        },
										        "Ashuganj": {
										          "Ashuganj Thana": ["Ashuganj Municipality", "Durgapur", "Char Chartala", "Lalpur"]
										        },
										        "Bancharampur": {
										          "Bancharampur Thana": ["Bancharampur Municipality", "Ayubpur", "Rupasdi", "Salimabad"]
										        },
										        "Bijoynagar": {
										          "Bijoynagar Thana": ["Bijoynagar Municipality", "Pattan", "Singerbil", "Islampur"]
										        },
										        "Brahmanbaria Sadar": {
										          "Brahmanbaria Sadar Thana": ["Brahmanbaria Municipality", "Medda", "Machihata", "Sultanpur"]
										        },
										        "Kasba": {
										          "Kasba Thana": ["Kasba Municipality", "Kuti", "Bayek", "Mulgram"]
										        },
										        "Nabinagar": {
										          "Nabinagar Thana": ["Nabinagar Municipality", "Bitghar", "Krishnanagar", "Shibpur"]
										        },
										        "Nasirnagar": {
										          "Nasirnagar Thana": ["Nasirnagar Municipality", "Haripur", "Gokarna", "Burishwar"]
										        },
										        "Sarail": {
										          "Sarail Thana": ["Sarail Municipality", "Shahbazpur", "Noagaon", "Pakshimul"]
										        }
										      },

										      "Chandpur": {
										        "Chandpur Sadar": {
										          "Chandpur Model Thana": ["Chandpur Municipality", "Bishnupur", "Rajnagar", "Baburhat"]
										        },
										        "Faridganj": {
										          "Faridganj Thana": ["Faridganj Municipality", "Gobindapur", "Rupsha", "Balithuba"]
										        },
										        "Haimchar": {
										          "Haimchar Thana": ["Haimchar Municipality", "Gazipur", "Nilkamal", "Char Bhairabi"]
										        },
										        "Haziganj": {
										          "Haziganj Thana": ["Haziganj Municipality", "Barkul", "Hatila", "Kalatia"]
										        },
										        "Kachua": {
										          "Kachua Thana": ["Kachua Municipality", "Bitara", "Palakhali", "Ashrafpur"]
										        },
										        "Matlab Dakshin": {
										          "Matlab South Thana": ["Matlab Municipality", "Narayanpur", "Nayergaon", "Upadi"]
										        },
										        "Matlab Uttar": {
										          "Matlab North Thana": ["Matlab Uttar Municipality", "Mohanpur", "Satnal", "Sultanabad"]
										        },
										        "Shahrasti": {
										          "Shahrasti Thana": ["Shahrasti Municipality", "Suchipara", "Tamta", "Rayashree"]
										        }
										      },

										      "Chattogram": {
										        "Anwara": {
										          "Anwara Thana": ["Anwara Municipality", "Barkal", "Chaturi", "Bairag Union Area"]
										        },
										        "Banshkhali": {
										          "Banshkhali Thana": ["Banshkhali Municipality", "Baharchara", "Sadhanpur", "Katharia"]
										        },
										        "Boalkhali": {
										          "Boalkhali Thana": ["Boalkhali Municipality", "Kadhurkhil", "Saroatoli", "Popadia"]
										        },
										        "Chandanaish": {
										          "Chandanaish Thana": ["Chandanaish Municipality", "Satbaria", "Bailtali", "Dhopachhari"]
										        },
										        "Fatikchhari": {
										          "Fatikchhari Thana": ["Fatikchhari Municipality", "Nanupur", "Harualchhari", "Bhujpur"]
										        },
										        "Hathazari": {
										          "Hathazari Thana": ["Hathazari Municipality", "Fatehpur", "Madrasha Area", "Dewanpur"]
										        },
										        "Karnaphuli": {
										          "Karnaphuli Thana": ["Karnaphuli Municipality", "Kalurghat", "Anandabazar", "Patenga Road Area"]
										        },
										        "Lohagara": {
										          "Lohagara Thana": ["Lohagara Municipality", "Padua", "Adhunagar", "Barahatia"]
										        },
										        "Mirsharai": {
										          "Mirsharai Thana": ["Mirsharai Municipality", "Baroiarhat", "Katachhara", "Dhum"]
										        },
										        "Patiya": {
										          "Patiya Thana": ["Patiya Municipality", "Kachuai", "Bara Uthan", "Habilasdwip"]
										        },
										        "Rangunia": {
										          "Rangunia Thana": ["Rangunia Municipality", "Kodala", "Pomara", "Betagi"]
										        },
										        "Raozan": {
										          "Raozan Thana": ["Raozan Municipality", "Kundeshwari", "Bagoan", "Noapara"]
										        },
										        "Sandwip": {
										          "Sandwip Thana": ["Sandwip Municipality", "Urirchar", "Harishpur", "Gazipur"]
										        },
										        "Satkania": {
										          "Satkania Thana": ["Satkania Municipality", "Amirabad", "Bazalia", "Kaliais"]
										        },
										        "Sitakunda": {
										          "Sitakunda Thana": ["Sitakunda Municipality", "Barabkunda", "Muradpur", "Banshbaria"]
										        }
										      },
										      "Cox's Bazar": {
										    	    "Chakaria": {
										    	      "Chakaria Thana": ["Chakaria Municipality", "Harbang", "Dulahazara", "Bamubill"]
										    	    },
										    	    "Cox's Bazar Sadar": {
										    	      "Cox's Bazar Model Thana": ["Cox's Bazar Municipality", "Kolatoli", "Jhilongja", "Khurushkul"]
										    	    },
										    	    "Kutubdia": {
										    	      "Kutubdia Thana": ["Kutubdia Municipality", "Ali Akbar Dail", "North Dhurung", "Baraghop"]
										    	    },
										    	    "Maheshkhali": {
										    	      "Maheshkhali Thana": ["Maheshkhali Municipality", "Gorakghata", "Kalarmarchhara", "Hoanak"]
										    	    },
										    	    "Pekua": {
										    	      "Pekua Thana": ["Pekua Municipality", "Magnama", "Rajakhali", "Toitong"]
										    	    },
										    	    "Ramu": {
										    	      "Ramu Thana": ["Ramu Municipality", "Joarianala", "Khuniapalong", "Fatekharkul"]
										    	    },
										    	    "Teknaf": {
										    	      "Teknaf Model Thana": ["Teknaf Municipality", "Shah Porir Dwip", "Hnila", "Sabrang"]
										    	    },
										    	    "Ukhia": {
										    	      "Ukhia Thana": ["Ukhia Municipality", "Kutupalong", "Palongkhali", "Raja Palong"]
										    	    }
										    	  },

										    	  "Cumilla": {
										    	    "Barura": {
										    	      "Barura Thana": ["Barura Municipality", "Adra", "Poyalgachha", "Galimpur"]
										    	    },
										    	    "Brahmanpara": {
										    	      "Brahmanpara Thana": ["Brahmanpara Municipality", "Shashidal", "Malapara", "Mokam"]
										    	    },
										    	    "Burichang": {
										    	      "Burichang Thana": ["Burichang Municipality", "Bakshimul", "Mainamati", "Mokam"]
										    	    },
										    	    "Chandina": {
										    	      "Chandina Thana": ["Chandina Municipality", "Madhaiya", "Madhabpur", "Joag"]
										    	    },
										    	    "Chauddagram": {
										    	      "Chauddagram Thana": ["Chauddagram Municipality", "Gunabati", "Batisa", "Bijoykar"]
										    	    },
										    	    "Cumilla Adarsha Sadar": {
										    	      "Kotwali Model Thana": ["Cumilla City Corporation", "Kandirpar", "Shashongacha", "Tomsom Bridge"]
										    	    },
										    	    "Cumilla Sadar Dakshin": {
										    	      "Sadar Dakshin Thana": ["Paduar Bazar", "Bijoypur", "Barapara", "Suagazi"]
										    	    },
										    	    "Daudkandi": {
										    	      "Daudkandi Model Thana": ["Daudkandi Municipality", "Eliotganj", "Gouripur", "Jinglatoli"]
										    	    },
										    	    "Debidwar": {
										    	      "Debidwar Thana": ["Debidwar Municipality", "Fatehabad", "Barashalghar", "Dhamti"]
										    	    },
										    	    "Homna": {
										    	      "Homna Thana": ["Homna Municipality", "Asadpur", "Nilokhi", "Mathabhanga"]
										    	    },
										    	    "Laksam": {
										    	      "Laksam Thana": ["Laksam Municipality", "Mudaffarganj", "Kalikapur", "Bipulasar"]
										    	    },
										    	    "Meghna": {
										    	      "Meghna Thana": ["Meghna Municipality", "Chalivanga", "Manikar Char", "Gobindapur"]
										    	    },
										    	    "Monoharganj": {
										    	      "Monoharganj Thana": ["Monoharganj Municipality", "Hasnabad", "Bipulasar", "Lakshmanpur"]
										    	    },
										    	    "Muradnagar": {
										    	      "Muradnagar Thana": ["Muradnagar Municipality", "Ramchandrapur", "Bangra", "Jahapur"]
										    	    },
										    	    "Nangalkot": {
										    	      "Nangalkot Thana": ["Nangalkot Municipality", "Dhalua", "Adra", "Mokara"]
										    	    },
										    	    "Titas": {
										    	      "Titas Thana": ["Titas Municipality", "Jagatpur", "Majidpur", "Narandia"]
										    	    }
										    	  },

										    	  "Feni": {
										    	    "Chhagalnaiya": {
										    	      "Chhagalnaiya Thana": ["Chhagalnaiya Municipality", "Maharajganj", "Radhanagar", "Pathannagar"]
										    	    },
										    	    "Daganbhuiyan": {
										    	      "Daganbhuiyan Thana": ["Daganbhuiyan Municipality", "Matubhuiyan", "Rajapur", "Sindurpur"]
										    	    },
										    	    "Feni Sadar": {
										    	      "Feni Model Thana": ["Feni Municipality", "Lemua", "Baligaon", "Kazirbag"]
										    	    },
										    	    "Fulgazi": {
										    	      "Fulgazi Thana": ["Fulgazi Municipality", "Munshirhat", "Anandapur", "Amzadhat"]
										    	    },
										    	    "Parshuram": {
										    	      "Parshuram Thana": ["Parshuram Municipality", "Chitholia", "Mirzanagar", "Boxmahmud"]
										    	    },
										    	    "Sonagazi": {
										    	      "Sonagazi Thana": ["Sonagazi Municipality", "Char Chandia", "Motiganj", "Amirabad"]
										    	    }
										    	  },

										    	  "Khagrachhari": {
										    	    "Dighinala": {
										    	      "Dighinala Thana": ["Dighinala Municipality", "Babuchhara", "Boalkhali", "Merung"]
										    	    },
										    	    "Guimara": {
										    	      "Guimara Thana": ["Guimara Municipality", "Hafchhari", "Sindukchhari", "Kalapani"]
										    	    },
										    	    "Khagrachhari Sadar": {
										    	      "Khagrachhari Sadar Thana": ["Khagrachhari Municipality", "Perachhara", "Golabari", "Shalbon"]
										    	    },
										    	    "Lakshmichhari": {
										    	      "Lakshmichhari Thana": ["Lakshmichhari Municipality", "Dulyatali", "Barmachhari", "Shantipur"]
										    	    },
										    	    "Mahalchhari": {
										    	      "Mahalchhari Thana": ["Mahalchhari Municipality", "Mobachhari", "Sindukchhari", "Maischhari"]
										    	    },
										    	    "Manikchhari": {
										    	      "Manikchhari Thana": ["Manikchhari Municipality", "Batnatali", "Tintahari", "Jogendranagar"]
										    	    },
										    	    "Matiranga": {
										    	      "Matiranga Thana": ["Matiranga Municipality", "Belchhari", "Tubalchhari", "Taindong"]
										    	    },
										    	    "Panchhari": {
										    	      "Panchhari Thana": ["Panchhari Municipality", "Latiban", "Logang", "Ultachhari"]
										    	    },
										    	    "Ramgarh": {
										    	      "Ramgarh Thana": ["Ramgarh Municipality", "Patachhara", "Hafchhari", "Taindong Road"]
										    	    }
										    	  },

										    	  "Lakshmipur": {
										    	    "Kamalnagar": {
										    	      "Kamalnagar Thana": ["Kamalnagar Municipality", "Char Kadira", "Ramgati Border Area", "Char Lawrence"]
										    	    },
										    	    "Lakshmipur Sadar": {
										    	      "Lakshmipur Sadar Thana": ["Lakshmipur Municipality", "Chandraganj", "Dalal Bazar", "Mandari"]
										    	    },
										    	    "Raipur": {
										    	      "Raipur Thana": ["Raipur Municipality", "Char Abdullah", "Rakhali", "Char Mohana"]
										    	    },
										    	    "Ramganj": {
										    	      "Ramganj Thana": ["Ramganj Municipality", "Noagaon", "Kanchanpur", "Panpara"]
										    	    },
										    	    "Ramgati": {
										    	      "Ramgati Thana": ["Ramgati Municipality", "Char Alexander", "Char Poragacha", "Hatia Edge"]
										    	    }
										    	  },
										    	  "Natore": {
										    		    "Bagatipara": {
										    		      "Bagatipara Thana": ["Bagatipara Municipality", "Dayarampur", "Faguardiar", "Panka"]
										    		    },
										    		    "Baraigram": {
										    		      "Baraigram Thana": ["Baraigram Municipality", "Gurudaspur Border Area", "Chandai", "Harua"]
										    		    },
										    		    "Gurudaspur": {
										    		      "Gurudaspur Thana": ["Gurudaspur Municipality", "Moshindha", "Biaghat", "Chanchkoir"]
										    		    },
										    		    "Lalpur": {
										    		      "Lalpur Thana": ["Lalpur Municipality", "Arbab", "Kadimchilan", "Islampur"]
										    		    },
										    		    "Naldanga": {
										    		      "Naldanga Thana": ["Naldanga Municipality", "Khajura", "Bilmaria", "Radhanagar"]
										    		    },
										    		    "Natore Sadar": {
										    		      "Natore Sadar Thana": ["Natore Municipality", "Kanaikhali", "Harishpur", "Bipra Belgharia"]
										    		    },
										    		    "Singra": {
										    		      "Singra Thana": ["Singra Municipality", "Chamari", "Chaugram", "Hatil"]
										    		    }
										    		  },

										    		  "Netrokona": {
										    		    "Atpara": {
										    		      "Atpara Thana": ["Atpara Municipality", "Durgapur Border Area", "Baniajan", "Chandipasha"]
										    		    },
										    		    "Barhatta": {
										    		      "Barhatta Thana": ["Barhatta Municipality", "Raypur", "Khaliajuri Border Area", "Singdha"]
										    		    },
										    		    "Durgapur": {
										    		      "Durgapur Thana": ["Durgapur Municipality", "Birishiri", "Chandigarh", "Shibganj"]
										    		    },
										    		    "Khaliajuri": {
										    		      "Khaliajuri Thana": ["Khaliajuri Municipality", "Haoar Belt", "Modonpur", "Agla"]
										    		    },
										    		    "Kalmakanda": {
										    		      "Kalmakanda Thana": ["Kalmakanda Municipality", "Lengura", "Pogla", "Dhala"]
										    		    },
										    		    "Kendua": {
										    		      "Kendua Thana": ["Kendua Municipality", "Ashujia", "Shormoshpur", "Goraduba"]
										    		    },
										    		    "Madan": {
										    		      "Madan Thana": ["Madan Municipality", "Gobindasree", "Teligati", "Nayekpur"]
										    		    },
										    		    "Mohanganj": {
										    		      "Mohanganj Thana": ["Mohanganj Municipality", "Birampur", "Gaglajur", "Maghan"]
										    		    },
										    		    "Netrokona Sadar": {
										    		      "Netrokona Sadar Thana": ["Netrokona Municipality", "Kendua Road Area", "Kaliara Gabragati", "Choto Bazar"]
										    		    },
										    		    "Purbadhala": {
										    		      "Purbadhala Thana": ["Purbadhala Municipality", "Jaria", "Agia", "Narayanpur"]
										    		    }
										    		  },

										    		  "Nilphamari": {
										    		    "Dimla": {
										    		      "Dimla Thana": ["Dimla Municipality", "Chapanirhat", "Nageshwari Border Area", "Teesta River Belt"]
										    		    },
										    		    "Domar": {
										    		      "Domar Thana": ["Domar Municipality", "Sonaray", "Boragari", "Bhogdabri"]
										    		    },
										    		    "Jaldhaka": {
										    		      "Jaldhaka Thana": ["Jaldhaka Municipality", "Mirganj", "Khutamara", "Golna"]
										    		    },
										    		    "Kishoreganj": {
										    		      "Kishoreganj Thana": ["Kishoreganj Municipality", "Barabhita", "Chandkhana", "Magura"]
										    		    },
										    		    "Nilphamari Sadar": {
										    		      "Nilphamari Sadar Thana": ["Nilphamari Municipality", "Kishoreganj Road Area", "Sangalshi", "Itakhola"]
										    		    },
										    		    "Saidpur": {
										    		      "Saidpur Thana": ["Saidpur Municipality", "Airport Area", "Kamar Pukur", "Lakshmanpur"]
										    		    }
										    		  },

										    		  "Noakhali": {
										    		    "Begumganj": {
										    		      "Begumganj Thana": ["Chowmuhani Municipality", "Rasulpur", "Mirwarishpur", "Chhatarpaia"]
										    		    },
										    		    "Chatkhil": {
										    		      "Chatkhil Thana": ["Chatkhil Municipality", "Shoshidal", "Karihati", "Panchgaon"]
										    		    },
										    		    "Companiganj": {
										    		      "Companiganj Thana": ["Companiganj Municipality", "Bashurhat", "Char Elahi", "Char Fakira"]
										    		    },
										    		    "Hatiya": {
										    		      "Hatiya Thana": ["Hatiya Municipality", "Nijhum Dwip", "Char Ishwar", "Sukhchar"]
										    		    },
										    		    "Kabirhat": {
										    		      "Kabirhat Thana": ["Kabirhat Municipality", "Sundalpur", "Dosh Ghoria", "Nodona"]
										    		    },
										    		    "Noakhali Sadar": {
										    		      "Noakhali Sadar Thana": ["Maijdee Court", "Chowrasta", "Kadir Hanif", "Sonapur"]
										    		    },
										    		    "Senbagh": {
										    		      "Senbagh Thana": ["Senbagh Municipality", "Kabilpur", "Bijbagh", "Duttapara"]
										    		    },
										    		    "Subarnachar": {
										    		      "Subarnachar Thana": ["Char Jabbar", "Char Bata", "Char Amanullah", "Char Jubilee"]
										    		    }
										    		  },

										    		  "Pabna": {
										    		    "Atgharia": {
										    		      "Atgharia Thana": ["Atgharia Municipality", "Brahmangram", "Chandba", "Debottar"]
										    		    },
										    		    "Bera": {
										    		      "Bera Thana": ["Bera Municipality", "Kashinathpur", "Nakalia", "Dhalarchar"]
										    		    },
										    		    "Bhangura": {
										    		      "Bhangura Thana": ["Bhangura Municipality", "Astomonisha", "Dilpasar", "Parbhangura"]
										    		    },
										    		    "Chatmohar": {
										    		      "Chatmohar Thana": ["Chatmohar Municipality", "Mulgram", "Handial", "Bilchalan"]
										    		    },
										    		    "Faridpur": {
										    		      "Faridpur Thana": ["Faridpur Municipality", "Banwarinagar Border Area", "Belkuchi Road Area", "Char Gautia"]
										    		    },
										    		    "Ishwardi": {
										    		      "Ishwardi Thana": ["Ishwardi Municipality", "Pakshi", "Rooppur", "Dashuria"]
										    		    },
										    		    "Pabna Sadar": {
										    		      "Pabna Sadar Thana": ["Pabna Municipality", "Hemayetpur", "Kalachandpara", "Malanchi"]
										    		    },
										    		    "Santhia": {
										    		      "Santhia Thana": ["Santhia Municipality", "Bhangura Border Area", "Dhopadaha", "Kashinarayanpur"]
										    		    },
										    		    "Sujanagar": {
										    		      "Sujanagar Thana": ["Sujanagar Municipality", "Ahammadpur", "Nagarbari", "Satbaria"]
										    		    }
										    		  },
										    		  "Panchagarh": {
										    			    "Atwari": {
										    			      "Atwari Thana": ["Atwari Municipality", "Balarampur", "Mirzapur", "Tetulia Border Area"]
										    			    },
										    			    "Boda": {
										    			      "Boda Thana": ["Boda Municipality", "Maidandighi", "Chandanbari", "Sakoa"]
										    			    },
										    			    "Debiganj": {
										    			      "Debiganj Thana": ["Debiganj Municipality", "Dandopal", "Shaldanga", "Pamuli"]
										    			    },
										    			    "Panchagarh Sadar": {
										    			      "Panchagarh Sadar Thana": ["Panchagarh Municipality", "Hafizabad", "Amarkhana", "Satmara"]
										    			    },
										    			    "Tetulia": {
										    			      "Tetulia Thana": ["Tetulia Municipality", "Banglabandha Land Port Area", "Buraburi", "Shalbahan"]
										    			    }
										    			  },

										    			  "Patuakhali": {
										    			    "Bauphal": {
										    			      "Bauphal Thana": ["Bauphal Municipality", "Kalaiya", "Daspara", "Najirpur"]
										    			    },
										    			    "Dashmina": {
										    			      "Dashmina Thana": ["Dashmina Municipality", "Rangopaldi", "Baharampur", "Alipur"]
										    			    },
										    			    "Dumki": {
										    			      "Dumki Thana": ["Dumki Municipality", "Muradia", "Labukhali", "Auliapur"]
										    			    },
										    			    "Galachipa": {
										    			      "Galachipa Thana": ["Galachipa Municipality", "Chiknikandi", "Gazalia", "Char Biswas"]
										    			    },
										    			    "Kalapara": {
										    			      "Kalapara Thana": ["Kalapara Municipality", "Kuakata", "Lalua", "Mithaganj"]
										    			    },
										    			    "Mirzaganj": {
										    			      "Mirzaganj Thana": ["Mirzaganj Municipality", "Amragachhia", "Rangabali Border Area", "Majidpur"]
										    			    },
										    			    "Patuakhali Sadar": {
										    			      "Patuakhali Sadar Thana": ["Patuakhali Municipality", "Itbaria", "Auliapur", "Baufal Road Area"]
										    			    },
										    			    "Rangabali": {
										    			      "Rangabali Thana": ["Rangabali Municipality", "Char Montaz", "Choto Baishdia", "Galachipa Edge"]
										    			    }
										    			  },

										    			  "Pirojpur": {
										    			    "Bhandaria": {
										    			      "Bhandaria Thana": ["Bhandaria Municipality", "Telikhali", "Dhaoa", "Nesarabad Border Area"]
										    			    },
										    			    "Indurkani": {
										    			      "Indurkani Thana": ["Indurkani Municipality", "Patakata", "Balipara", "Zianagar"]
										    			    },
										    			    "Kawkhali": {
										    			      "Kawkhali Thana": ["Kawkhali Municipality", "Amua", "Sayna Raghunathpur", "Nesarabad Edge"]
										    			    },
										    			    "Mathbaria": {
										    			      "Mathbaria Thana": ["Mathbaria Municipality", "Tikikata", "Tushkhali", "Gulishakhali"]
										    			    },
										    			    "Nazirpur": {
										    			      "Nazirpur Thana": ["Nazirpur Municipality", "Shakharikathi", "Dumuria", "Kawkhali Border Area"]
										    			    },
										    			    "Nesarabad": {
										    			      "Nesarabad Thana": ["Nesarabad Municipality", "Swarupkathi", "Chandipur", "Dumuria Road Area"]
										    			    },
										    			    "Pirojpur Sadar": {
										    			      "Pirojpur Sadar Thana": ["Pirojpur Municipality", "Kawkhali Road Area", "Parerhat", "Sankarpasha"]
										    			    }
										    			  },

										    			  "Rajbari": {
										    			    "Baliakandi": {
										    			      "Baliakandi Thana": ["Baliakandi Municipality", "Jamalpur", "Narua", "Sonapur"]
										    			    },
										    			    "Goalandaghat": {
										    			      "Goalandaghat Thana": ["Goalandaghat Municipality", "Choto Bhakla", "Debgram", "Rajbari River Port Area"]
										    			    },
										    			    "Kalukhali": {
										    			      "Kalukhali Thana": ["Kalukhali Municipality", "Ratandia", "Mrigi", "Boalia"]
										    			    },
										    			    "Pangsha": {
										    			      "Pangsha Thana": ["Pangsha Municipality", "Jashai", "Habashpur", "Ramkol"]
										    			    },
										    			    "Rajbari Sadar": {
										    			      "Rajbari Sadar Thana": ["Rajbari Municipality", "Alipur", "Mizanpur", "Goalanda Road Area"]
										    			    }
										    			  },

										    			  "Rangamati": {
										    			    "Baghaichhari": {
										    			      "Baghaichhari Thana": ["Baghaichhari Municipality", "Marishya", "Kedarmara", "Dighinala Border Area"]
										    			    },
										    			    "Barkal": {
										    			      "Barkal Thana": ["Barkal Municipality", "Bilaichhari Edge", "Subalong", "Chandraghona Area"]
										    			    },
										    			    "Belaichhari": {
										    			      "Belaichhari Thana": ["Belaichhari Municipality", "Farua", "Jurachhari Border Area", "Remote Hill Area"]
										    			    },
										    			    "Juraichhari": {
										    			      "Juraichhari Thana": ["Juraichhari Municipality", "Rajasthali Border Area", "Dumdumya", "Hill Track Zone"]
										    			    },
										    			    "Kaptai": {
										    			      "Kaptai Thana": ["Kaptai Municipality", "Kaptai Lake Area", "Chandraghona", "Chitmoram"]
										    			    },
										    			    "Kawkhali": {
										    			      "Kawkhali Thana": ["Kawkhali Municipality", "Betbunia", "Belaichhari Edge", "Rangamati Sadar Road Area"]
										    			    },
										    			    "Langadu": {
										    			      "Langadu Thana": ["Langadu Municipality", "Ghagra", "Bilaschhari", "Remote Hill Area"]
										    			    },
										    			    "Naniarchar": {
										    			      "Naniarchar Thana": ["Naniarchar Municipality", "Burighat", "Sabekhyong", "Hill Border Area"]
										    			    },
										    			    "Rangamati Sadar": {
										    			      "Rangamati Sadar Thana": ["Rangamati Municipality", "Reserve Bazar", "Tabalchhari", "Kaptai Road Zone"]
										    			    }
										    			  },
										    			  "Rangpur": {
										    				    "Badarganj": {
										    				      "Badarganj Thana": ["Badarganj Municipality", "Radhanagar", "Shyampur", "Lohani"]
										    				    },
										    				    "Gangachara": {
										    				      "Gangachara Thana": ["Gangachara Municipality", "Kolkond", "Mornia", "Alambiditor"]
										    				    },
										    				    "Kaunia": {
										    				      "Kaunia Thana": ["Kaunia Municipality", "Haragachh", "Shahidbagh", "Sarai"]
										    				    },
										    				    "Mithapukur": {
										    				      "Mithapukur Thana": ["Mithapukur Municipality", "Ranipukur", "Pairaband", "Gopalpur"]
										    				    },
										    				    "Pirgachha": {
										    				      "Pirgachha Thana": ["Pirgachha Municipality", "Tambulpur", "Kumedpur", "Itakumari"]
										    				    },
										    				    "Pirganj": {
										    				      "Pirganj Thana": ["Pirganj Municipality", "Madarganj", "Kumedpur Road Area", "Chatra"]
										    				    },
										    				    "Rangpur Sadar": {
										    				      "Rangpur Sadar Thana": ["Rangpur City Corporation", "Cantonment Area", "Kellaband", "Alamnagar"]
										    				    },
										    				    "Taraganj": {
										    				      "Taraganj Thana": ["Taraganj Municipality", "Alampur", "Bhelabari", "Chandipur"]
										    				    }
										    				  },

										    				  "Satkhira": {
										    				    "Assasuni": {
										    				      "Assasuni Thana": ["Assasuni Municipality", "Kadamtala", "Pratapnagar", "Baradal"]
										    				    },
										    				    "Debhata": {
										    				      "Debhata Thana": ["Debhata Municipality", "Sakhipur", "Kulia", "Noapara"]
										    				    },
										    				    "Kalaroa": {
										    				      "Kalaroa Thana": ["Kalaroa Municipality", "Joynagar", "Keragachhi", "Chandanpur"]
										    				    },
										    				    "Kaliganj": {
										    				      "Kaliganj Thana": ["Kaliganj Municipality", "Bishnupur", "Nalta", "Ramnagar"]
										    				    },
										    				    "Satkhira Sadar": {
										    				      "Satkhira Sadar Thana": ["Satkhira Municipality", "Binerpota", "Bhomra Land Port Area", "Labsa"]
										    				    },
										    				    "Shyamnagar": {
										    				      "Shyamnagar Thana": ["Shyamnagar Municipality", "Burigoalini", "Koyra Border Area", "Munshiganj"]
										    				    },
										    				    "Tala": {
										    				      "Tala Thana": ["Tala Municipality", "Jalalpur", "Patkelghata", "Kashimari"]
										    				    }
										    				  },

										    				  "Shariatpur": {
										    				    "Bhedarganj": {
										    				      "Bhedarganj Thana": ["Bhedarganj Municipality", "Char Bhaga", "Arshi Nagar", "Rupapat"]
										    				    },
										    				    "Damudya": {
										    				      "Damudya Thana": ["Damudya Municipality", "Darul Aman", "Shahidnagar", "Kazirhat"]
										    				    },
										    				    "Gosairhat": {
										    				      "Gosairhat Thana": ["Gosairhat Municipality", "Kodomtola", "Nagerpara", "Kuchipara"]
										    				    },
										    				    "Naria": {
										    				      "Naria Thana": ["Naria Municipality", "Bhojeshwar", "Chamta", "Shakhipur Road Area"]
										    				    },
										    				    "Shariatpur Sadar": {
										    				      "Shariatpur Sadar Thana": ["Shariatpur Municipality", "Palong", "Angaria", "Chikandi"]
										    				    },
										    				    "Zajira": {
										    				      "Zajira Thana": ["Zajira Municipality", "Mulna", "Purba Naodoba", "Bara Krishnapur"]
										    				    }
										    				  },

										    				  "Sherpur": {
										    				    "Jhenaigati": {
										    				      "Jhenaigati Thana": ["Jhenaigati Municipality", "Dhala", "Gouripur", "Hatil"]
										    				    },
										    				    "Nakla": {
										    				      "Nakla Thana": ["Nakla Municipality", "Ganopaddi", "Chandrakona", "Gouripur Road Area"]
										    				    },
										    				    "Nalitabari": {
										    				      "Nalitabari Thana": ["Nalitabari Municipality", "Bagber", "Nonni", "Poragaon"]
										    				    },
										    				    "Sherpur Sadar": {
										    				      "Sherpur Sadar Thana": ["Sherpur Municipality", "Nayabil", "Gajni", "Baniajan"]
										    				    },
										    				    "Sreebardi": {
										    				      "Sreebardi Thana": ["Sreebardi Municipality", "Kakilakura", "Jhulgaon", "Gosaipur"]
										    				    }
										    				  }
					  };

function populateDistricts(crimeId){
    const district=document.getElementById("editZilla"+crimeId);

    district.innerHTML="<option value=''>Select District</option>";

    Object.keys(locationData).forEach(function(zilla){
        district.innerHTML+=
        "<option value='"+zilla+"'>"+zilla+"</option>";
    });
}

function populateUpazillas(crimeId){
    const district=document.getElementById("editZilla"+crimeId).value;
    const upazilla=document.getElementById("editUpazilla"+crimeId);

    upazilla.innerHTML="<option>Select Upazilla</option>";

    if(!district) return;

    Object.keys(locationData[district]).forEach(function(upa){
        upazilla.innerHTML+=
        "<option value='"+upa+"'>"+upa+"</option>";
    });

    populatePoliceStations(crimeId);
}

function populatePoliceStations(crimeId){

    const district=document.getElementById("editZilla"+crimeId).value;
    const upazilla=document.getElementById("editUpazilla"+crimeId).value;

    const ps=document.getElementById("editPS"+crimeId);

    ps.innerHTML="<option>Select Police Station</option>";

    if(!district || !upazilla) return;

    Object.keys(locationData[district][upazilla]).forEach(function(station){

        ps.innerHTML+=
        "<option value='"+station+"'>"+station+"</option>";

    });

    populateAreas(crimeId);
}

function populateAreas(crimeId){

    const district=document.getElementById("editZilla"+crimeId).value;
    const upazilla=document.getElementById("editUpazilla"+crimeId).value;
    const station=document.getElementById("editPS"+crimeId).value;

    const area=document.getElementById("editArea"+crimeId);

    area.innerHTML="<option>Select Area</option>";

    if(!district || !upazilla || !station) return;

    locationData[district][upazilla][station].forEach(function(a){

        area.innerHTML+=
        "<option value='"+a+"'>"+a+"</option>";

    });

}
</script>
</body>
</html>