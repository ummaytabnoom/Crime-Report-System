<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="javax.servlet.http.Part" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.util.List" %>
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*" %>

<%
//Load current profile picture

    request.setCharacterEncoding("UTF-8");
    boolean isMultipart = ServletFileUpload.isMultipartContent(request);

    String currentUser = (String) session.getAttribute("username");
    byte[] imageBytes = null;
    byte[] fileBytes = null;
	String message = "";
	//FOR FETCHING PROFILE_PICTURE
	if (currentUser != null) {
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
            message = "Error loading profile picture: " + e.getMessage();
        }
    }


	if (isMultipart) {
	    DiskFileItemFactory factory = new DiskFileItemFactory();
	    ServletFileUpload upload = new ServletFileUpload(factory);

	    String userName = (String) session.getAttribute("username");
	    String fullName = "";
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

	    byte[] demoPicBytes = null;
	    byte[] profilePicBytes = null;

	    try {
	        List<FileItem> formItems = upload.parseRequest(request);

	        for (FileItem item : formItems) {
	            if (item.isFormField()) {
	                String fieldName = item.getFieldName();
	                String fieldValue = item.getString("UTF-8");

	                switch (fieldName) {
	                    case "fullName": fullName = fieldValue; break;
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
	                if (item.getName() != null && item.getSize() > 0) {
	                    demoPicBytes = item.get(); // 👈 Read file into byte array
	                }
	            }
	        }

	        Class.forName("oracle.jdbc.driver.OracleDriver");
	        Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");
	        conn.setAutoCommit(false);

	        // 👇 Fetch PROFILE_PICTURE from REGISTERED_USERS
	        String profileQuery = "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME = ?";
	        PreparedStatement profileStmt = conn.prepareStatement(profileQuery);
	        profileStmt.setString(1, userName);
	        ResultSet profileRs = profileStmt.executeQuery();

	        if (profileRs.next()) {
	            Blob profileBlob = profileRs.getBlob("PROFILE_PICTURE");
	            if (profileBlob != null) {
	                profilePicBytes = profileBlob.getBytes(1, (int) profileBlob.length()); // 👈 Convert to byte[]
	            }
	        }

	        profileRs.close();
	        profileStmt.close();

	        // ✅ Insert into REPORTED_CRIMES including profile picture
	        String sql = "INSERT INTO REPORTED_CRIMES (USER_NAME, FULL_NAME, ZILLA, UPAZILLA, POLICE_STATION, AREA, ROAD_NAME, ROAD_NO, DATE_OF_INCIDENT, CATEGORY, DESCRIPTION, STATUS, DEMO_PICTURE, HIDE_IDENTITY) " +
	                     "VALUES (?, ?, ?, ?, ?, ?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?, ?)";

	        PreparedStatement stmt = conn.prepareStatement(sql);

	        stmt.setString(1, userName);
	        stmt.setString(2, fullName);
	        stmt.setString(3, zilla);
	        stmt.setString(4, upazilla);
	        stmt.setString(5, policeStation);
	        stmt.setString(6, area);
	        stmt.setString(7, roadName);
	        stmt.setString(8, roadNo);
	        stmt.setString(9, date);
	        stmt.setString(10, category);
	        stmt.setString(11, description);
	        stmt.setString(12, "Pending");
	        

	        if (demoPicBytes != null) {
	            stmt.setBytes(13, demoPicBytes);
	        } else {
	            stmt.setNull(13, Types.BLOB);
	        }

	        if (profilePicBytes != null) {
	            stmt.setBytes(14, profilePicBytes);
	        } else {
	            stmt.setNull(14, Types.BLOB);
	        }
	        
	        stmt.setString(14, hideIdentity);  // new line for HIDE_IDENTITY

	        int row = stmt.executeUpdate();
	        conn.commit();

	        if (row > 0) {
	            message = "<p class='message success'>Report submitted successfully.</p>";
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

        .menu-icon {
            font-size: 26px;
            cursor: pointer;
        }

        .dropdown {
            position: absolute;
            top: 60px;
            right: 20px;
            background-color: white;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
            border-radius: 6px;
            display: none;
            flex-direction: column;
            min-width: 180px;
            z-index: 999;
        }

        .dropdown a {
            padding: 12px 16px;
            text-decoration: none;
            color: #333;
            border-bottom: 1px solid #eee;
            display: block;
        }

        .dropdown a:hover {
            background-color: #f2f2f2;
        }

        .show {
            display: flex;
        }

        .top-right-buttons {
    position: absolute;
    top: 10px;
    left: 80%;
    transform: translateX(-50%);
    display: flex;
    gap: 20px;
}

.top-right-buttons a {
    padding: 10px 15px;
    background-color: #005F5F;
    color: white;
    text-decoration: none;
    border-radius: 5px;
    transition: all 0.3s ease;   /* smooth effect */
}

.top-right-buttons a:hover {
    background-color: #008C8C;  /* lighter teal */
    transform: scale(1.05);     /* slight zoom */
    box-shadow: 0 4px 8px rgba(0,0,0,0.2); /* shadow */
}


        .container {
            max-width: 750px;
            margin: 20px auto 10px;
            background-color: rgba(255, 255, 255, 0.9);
            padding: 20px 30px;
            border-radius: 10px;
            box-shadow: 0 0 15px rgba(0, 0, 0, 0.2);
        }

        h2 {
            text-align: center;
            color: #005F5F;
            margin-bottom: 20px;
        }

        table {
            width: 100%;
            border-collapse: separate;
            border-spacing: 0 10px;
        }

        td {
            padding: 6px 8px;
            vertical-align: top;
        }

        td:first-child {
            width: 20%;
            font-weight: bold;
            color: #333;
        }

        input[type="text"], input[type="date"], select, textarea {
            width: 100%;
            padding: 8px;
            border: 1px solid #bbb;
            border-radius: 6px;
            font-size: 14px;
            box-sizing: border-box;
        }
        input[type="file"] {
    padding: 10px;
    border: 1px solid #bbb;
    border-radius: 6px;
    font-size: 14px;
    width: 100%; /* Makes it fill the full width of the cell */
    box-sizing: border-box;
    background-color: white;
    cursor: pointer;
}
        

        textarea {
            resize: vertical;
        }

        input[type="submit"] {
            display: block;
            margin: 25px auto 0;
            padding: 12px 25px;
            background-color: #FF8C00;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
        }

        input[type="submit"]:hover {
            background-color: #e67300;
        }

        .success {
            text-align: center;
            margin-top: 15px;
            color: green;
            font-weight: bold;
        }
        .user-info {
    display: inline-flex;
    align-items: center;
    gap: 10px;
    margin-left: 5px;
    vertical-align: middle;
}

.user-pic {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    object-fit: cover;
    border: 2px solid #fff;
}

.user-name {
    font-weight: bold;
    color: white;
    font-size: 25px;
}
         .error-message {
            color: #d9534f;
            font-size: 0.9em;
            margin-top: 10px;
            margin-bottom: 10px;
            display: none;
        }
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
        <a href="SettingsForAdmin.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

    <div class="top-right-buttons">
        <a href="UserHomeForAdmin.jsp">User Dashboard</a>
        <a href="MyReportsForAdmin.jsp">My Reports</a>
        <a href="AdminsHome.jsp">AdminsHome</a>
    </div>

    <div class="container">
        <h2>Crime Reporting Form</h2>
        <%= message %>
        <form action="ReportSubForAdmin.jsp" method="post" enctype="multipart/form-data">
            <table>
            	<tr><td>Full Name:</td><td><input type="text" name="fullName" required></td></tr>
                <tr><td>Zilla:</td><td><input type="text" name="zilla" required></td></tr>
                <tr><td>Upazilla:</td><td><input type="text" name="upazilla" required></td></tr>
                <tr><td>Police Station:</td><td><input type="text" name="policeStation" required></td></tr>
                <tr><td>Area:</td><td><input type="text" name="area" required></td></tr>
                <tr><td>Road Name:</td><td><input type="text" name="roadName" required></td></tr>
                <tr><td>Road No:</td><td><input type="text" name="roadNo" required></td></tr>
                <tr><td>Date of Incident:</td><td><input type="date" name="date" id="incidentDate" required onchange="validateIncidentDate()"><br><span id="incident-date-error" class="error-message"></span></td></tr>
                <tr><td>Crime Category:</td>
                    <td>
                        <select name="category" required>
                            <option value="">Select a category</option>
                            <option value="Theft">Theft</option>
                            <option value="Robbery">Robbery</option>
                            <option value="Assault">Assault</option>
                            <option value="Harassment">Harassment</option>
                            <option value="Vandalism">Vandalism</option>
                        </select>
                    </td>
                </tr>
                <tr><td>Description:</td><td><textarea name="description" rows="4" required></textarea></td></tr>
                <tr><td>Picture of criminals or incident:</td><td><input type="file" name="demoPicture" accept="image/*"></td></tr>
                
                <tr>
    <td>Hide Identity:</td>
    <td>
        <select name="hideIdentity" required>
            <option value="NO" selected>No</option>
            <option value="YES">Yes</option>
        </select>
    </td>
</tr>
                
                
            </table>
            <input type="submit" value="Submit Report">
        </form>
    </div>
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
            
            // Sets the max date to today on page load
            const today = new Date();
            const yyyy = today.getFullYear();
            const mm = String(today.getMonth() + 1).padStart(2, '0');
            const dd = String(today.getDate()).padStart(2, '0');
            const maxDate = `${yyyy}-${mm}-${dd}`;
            document.getElementById("incidentDate").setAttribute("max", maxDate);

        });
    
    // Function to validate the incident date
    function validateIncidentDate() {
        const incidentDateInput = document.getElementById("incidentDate");
        const incidentDateError = document.getElementById("incident-date-error");
        const selectedDate = new Date(incidentDateInput.value);
        const today = new Date();

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

    </script>
</body>
</html>