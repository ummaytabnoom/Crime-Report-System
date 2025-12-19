<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>
<%
    String currentUser = (String) session.getAttribute("username");
    Integer currentUserId = (Integer) session.getAttribute("userId");

    byte[] imageBytes = null;
    List<Map<String,Object>> crimeList = new ArrayList<>();

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        Connection conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

        // Get current user profile picture
        PreparedStatement stmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID=?");
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

     // Get all reported crimes from the PERMANENT_REPORTS table
        PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM PERMANENT_REPORTS ORDER BY CRIME_ID DESC");
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

            // Format date
            java.sql.Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
            String formattedDate = (ts != null) ? sdf.format(ts) : "";
            crime.put("date", formattedDate);

            String zilla = crimesRs.getString("ZILLA");
            String upazilla = crimesRs.getString("UPAZILLA");
            String policeStation = crimesRs.getString("POLICE_STATION");
            String roadName = crimesRs.getString("ROAD_NAME");
            String roadNo = crimesRs.getString("ROAD_NO");
            crime.put("fullLocation", zilla + ", " + upazilla + ", " + policeStation + ", " + roadName + ", Road No: " + roadNo);

            byte[] demoBytes = crimesRs.getBytes("DEMO_PICTURE");
            crime.put("demoImg", (demoBytes != null) ? Base64.getEncoder().encodeToString(demoBytes) : "");

            // Fetch reporter info
            PreparedStatement userStmt = conn.prepareStatement(
                    "SELECT PROFILE_PICTURE, MOBILE, FULL_NAME, USER_NAME FROM REGISTERED_USERS WHERE ID=?");
            userStmt.setString(1, crimesRs.getString("USER_NAME"));
            ResultSet userRs = userStmt.executeQuery();

            String profileImg = "";
            String mobileNo = "";
            String fullNameReal = "";
            String userNameReal = "";
            if(userRs.next()) {
                byte[] profileBytes = userRs.getBytes("PROFILE_PICTURE");
                if(profileBytes != null) profileImg = Base64.getEncoder().encodeToString(profileBytes);
                mobileNo = userRs.getString("MOBILE");
                fullNameReal = userRs.getString("FULL_NAME");
                userNameReal = userRs.getString("USER_NAME");
            }
            userRs.close();
            userStmt.close();

            crime.put("profileImg", profileImg); // will be hidden if anonymous
            crime.put("mobileNo", mobileNo);
            crime.put("realFullName", fullNameReal);
            crime.put("realUsername", userNameReal);
            crime.put("hideIdentity", hideIdentity);

            // Set display names
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
        body {
            margin: 0;
            padding: 0;
            background: url("images/adminMan.png") no-repeat center center fixed;
            background-size: cover;
            font-family: Arial, sans-serif;
            color: white;
        }
        .navbar {
            background-color: #FF8C00;
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
        }
        .menu-icon {
            font-size: 26px;
            cursor: pointer;
            position: relative;
            top: 10px;
        }
        .dropdown {
            position: absolute;
            top: 60px;
            right: 20px;
            background-color: white;
            color: black;
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
        }
        .dropdown a:hover {
            background-color: #f2f2f2;
        }
        .show {
            display: flex;
        }
        .user-info {
            display: inline-flex;
            align-items: center;
            gap: 10px;
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

        .crime-container {
            border: 1px solid #ccc;
            padding: 15px;
            margin: 25px auto;
            border-radius: 10px;
            background-color: #f2f2f2;
            color: black;
            width: 80%;
            max-width: 800px;
            box-shadow: 0 0 10px rgba(0, 0, 0, 0.2);
        }
        .profile-image {
            width: 60px;
            height: 60px;
            object-fit: cover;
            border-radius: 50%;
            float: left;
            margin-right: 15px;
            border: 2px solid #007BFF;
        }
	.crime-image {
	    width: 600px;   /* exact width */
	    height: 450px;  /* exact height */
	    display: block;
	    margin-top: 15px;
	    border-radius: 8px;
	}
        .top-right-buttons {
            position: absolute;
            top: 30px;
            left: 55%;
            transform: translateX(0%);
        }
        .top-right-buttons a {
            background-color: #005F5F;
            color: white;
            padding: 8px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin-right: 10px;
            transition: all 0.3s ease;
        }
        .top-right-buttons a:hover {
            background-color: #008C8C;
            color: #fff;
            transform: scale(1.05);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }
        .search-bar {
            width: 60%;
            max-width: 500px;
            margin: 0 auto 20px auto;
            display: block;
            padding: 10px 15px;
            border-radius: 6px;
            border: 1px solid #ccc;
            font-size: 14px;
        }
        .content-box {
            background-color: rgba(255, 255, 255, 0.95);
            padding: 30px;
            border-radius: 10px;
            max-width: 1200px;
            margin: 40px auto;
            color: black;
        }
        h2 {
            text-align: center;
            margin-bottom: 20px;
            color: black; 
        }

        /* Anonymous button style */
        .user-info-btn {
            background-color: #007BFF;
            color: white;
            padding: 6px 16px;
            border: none;
            border-radius: 20px;
            cursor: pointer;
            font-weight: bold;
            transition: all 0.3s ease;
            box-shadow: 0 2px 5px rgba(0,0,0,0.3);
        }
        .user-info-btn:hover {
            background-color: #3399FF;
            transform: scale(1.05);
            box-shadow: 0 4px 10px rgba(0,0,0,0.4);
        }
        #userModal {
    display: none; 
    position: fixed; 
    top: 0; left: 0; 
    width: 100%; height: 100%; 
    background: rgba(0,0,0,0.5); 
    justify-content: center; 
    align-items: center;
    z-index: 1000;
}

