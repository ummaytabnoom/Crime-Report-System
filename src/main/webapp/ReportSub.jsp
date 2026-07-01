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
</body>
</html>
