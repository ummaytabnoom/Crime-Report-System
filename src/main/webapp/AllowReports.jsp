<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>
<%
    String currentUser = (String) session.getAttribute("username");
    byte[] imageBytes = null;
    List<Map<String,Object>> crimeList = new ArrayList<>();
    String message = "";

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

        // Handle POST requests for approval or deletion
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String action = request.getParameter("action");
            String crimeIdParam = request.getParameter("crimeId");

            if (action != null && crimeIdParam != null) {
                int crimeId = Integer.parseInt(crimeIdParam);

                if ("delete".equalsIgnoreCase(action)) {
                    PreparedStatement delStmt = conn.prepareStatement("DELETE FROM REPORTED_CRIMES WHERE CRIME_ID = ?");
                    delStmt.setInt(1, crimeId);
                    delStmt.executeUpdate();
                    delStmt.close();
                    message = "Crime report deleted successfully.";

                } else if ("approve".equalsIgnoreCase(action)) {
                    // Start transaction to ensure atomicity
                    conn.setAutoCommit(false);
                    try {
                        // 1. Select the crime to be moved
                        PreparedStatement selectStmt = conn.prepareStatement("SELECT * FROM REPORTED_CRIMES WHERE CRIME_ID = ?");
                        selectStmt.setInt(1, crimeId);
                        ResultSet crimeRs = selectStmt.executeQuery();
                        if (crimeRs.next()) {
                            // 2. Insert into REPORTED_CRIMES
                            PreparedStatement insertStmt = conn.prepareStatement(
                                    "INSERT INTO REPORTED_CRIMES (CRIME_ID, USER_NAME, FULL_NAME, ZILLA, UPAZILLA, POLICE_STATION, AREA, ROAD_NAME, ROAD_NO, DATE_OF_INCIDENT, CATEGORY, DESCRIPTION, STATUS, DEMO_PICTURE, PROFILE_PICTURE, HIDE_IDENTITY, USER_ID) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)");
                            
                            // Copy all column values
                            insertStmt.setInt(1, crimeRs.getInt("CRIME_ID"));
                            insertStmt.setString(2, crimeRs.getString("USER_NAME"));
                            insertStmt.setString(3, crimeRs.getString("FULL_NAME"));
                            insertStmt.setString(4, crimeRs.getString("ZILLA"));
                            insertStmt.setString(5, crimeRs.getString("UPAZILLA"));
                            insertStmt.setString(6, crimeRs.getString("POLICE_STATION"));
                            insertStmt.setString(7, crimeRs.getString("AREA"));
                            insertStmt.setString(8, crimeRs.getString("ROAD_NAME"));
                            insertStmt.setString(9, crimeRs.getString("ROAD_NO"));
                            insertStmt.setTimestamp(10, crimeRs.getTimestamp("DATE_OF_INCIDENT"));
                            insertStmt.setString(11, crimeRs.getString("CATEGORY"));
                            insertStmt.setString(12, crimeRs.getString("DESCRIPTION"));
                            insertStmt.setString(13, "Approved"); // Set status to "Approved"
                            insertStmt.setBlob(14, crimeRs.getBlob("DEMO_PICTURE"));
                            insertStmt.setBlob(15, crimeRs.getBlob("PROFILE_PICTURE"));
                            insertStmt.setString(16, crimeRs.getString("HIDE_IDENTITY"));
                            insertStmt.setInt(17, crimeRs.getInt("USER_ID"));

                            insertStmt.executeUpdate();
                            insertStmt.close();

                            // 3. Delete from REPORTED_CRIMES
                            PreparedStatement delStmt = conn.prepareStatement("DELETE FROM REPORTED_CRIMES WHERE CRIME_ID = ?");
                            delStmt.setInt(1, crimeId);
                            delStmt.executeUpdate();
                            delStmt.close();
                            
                            conn.commit();
                            message = "Crime report approved and archived successfully.";
                        } else {
                            message = "Error: Crime report not found.";
                        }
                        crimeRs.close();
                        selectStmt.close();
                    } catch (SQLException e) {
                        conn.rollback();
                        message = "Error: Failed to approve and archive. " + e.getMessage();
                    } finally {
                        conn.setAutoCommit(true);
                    }
                }
            }
        }

        // Get current user profile picture
        stmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?");
        stmt.setString(1, currentUser);
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

        // Get all reported crimes, applying search filter
        String searchQuery = request.getParameter("search");
        String sql = "SELECT * FROM REPORTED_CRIMES ";
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            sql += "WHERE USER_NAME LIKE ? OR FULL_NAME LIKE ? ";
        }
        sql += "ORDER BY CRIME_ID DESC";

        PreparedStatement ps = conn.prepareStatement(sql);
        int paramIndex = 1;
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            ps.setString(paramIndex++, "%" + searchQuery + "%");
            ps.setString(paramIndex++, "%" + searchQuery + "%");
        }
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

            PreparedStatement userStmt = conn.prepareStatement(
                    "SELECT PROFILE_PICTURE, MOBILE, FULL_NAME, USER_NAME FROM REGISTERED_USERS WHERE USER_NAME=?");
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

            crime.put("profileImg", profileImg);
            crime.put("mobileNo", mobileNo);
            crime.put("realFullName", fullNameReal);
            crime.put("realUsername", userNameReal);
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

    } catch (Exception e) {
        out.println("<p style='color:red;'>Database Error: " + e.getMessage() + "</p>");
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) { }
        try { if (stmt != null) stmt.close(); } catch (SQLException e) { }
        try { if (conn != null) conn.close(); } catch (SQLException e) { }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Report Approval</title>
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

        /* Styles for Approval/Delete Buttons */
        .approval-buttons {
            display: flex;
            gap: 10px;
            margin-top: 15px;
            justify-content: center;
        }

        .approval-buttons form {
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

        .approve-btn {
            background-color: #28A745; /* Green for Approve */
        }

        .approve-btn:hover {
            background-color: #218838;
        }
        
        .delete-btn {
            background-color: #DC3545; /* Red for Delete */
        }

        .delete-btn:hover {
            background-color: #c82333;
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
        <a href="ReportSubForAdmin.jsp">Report A Crime</a>
        <a href="MyReportsForAdmin.jsp">My Reports</a>
        <a href="AdminsHome.jsp">Admin Dashboard</a>
        <a href="UserHomeForAdmin.jsp">User Dashboard</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="SettingsForAdmin.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
    <h2>Report Approval Panel</h2>

    <% if (!message.isEmpty()) { %>
        <p style="color: green; text-align: center; font-weight: bold;"><%= message %></p>
    <% } %>

    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name" value="<%= (request.getParameter("search") != null) ? request.getParameter("search") : "" %>" />
            <button type="submit">Search</button>
            <% if (request.getParameter("search") != null && !request.getParameter("search").trim().isEmpty()) { %>
                <button type="button" onclick="window.location='ApprovalMan.jsp'">Clear</button>
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

        <div class="approval-buttons">
            <form method="post" onsubmit="return confirm('Are you sure you want to approve this report? It will be moved to permanent records.');">
                <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                <input type="hidden" name="action" value="approve">
                <button type="submit" class="btn approve-btn">Approve & Archive</button>
            </form>
            <form method="post" onsubmit="return confirm('Are you sure you want to delete this report? This action is permanent.');">
                <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                <input type="hidden" name="action" value="delete">
                <button type="submit" class="btn delete-btn">Delete Report</button>
            </form>
        </div>
    </div>
    <% }
    } else { %>
        <p style="text-align: center; color: black; font-size: 18px;">No reported crimes awaiting approval.</p>
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