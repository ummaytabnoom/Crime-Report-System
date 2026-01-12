<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>

<%
    String currentUser = (String) session.getAttribute("username");
    if (currentUser == null) {
        response.sendRedirect("Login.jsp");
        return;
    }

    byte[] profileImageBytes = null;
    List<Map<String, Object>> crimeList = new ArrayList<>();
    String message = "";
    String searchQuery = request.getParameter("search");
    
    // Use a cache to store user details to avoid multiple database calls inside the loop
    Map<String, Map<String, String>> userCache = new HashMap<>();

    // Use try-with-resources to ensure resources are always closed
    try (Connection conn = DriverManager.getConnection(
            "jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345")) {
        
        Class.forName("oracle.jdbc.OracleDriver");

        // --- Handle POST requests (Status update/deletion) ---
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String action = request.getParameter("action");
            String crimeIdParam = request.getParameter("crimeId");
            if (action != null && crimeIdParam != null) {
                int crimeId = Integer.parseInt(crimeIdParam);
                String sql = "";
                if ("delete".equalsIgnoreCase(action)) {
                    sql = "DELETE FROM REPORTED_CRIMES WHERE REPORT_ID = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setInt(1, crimeId);
                        ps.executeUpdate();
                    }
                    message = "Crime report deleted successfully.";
                } else {
                    sql = "UPDATE REPORTED_CRIMES SET STATUS = ? WHERE REPORT_ID = ?";
                    try (PreparedStatement ps = conn.prepareStatement(sql)) {
                        ps.setString(1, action);
                        ps.setInt(2, crimeId);
                        ps.executeUpdate();
                    }
                    message = "Status updated to " + action + ".";
                }
            }
        }
        
        // --- Fetch current user's profile picture once ---
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?")) {
            ps.setString(1, currentUser);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Blob blob = rs.getBlob("PROFILE_PICTURE");
                    if (blob != null) {
                        try (InputStream is = blob.getBinaryStream();
                             ByteArrayOutputStream os = new ByteArrayOutputStream()) {
                            byte[] buffer = new byte[1024];
                            int bytesRead;
                            while ((bytesRead = is.read(buffer)) != -1) {
                                os.write(buffer, 0, bytesRead);
                            }
                            profileImageBytes = os.toByteArray();
                        }
                    }
                }
            }
        }

        // --- Fetch ALL user details into a cache to avoid repeated queries ---
        try (PreparedStatement ps = conn.prepareStatement(
                "SELECT PROFILE_PICTURE, MOBILE, FULL_NAME, USER_NAME FROM REGISTERED_USERS")) {
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, String> userInfo = new HashMap<>();
                    byte[] profileBytes = rs.getBytes("PROFILE_PICTURE");
                    userInfo.put("profileImg", (profileBytes != null) ? Base64.getEncoder().encodeToString(profileBytes) : "");
                    userInfo.put("mobile", rs.getString("MOBILE"));
                    userInfo.put("fullName", rs.getString("FULL_NAME"));
                    userCache.put(rs.getString("USER_NAME"), userInfo);
                }
            }
        }

        // --- Fetch ALL crime reports with search functionality ---
        StringBuilder sqlBuilder = new StringBuilder("SELECT * FROM REPORTED_CRIMES");
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            sqlBuilder.append(" WHERE LOWER(USER_NAME) LIKE ? OR LOWER(FULL_NAME) LIKE ?");
        }
        sqlBuilder.append(" ORDER BY REPORT_ID DESC");

        try (PreparedStatement ps = conn.prepareStatement(sqlBuilder.toString())) {
            int paramIndex = 1;
            if (searchQuery != null && !searchQuery.trim().isEmpty()) {
                ps.setString(paramIndex++, "%" + searchQuery.toLowerCase() + "%");
                ps.setString(paramIndex++, "%" + searchQuery.toLowerCase() + "%");
            }
            try (ResultSet crimesRs = ps.executeQuery()) {
                SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                while (crimesRs.next()) {
                    Map<String, Object> crime = new HashMap<>();
                    String reporterUsername = crimesRs.getString("USER_NAME");
                    String hideIdentity = crimesRs.getString("HIDE_IDENTITY");

                    crime.put("crimeId", crimesRs.getInt("REPORT_ID"));
                    crime.put("userName", reporterUsername);
                    crime.put("category", crimesRs.getString("CATEGORY"));
                    crime.put("description", crimesRs.getString("DESCRIPTION"));
                    crime.put("status", crimesRs.getString("STATUS"));

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

                    // Use the cached user details
                    Map<String, String> reporterInfo = userCache.get(reporterUsername);
                    if(reporterInfo != null) {
                        crime.put("profileImg", reporterInfo.get("profileImg"));
                        crime.put("mobileNo", reporterInfo.get("mobile"));
                        crime.put("realFullName", reporterInfo.get("fullName"));
                        crime.put("realUsername", reporterUsername);
                    } else {
                        // Handle case where user info is not in cache (e.g., deleted user)
                        crime.put("profileImg", "");
                        crime.put("mobileNo", "N/A");
                        crime.put("realFullName", "Unknown");
                        crime.put("realUsername", "Unknown");
                    }
                    
                    crime.put("hideIdentity", hideIdentity);

                    if ("YES".equalsIgnoreCase(hideIdentity)) {
                        crime.put("displayName", "Anonymous");
                        crime.put("displayUsername", "");
                    } else {
                        crime.put("displayName", crime.get("realFullName"));
                        crime.put("displayUsername", " (Username: " + crime.get("realUsername") + ")");
                    }
                    
                    crimeList.add(crime);
                }
            }
        }
    } catch (Exception e) {
        // Log the full stack trace for debugging purposes in a real application
        // e.printStackTrace();
        message = "Database Error: " + e.getMessage();
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>State Upgrade Panel</title>
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
            max-width: 400px;
            max-height: 300px;
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
        .search-bar form {
            display: flex;
            gap: 10px;
        }
        .search-bar input[type="text"] {
            flex-grow: 1;
            padding: 8px 12px;
            border-radius: 4px;
            border: 1px solid #ddd;
        }
        .search-bar button {
            padding: 8px 15px;
            border: none;
            border-radius: 4px;
            background-color: #007BFF;
            color: white;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }
        .search-bar button:hover {
            background-color: #0056b3;
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

        .status-buttons {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            justify-content: center;
        }

        .status-buttons form {
            margin: 0;
        }

        .btn {
            padding: 8px 15px;
            border: none;
            border-radius: 5px;
            color: white;
            font-weight: bold;
            cursor: pointer;
            transition: background-color 0.3s ease, transform 0.2s ease;
        }

        .btn:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
        }

        .pending {
            background-color: #FFC107;
        }

        .pending:hover {
            background-color: #e0a800;
        }

        .under {
            background-color: #007BFF;
        }

        .under:hover {
            background-color: #0056b3;
        }

        .resolved {
            background-color: #28A745;
        }

        .resolved:hover {
            background-color: #218838;
        }
    </style>
</head>
<body>
<div class="navbar">
    <div class="user-info">
        <% if (profileImageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(profileImageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>
    <div class="top-right-buttons">
       
        <a href="PoliceHome.jsp">Police Dashboard</a>
        <a href="UserHome.jsp">User Dashboard</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="SettingsForPolice.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
    <h2>State Upgrade Panel</h2>

    <% if (!message.isEmpty()) { %>
        <p style="color: green; text-align: center; font-weight: bold;"><%= message %></p>
    <% } %>

    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name" value="<%= (searchQuery != null) ? searchQuery : "" %>" />
            <button type="submit">Search</button>
            <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                <button type="button" onclick="window.location='StateUpgrade.jsp'">Clear</button>
            <% } %>
        </form>
    </div>

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
        <p><strong>Location:</strong> <%= crime.get("fullLocation") %></p>
        <p><strong>Date:</strong> <%= crime.get("date") %></p>
        <p><strong>Description:</strong> <%= crime.get("description") %></p>
        <p><strong>Status:</strong> <%= crime.get("status") %></p>

        <% if (!((String)crime.get("demoImg")).isEmpty()) { %>
            <img src="data:image/jpeg;base64,<%= crime.get("demoImg") %>" class="crime-image" />
        <% } else { %>
            <p><i>No crime image uploaded.</i></p>
        <% } %>

        <div class="status-buttons">
            <form method="post">
                <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                <input type="hidden" name="action" value="Pending">
                <button type="submit" class="btn pending">Set Pending</button>
            </form>
            <form method="post">
                <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                <input type="hidden" name="action" value="Under Investigation">
                <button type="submit" class="btn under">Set Under Investigation</button>
            </form>
            <form method="post">
                <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                <input type="hidden" name="action" value="Resolved">
                <button type="submit" class="btn resolved">Set Resolved</button>
            </form>
        </div>

    </div>
    <% }
    } else { %>
        <p style="text-align: center; color: black; font-size: 18px;">No crime reports found.</p>
    <% } %>

    <div id="userModal">
        <div id="userModalContent">
           <img id="modalProfileImg" src=""
     style="width:80px; height:80px; border-radius:50%; display:block; margin: 0 auto 15px auto;">
<h3>User Information</h3>

            <p id="modalFullName"></p>
            <p id="modalUsername"></p>
            <p id="modalMobile"></p>
            <button onclick="closeModal()">Close</button>
        </div>
    </div>
</div>

<script>
    function showUserInfo(fullName, userName, mobile, profileImg) {
        const imgEl = document.getElementById("modalProfileImg");
        if(profileImg && profileImg !== "") {
            imgEl.src = "data:image/jpeg;base64," + profileImg;
            imgEl.style.display = "block";
        } else {
            imgEl.src = "images/default.png";
            imgEl.style.display = "block";
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
</script>
</body>
</html>