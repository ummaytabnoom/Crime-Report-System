<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Base64" %>

<%@ page import="org.apache.commons.fileupload.FileItem" %>
<%@ page import="org.apache.commons.fileupload.disk.DiskFileItemFactory" %>
<%@ page import="org.apache.commons.fileupload.servlet.ServletFileUpload" %>
<%
    // Set encoding
    request.setCharacterEncoding("UTF-8");
    boolean isMultipart = ServletFileUpload.isMultipartContent(request);

    String currentUser = (String) session.getAttribute("username");

String userRole = (String) session.getAttribute("userRole");

boolean isAdmin = "admin".equals(userRole);
boolean isPolice = "police".equals(userRole);

    byte[] imageBytes = null;
    String message = "";
    boolean reportSubmitted = false;

    // Variables to hold user info
    int userId = 0;
    String fullName = "";

    // Fetch profile picture and user details
    if (currentUser != null) {
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

            // Fetch profile picture
            String picSql = "SELECT PROFILE_PICTURE, ID, FULL_NAME FROM REGISTERED_USERS WHERE USER_NAME = ?";
            PreparedStatement picStmt = conn.prepareStatement(picSql);
            picStmt.setString(1, currentUser);
            ResultSet rs = picStmt.executeQuery();

            if (rs.next()) {
                // Fetch profile picture
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

                // Fetch user ID and full name
                userId = rs.getInt("ID");
                fullName = rs.getString("FULL_NAME");
            }
            rs.close();
            picStmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            message = "Error loading user info: " + e.getMessage();
        }
    }

    // Handle form submission
    if (isMultipart) {
        DiskFileItemFactory factory = new DiskFileItemFactory();
        ServletFileUpload upload = new ServletFileUpload(factory);

        String zilla = "";
        String upazilla = "";
        String policeStation = "";
        String area = "";
        String roadName = "";
        String roadNo = "";
        String date = "";
        String category = "";
        String description = "";
        String hideIdentity = "NO"; // default value
        byte[] mediaBytes = null;
        String mediaType = "";

        try {
            List<FileItem> formItems = upload.parseRequest(request);

            for (FileItem item : formItems) {
                if (item.isFormField()) {
                    String fieldName = item.getFieldName();
                    String fieldValue = item.getString("UTF-8");

                    switch (fieldName) {
                        case "zilla": zilla = fieldValue; break;
                        case "upazilla": upazilla = fieldValue; break;
                        case "policeStation": policeStation = fieldValue; break;
                        case "area": area = fieldValue; break;
                        case "roadName": roadName = fieldValue; break;
                        case "roadNo": roadNo = fieldValue; break;
                        case "date": date = fieldValue; break;
                        case "category": category = fieldValue; break;
                        case "description": description = fieldValue; break;
                        case "hideIdentity": hideIdentity = fieldValue; break;
                    }
                } else {
                	if (!item.isFormField()) {

                	    if (item.getName() != null && item.getSize() > 0) {

                	    	 mediaType = item.getContentType();

                	        if (mediaType.startsWith("image/")
                	                || mediaType.startsWith("video/")) {

                	            mediaBytes = item.get();

                	        } else {

                	            throw new Exception("Only image and video files are allowed.");

                	        }
                	    }
                	}
                }
            }

            // Insert into REPORTED_CRIMES
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");
            conn.setAutoCommit(false);

            String sql = "INSERT INTO REPORTED_CRIMES " +
                         "(ID, USER_NAME, FULL_NAME, ZILLA, UPAZILLA, POLICE_STATION, AREA, ROAD_NAME, ROAD_NO, DATE_OF_INCIDENT, CATEGORY, DESCRIPTION, STATUS, MEDIA_FILE,MEDIA_TYPE, HIDE_IDENTITY) " +
                         "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?, ?, ?)";

            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, userId);
            stmt.setString(2, currentUser);
            stmt.setString(3, fullName);
            stmt.setString(4, zilla);
            stmt.setString(5, upazilla);
            stmt.setString(6, policeStation);
            stmt.setString(7, area);
            stmt.setString(8, roadName);
            stmt.setString(9, roadNo);
            stmt.setString(10, date);
            stmt.setString(11, category);
            stmt.setString(12, description);
            stmt.setString(13, "Pending");
            if (mediaBytes != null) {
                stmt.setBytes(14, mediaBytes);
            } else {
                stmt.setNull(14, Types.BLOB);
            }
            stmt.setString(15, mediaType);
            stmt.setString(16, hideIdentity);

            int row = stmt.executeUpdate();
            conn.commit();

            if (row > 0) {
                message = "<p class='message success'>Report submitted successfully.</p>";
                reportSubmitted = true;
            } else {
                message = "<p class='message error'>Failed to submit the report.</p>";
            }

            stmt.close();
            conn.close();
        } catch (Exception ex) {
            ex.printStackTrace();
            message = "<p class='message error'>Error: " + ex.getMessage() + "</p>";
        }
    }

    if (reportSubmitted) {
        response.setHeader("Refresh", "3; URL=MyReports.jsp");
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Report a Crime</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-image: url("images/reportBackground.jpg");
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
  .navbar {
            background-color: #FF8C00;
            color: white;
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }

        .navbar-title {
            font-size: 22px;
            font-weight: bold;
        }

/* TOGGLE MENU ICON */
.menu-icon{
    font-size: 30px;
    cursor: pointer;
    color: white;

    position: absolute;
    top: 18px;
    right: 20px;

    z-index: 1000;
}

/* DROPDOWN MENU */
.dropdown{
    position: absolute;
    top: 60px;
    right: 10px;

    background-color: white;
    box-shadow: 0 4px 10px rgba(0,0,0,0.2);
    border-radius: 6px;

    display: none;
    flex-direction: column;

    min-width: 180px;
    z-index: 999;
}
 .dropdown a { padding: 12px 16px; text-decoration: none; color: #333; border-bottom: 1px solid #eee; display: block; }
        .dropdown a:hover { background-color: #f2f2f2; }
        .show { display: flex; }
        .top-right-buttons { position: absolute; top: 20px; left:80%; transform: translateX(-50%); display: flex; gap: 20px; }
        .top-right-buttons a { padding: 10px 15px; background-color: #005F5F; color: white; text-decoration: none; border-radius: 5px; transition: all 0.3s ease; }
        .top-right-buttons a:hover { background-color: #008C8C; transform: scale(1.05); box-shadow: 0 4px 8px rgba(0,0,0,0.2); }
        .container { max-width: 750px; margin: 20px auto 10px; background-color: rgba(255,255,255,0.9); padding: 20px 30px; border-radius: 10px; box-shadow: 0 0 15px rgba(0,0,0,0.2); }
        h2 { text-align: center; color: #005F5F; margin-bottom: 20px; }
        table { width: 100%; border-collapse: separate; border-spacing: 0 10px; }
        td { padding: 6px 8px; vertical-align: top; }
        td:first-child { width: 20%; font-weight: bold; color: #333; }
        input[type="text"], input[type="date"], select, textarea { width: 100%; padding: 8px; border: 1px solid #bbb; border-radius: 6px; font-size: 14px; box-sizing: border-box; }
        input[type="file"] { padding: 10px; border: 1px solid #bbb; border-radius: 6px; font-size: 14px; width: 100%; box-sizing: border-box; background-color: white; cursor: pointer; }
        textarea { resize: vertical; }
        input[type="submit"] { display: block; margin: 25px auto 0; padding: 12px 25px; background-color: #FF8C00; color: white; border: none; border-radius: 8px; cursor: pointer; font-size: 16px; }
        input[type="submit"]:hover { background-color: #e67300; }
        .message { text-align: center; margin-top: 15px; font-weight: bold; padding: 10px; border-radius: 5px; }
        .message.success { color: green; background-color: #d4edda; border: 1px solid #c3e6cb; }
        .message.error { color: red; background-color: #f8d7da; border: 1px solid #f5c6cb; }
        .user-info { display: inline-flex; align-items: center; gap: 10px; margin-left: 5px; vertical-align: middle; }
        .user-pic { width: 50px; height: 50px; border-radius: 50%; object-fit: cover; border: 2px solid #fff; }
        .user-name { font-weight: bold; color: white; font-size: 25px; }
        .error-message { color: #d9534f; font-size: 0.9em; margin-top: 10px; margin-bottom: 10px; display: none; }
    </style>
</head>
<body>
    <div class="navbar">
        <div class="navbar-title">
            <div class="user-info">
                <% if (imageBytes != null) { %>
                    <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
                <% } else { %>
                    <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
                <% } %>
                <span class="user-name"><%= currentUser %></span>
            </div>
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

    <div class="top-right-buttons">
        <a href="UserHome.jsp">User Dashboard</a>
        <a href="MyReports.jsp">My Reports</a>
    </div>

    <div class="container">
        <h2>Crime Reporting Form</h2>
        <%= message %>
        <form action="ReportSub.jsp" method="post" enctype="multipart/form-data">

<table border="0" cellpadding="8" cellspacing="0">

    <!-- Full Name (hidden) -->
    <input type="hidden" name="fullName" value="<%= fullName %>">

    <!-- ZILLA -->
    <tr>
        <td>Zilla:</td>
        <td>
            <select id="zilla" name="zilla" onchange="loadUpazillas()" required>
                <option value="">-- Select Zilla --</option>
            </select>
        </td>
    </tr>

    <!-- UPAZILLA -->
    <tr>
        <td>Upazilla:</td>
        <td>
            <select id="upazilla" name="upazilla" onchange="loadPoliceStations()" required>
                <option value="">-- Select Upazilla --</option>
            </select>
        </td>
    </tr>

    <!-- POLICE STATION -->
    <tr>
        <td>Police Station:</td>
        <td>
            <select id="policeStation" name="policeStation" onchange="loadAreas()" required>
                <option value="">-- Select Police Station --</option>
            </select>
        </td>
    </tr>

    <!-- AREA -->
    <tr>
        <td>Area:</td>
        <td>
            <select id="area" name="area" required>
                <option value="">-- Select Area --</option>
            </select>
        </td>
    </tr>

    <!-- ROAD NAME -->
    <tr>
        <td>Road Name:</td>
        <td>
            <input type="text" name="roadName" required style="width: 100%;">
        </td>
    </tr>

    <!-- ROAD NO -->
    <tr>
        <td>Road No:</td>
        <td>
            <input type="text" name="roadNo" required style="width: 100%;">
        </td>
    </tr>

    <!-- DATE -->
    <tr>
        <td>Date of Incident:</td>
        <td>
            <input type="date" name="date" id="incidentDate"
                   required onchange="validateIncidentDate()" style="width: 100%;">
            <br>
            <span id="incident-date-error" class="error-message"></span>
        </td>
    </tr>

    <!-- CATEGORY -->
    <tr>
        <td>Crime Category:</td>
        <td>
            <select name="category" required style="width: 100%;">
                <option value="">Select a category</option>
                <option value="Theft">Theft</option>
                <option value="Robbery">Robbery</option>
                <option value="Assault">Assault</option>
                <option value="Harassment">Harassment</option>
                <option value="Vandalism">Vandalism</option>
            </select>
        </td>
    </tr>

    <!-- DESCRIPTION -->
    <tr>
        <td>Description:</td>
        <td>
            <textarea name="description" rows="4" required style="width: 100%;"></textarea>
        </td>
    </tr>

    <!-- FILE -->
    <tr>
        <td>Picture:</td>
        <td>
           <input type="file"
       name="mediaFile"
       accept="image/*,video/*">
        </td>
    </tr>

    <!-- HIDE IDENTITY -->
    <tr>
        <td>Hide Identity:</td>
        <td>
            <select name="hideIdentity" required style="width: 100%;">
                <option value="NO" selected>No</option>
                <option value="YES">Yes</option>
            </select>
        </td>
    </tr>

    <!-- SUBMIT -->
    <tr>
        <td colspan="2" style="text-align:center; padding-top:15px;">
            <input type="submit" value="Submit Report">
        </td>
    </tr>

</table>

</form>
    </div>
    <script src="js/locationData.js"></script>
    <script>
        document.addEventListener("DOMContentLoaded", function () {
            const menuIcon = document.querySelector('.menu-icon');
            const dropdownMenu = document.getElementById('dropdownMenu');

            menuIcon.addEventListener('click', function () {
                dropdownMenu.classList.toggle('show');
            });

            window.addEventListener('click', function (event) {
                if (!event.target.matches('.menu-icon')) {
                    if (dropdownMenu.classList.contains('show')) {
                        dropdownMenu.classList.remove('show');
                    }
                }
            });

            // Sets the max date to today
            const today = new Date();
            const yyyy = today.getFullYear();
            const mm = String(today.getMonth() + 1).padStart(2, '0');
            const dd = String(today.getDate()).padStart(2, '0');
            const maxDate = `${yyyy}-${mm}-${dd}`;
            document.getElementById("incidentDate").setAttribute("max", maxDate);
        });

        function validateIncidentDate() {
            const incidentDateInput = document.getElementById("incidentDate");
            const incidentDateError = document.getElementById("incident-date-error");
            const selectedDate = new Date(incidentDateInput.value);
            const today = new Date();
            today.setHours(0,0,0,0);
            selectedDate.setHours(0,0,0,0);


            if (selectedDate > today) {
                incidentDateInput.setCustomValidity("Invalid date.");
                incidentDateError.textContent = "Invalid date.";
                incidentDateError.style.display = "block";
            } else {
                incidentDateInput.setCustomValidity("");
                incidentDateError.textContent = "";
                incidentDateError.style.display = "none";
            }
        }
        
        
        const locationData = window.locationData;
        console.log(locationData);
        
        
        					  function loadZillas() {
        						    const zillaSelect = document.getElementById("zilla");

        						    zillaSelect.innerHTML =
        						        '<option value="">-- Select Zilla --</option>';

        						    Object.keys(locationData).forEach(zilla => {
        						        let option = document.createElement("option");

        						        option.value = zilla;
        						        option.textContent = zilla;

        						        zillaSelect.appendChild(option);
        						    });
        						}


        						function loadUpazillas() {

        						    const zilla =
        						        document.getElementById("zilla").value;

        						    const upazillaSelect =
        						        document.getElementById("upazilla");

        						    const policeSelect =
        						        document.getElementById("policeStation");

        						    const areaSelect =
        						        document.getElementById("area");


        						    upazillaSelect.innerHTML =
        						        '<option value="">-- Select Upazilla --</option>';

        						    policeSelect.innerHTML =
        						        '<option value="">-- Select Police Station --</option>';

        						    areaSelect.innerHTML =
        						        '<option value="">-- Select Area --</option>';

        						    if (!zilla) return;

        						    Object.keys(locationData[zilla]).forEach(upazilla => {

        						        let option = document.createElement("option");

        						        option.value = upazilla;
        						        option.textContent = upazilla;

        						        upazillaSelect.appendChild(option);

        						    });

        						}


        						function loadPoliceStations() {

        						    const zilla =
        						        document.getElementById("zilla").value;

        						    const upazilla =
        						        document.getElementById("upazilla").value;

        						    const policeSelect =
        						        document.getElementById("policeStation");

        						    const areaSelect =
        						        document.getElementById("area");


        						    policeSelect.innerHTML =
        						        '<option value="">-- Select Police Station --</option>';

        						    areaSelect.innerHTML =
        						        '<option value="">-- Select Area --</option>';

        						    if (!zilla || !upazilla) return;


        						    Object.keys(
        						        locationData[zilla][upazilla]
        						    ).forEach(police => {

        						        let option =
        						            document.createElement("option");

        						        option.value = police;
        						        option.textContent = police;

        						        policeSelect.appendChild(option);

        						    });

        						}


        						function loadAreas() {

        						    const zilla =
        						        document.getElementById("zilla").value;

        						    const upazilla =
        						        document.getElementById("upazilla").value;

        						    const police =
        						        document.getElementById("policeStation").value;

        						    const areaSelect =
        						        document.getElementById("area");


        						    areaSelect.innerHTML =
        						        '<option value="">-- Select Area --</option>';

        						    if (!zilla || !upazilla || !police)
        						        return;


        						    locationData[zilla][upazilla][police]
        						        .forEach(area => {

        						            let option =
        						                document.createElement("option");

        						            option.value = area;
        						            option.textContent = area;

        						            areaSelect.appendChild(option);

        						        });

        						}
        						
        						
        						document.addEventListener("DOMContentLoaded", function () {
        							
        							
        							console.log(locationData);
        						    console.log(Object.keys(locationData).length);

        							loadZillas()
        							

        						});
      </script>
      <script src="js/locationData.js"></script>
</body>
</html>
