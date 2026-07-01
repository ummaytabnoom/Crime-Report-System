
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
            String[] parts = value.split(",");

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
                if(response === "success"){
                    successCallback();
                }else if(response.startsWith("LOCKED:")){
                    alert(response.replace("LOCKED:", ""));
                    window.location.reload(); 
                }else{
                    showNotification(response);
                }
            }else{
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
            "<div style='margin-bottom: 8px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Zilla:</label> <input type='text' id='editZilla" + crimeId + "' value='" + currentZilla + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div style='margin-bottom: 8px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Upazilla:</label> <input type='text' id='editUpazilla" + crimeId + "' value='" + currentUpazilla + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div style='margin-bottom: 8px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Area:</label> <input type='text' id='editArea" + crimeId + "' value='" + currentArea + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" + // Added Area input field
            "<div style='margin-bottom: 8px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Police Station:</label> <input type='text' id='editPS" + crimeId + "' value='" + currentPS + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div style='margin-bottom: 8px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Road Name:</label> <input type='text' id='editRoadName" + crimeId + "' value='" + currentRoadName + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div style='margin-bottom: 12px;'><label style='display:inline-block; width:110px; font-weight:bold; color:#333;'>Road No:</label> <input type='text' id='editRoadNo" + crimeId + "' value='" + currentRoadNo + "' style='width: 60%; padding: 6px; border:1px solid #ccc; border-radius:4px;'></div>" +
            "<div>" +
                "<button type='button' id='saveLocBtn" + crimeId + "' style='background:#005F5F; color:white; border:none; padding:6px 15px; margin-right:5px; border-radius:4px; cursor:pointer; font-weight:bold;'>Save</button>" +
                "<button type='button' id='cancelLocBtn" + crimeId + "' style='background:#888; color:white; border:none; padding:6px 15px; border-radius:4px; cursor:pointer; font-weight:bold;'>Cancel</button>" +
            "</div>" +
        "</div>";

    document.getElementById("cancelLocBtn" + crimeId).onclick = function() { locSpan.innerHTML = originalHTML; };

    document.getElementById("saveLocBtn" + crimeId).onclick = function() {
        let zilla = document.getElementById("editZilla" + crimeId).value.trim();
        let upazilla = document.getElementById("editUpazilla" + crimeId).value.trim();
        let area = document.getElementById("editArea" + crimeId).value.trim();
        let ps = document.getElementById("editPS" + crimeId).value.trim();
        let roadName = document.getElementById("editRoadName" + crimeId).value.trim();
        let roadNo = document.getElementById("editRoadNo" + crimeId).value.trim();

        // Combined string matches order processed inside backend action block
        let compositeValue = zilla + ", " + upazilla + ", " + area + ", " + ps + ", " + roadName + ", " + roadNo;

        sendRequest(
            "action=updateLocation&crimeId=" + crimeId + "&value=" + encodeURIComponent(compositeValue),
            function() {
                locSpan.innerText = (zilla || "N/A") + ", " + (upazilla || "N/A") + ", " + (area || "N/A") + ", " + (ps || "N/A") + ", " + (roadName || "N/A") + ", Road No: " + (roadNo || "N/A");
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
</script>
</body>
</html>