#userModalContent {
    background: white; 
    padding: 30px; 
    border-radius: 15px; 
    max-width: 400px; 
    text-align: center;
    color: black;
    font-weight: bold;
    box-shadow: 0 4px 20px rgba(0,0,0,0.3);
}

#userModalContent h3 {
    margin-top: 0;
    margin-bottom: 15px;
    color: #333;
}

#userModalContent img {
    width: 100px;
    height: 100px;
    object-fit: cover;
    border-radius: 50%;
    border: 2px solid #007BFF;
    margin-bottom: 15px;
    align-items: center;
}

#userModalContent p {
    margin: 5px 0;
    color: #000;
    font-size: 16px;
}

#userModalContent button {
    margin-top: 20px;
    padding: 8px 18px;
    border: none;
    border-radius: 8px;
    background-color: #007BFF;
    color: white;
    font-size: 16px;
    cursor: pointer;
    transition: all 0.3s ease;
}

#userModalContent button:hover {
    background-color: #3399FF;
}

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
        <a href="MyReportsForAdmin.jsp">My Reports</a>
        <a href="AdminsHome.jsp">Admin Dashboard</a>
        <a href="ReportSubForAdmin.jsp">Report Crime</a>
        <a href="AllowReports.jsp">Allow Reports</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="SettingsForAdmin.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>


<div class="content-box">
<h2>All Reported Crime Incidents</h2>
<input type="text" id="searchInput" class="search-bar" placeholder="Search by location..." onkeyup="filterCrimes()">

<% if (crimeList != null && !crimeList.isEmpty()) {
    for (Map<String,Object> crime : crimeList) {
        String displayName = (String) crime.get("displayName");
        String hideIdentity = (String) crime.get("hideIdentity");
%>
<div class="crime-container">
    <% String profileImg = (String) crime.get("profileImg"); %>
    <% if ("YES".equalsIgnoreCase(hideIdentity)) { %>
        <img src="images/default.png" class="profile-image" alt="Anonymous"/>
    <% } else if (profileImg != null && !profileImg.isEmpty()) { %>
        <img src="data:image/jpeg;base64,<%= profileImg %>" class="profile-image" alt="Profile"/>
    <% } else { %>
        <img src="images/default.png" class="profile-image" alt="Default"/>
    <% } %>

    <h3>
    <% if("Anonymous".equals(displayName)) { %>
        <button class="user-info-btn"
            onclick="showUserInfo('<%= crime.get("realFullName") %>', '<%= crime.get("realUsername") %>', '<%= crime.get("mobileNo") %>', '<%= crime.get("profileImg") %>')">Anonymous</button>
    <% } else { %>
        <%= displayName %><%= crime.get("displayUsername") %>
        <span style="color: gray; font-size: 14px;"> | Mobile: <%= crime.get("mobileNo") %></span>
    <% } %>
    </h3>

    <p><strong>Category:</strong> <%= crime.get("category") %></p>
    <p class="crime-location"><strong>Location:</strong> <%= crime.get("fullLocation") %></p>
    <p><strong>Date:</strong> <%= crime.get("date") %></p>
    <p><strong>Description:</strong> <%= crime.get("description") %></p>
    <p><strong>Status:</strong> <%= crime.get("status") %></p>
    <% String demoImg = (String) crime.get("demoImg"); %>
    <% if (demoImg != null && !demoImg.isEmpty()) { %>
        <img src="data:image/jpeg;base64,<%= demoImg %>" class="crime-image" alt="Crime Image"/>
    <% } else { %>
        <p><i>No crime image uploaded.</i></p>
    <% } %>
</div>
<% } } else { %>
    <p style="text-align:center; color:black;">No reported crimes found.</p>
<% } %>
</div>

<!-- Modal -->
<div id="userModal">
    <div id="userModalContent">
        <img id="modalProfileImg" src="" 
     style="width:80px; height:80px; border-radius:50%; margin: 0 auto 10px auto; display:block;">

<h3>User Information</h3>
        <p id="modalFullName"></p>
        <p id="modalUsername"></p>
        <p id="modalMobile"></p>
        <button onclick="closeModal()">Close</button>
    </div>
</div>

<script>
function showUserInfo(fullName, userName, mobile, profileImg) {
    const imgEl = document.getElementById("modalProfileImg");
    if(profileImg && profileImg !== "") {
        imgEl.src = "data:image/jpeg;base64," + profileImg;
        imgEl.style.display = "block";
    } else {
        imgEl.style.display = "none";
    }
    document.getElementById("modalFullName").innerText = "Full Name: " + fullName;
    document.getElementById("modalUsername").innerText = "Username: " + userName;
    document.getElementById("modalMobile").innerText = "Mobile No: " + mobile;
    document.getElementById("userModal").style.display = "flex";
}
function closeModal() {
    document.getElementById("userModal").style.display = "none";
}
function toggleMenu() {
    document.getElementById("dropdownMenu").classList.toggle("show");
}
function filterCrimes() {
    const input = document.getElementById("searchInput").value.toLowerCase();
    const containers = document.getElementsByClassName("crime-container");
    for (let i = 0; i < containers.length; i++) {
        const locationElement = containers[i].querySelector(".crime-location");
        if (locationElement) {
            const locationText = locationElement.innerText.toLowerCase();
            containers[i].style.display = locationText.includes(input) ? "block" : "none";
        }
    }
}
</script>
</body>
</html>