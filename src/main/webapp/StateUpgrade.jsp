<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="java.util.List, java.util.Map, java.util.ArrayList, java.util.HashMap" %>

<%
    // Ensure only logged-in police officers can access this management action page
    String currentUser = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("userRole");

    if (currentUser == null || !"police".equals(userRole)) {
        response.sendRedirect("Login.jsp");
        return;
    }

    byte[] imageBytes = null;
    List<Map<String,Object>> crimeList = new ArrayList<>();
    String feedbackMessage = "";

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try {
        Class.forName("oracle.jdbc.OracleDriver");
        conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:XE",
                "system",
                "a12345");
        
        // Enforce auto-commit so Oracle saves changes instantly
        conn.setAutoCommit(true);

        /* =========================================================
           FETCH LOGGED-IN OFFICER'S ASSIGNED POSTING REGIONS
           (Using TRIM and UPPER to match variations safely)
        ========================================================= */
        String officerCity = "";
        String officerStation = "";
        
        
        String policeId = "";
        PreparedStatement idStmt = conn.prepareStatement(
                "SELECT TRIM(POLICE_ID) AS POLICE_ID FROM REGISTERED_USERS WHERE UPPER(TRIM(USER_NAME)) = UPPER(TRIM(?))");
        idStmt.setString(1, currentUser);
        ResultSet idRs = idStmt.executeQuery();
        if (idRs.next()) {
            policeId = idRs.getString("POLICE_ID");
        }
        idRs.close();
        idStmt.close();
        System.out.println("police"+policeId);
        PreparedStatement officerStmt = conn.prepareStatement(
                "SELECT TRIM(POSTING_CITY) AS POSTING_CITY, TRIM(POLICE_STATION) AS POLICE_STATION " +
                "FROM POLICE_INFO WHERE UPPER(TRIM(POLICE_ID)) = UPPER(TRIM(?))");
        officerStmt.setString(1, policeId); 
        ResultSet officerRs = officerStmt.executeQuery();

        if (officerRs.next()) {
            officerCity = officerRs.getString("POSTING_CITY");
            officerStation = officerRs.getString("POLICE_STATION");
            
            
            
        }
        officerRs.close();
        officerStmt.close();
        
        /* =========================================================
           HANDLE STATUS UPDATE (POST REQUEST)
        ========================================================= */
        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String crimeIdParam = request.getParameter("crimeId");
            String newStatus = request.getParameter("newStatus");
            
            

            if (crimeIdParam != null && newStatus != null && !crimeIdParam.trim().isEmpty()) {
                int crimeId = Integer.parseInt(crimeIdParam.trim());

                // Target STATUS and UPGRADED_BY from your table schema
                String updateQuery = "UPDATE REPORTED_CRIMES SET STATUS = ?, UPGRADED_BY = ? WHERE CRIME_ID = ?";
                PreparedStatement updatePs = conn.prepareStatement(updateQuery);

                updatePs.setString(1, newStatus.trim());
                updatePs.setString(2, currentUser.trim()); // Saves active police username
                updatePs.setInt(3, crimeId);

                int rowsAffected = updatePs.executeUpdate();
                updatePs.close();

                if (rowsAffected > 0) {
                    feedbackMessage = "Success! Status changed to '" + newStatus + "' and logged under officer '" + currentUser + "'.";
                } else {
                    feedbackMessage = "Error: No records updated for CRIME_ID: " + crimeId;
                }
            }
        }

        /* =========================================================
           FETCH POLICE OFFICER PROFILE PICTURE
        ========================================================= */
        stmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE UPPER(TRIM(USER_NAME))=UPPER(TRIM(?))");
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

        /* =========================================================
           FETCH FILTERED VISIBLE/APPROVED CRIMES
           Enhanced query using TRIM() on database columns to eliminate formatting gaps
        ========================================================= */
        PreparedStatement ps = conn.prepareStatement(
                "SELECT * FROM REPORTED_CRIMES " +
                "WHERE ACCEPTED_BY IS NOT NULL " +
                "AND UPPER(TRIM(ZILLA)) = UPPER(TRIM(?)) " +
                "AND UPPER(TRIM(POLICE_STATION)) = UPPER(TRIM(?)) " +
                "ORDER BY CRIME_ID DESC");

        ps.setString(1, officerCity != null ? officerCity : "");
        
        ps.setString(2, officerStation != null ? officerStation : "");

        ResultSet crimesRs = ps.executeQuery();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

        while (crimesRs.next()) {
            Map<String, Object> crime = new HashMap<>();
            String hideIdentity = crimesRs.getString("HIDE_IDENTITY");

            crime.put("crimeId", crimesRs.getInt("CRIME_ID"));
            crime.put("category", crimesRs.getString("CATEGORY"));
            crime.put("status", crimesRs.getString("STATUS"));
            crime.put("upgradedBy", crimesRs.getString("UPGRADED_BY"));
            crime.put("acceptedBy", crimesRs.getString("ACCEPTED_BY"));

            // Read CLOB Description
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

            java.sql.Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
            crime.put("date", (ts != null) ? sdf.format(ts) : "");

            // Location Builder
            String location = crimesRs.getString("ZILLA") + ", " +
                              crimesRs.getString("UPAZILLA") + ", " +
                              crimesRs.getString("POLICE_STATION") + ", " +
                              (crimesRs.getString("AREA") != null ? crimesRs.getString("AREA") + ", " : "") +
                              crimesRs.getString("ROAD_NAME") + ", Road No: " +
                              crimesRs.getString("ROAD_NO");
            crime.put("fullLocation", location);

         // Fetch media file and media type
            byte[] mediaBytes = crimesRs.getBytes("MEDIA_FILE");
            String mediaType = crimesRs.getString("MEDIA_TYPE");

            crime.put("mediaType", mediaType);

            if (mediaBytes != null) {
                crime.put("mediaData", Base64.getEncoder().encodeToString(mediaBytes));
            } else {
                crime.put("mediaData", "");
            }
            /* =====================================================
               FETCH REPORTER ACTUAL DETAILS
            ===================================================== */
            PreparedStatement userStmt = conn.prepareStatement(
                    "SELECT PROFILE_PICTURE, MOBILE, FULL_NAME, USER_NAME FROM REGISTERED_USERS WHERE UPPER(TRIM(USER_NAME))=UPPER(TRIM(?))");
            userStmt.setString(1, crimesRs.getString("USER_NAME"));
            ResultSet userRs = userStmt.executeQuery();

            String profileImg = "";
            String mobileNo = "";
            String fullNameReal = "";
            String userNameReal = "";

            if (userRs.next()) {
                byte[] profileBytes = userRs.getBytes("PROFILE_PICTURE");
                if (profileBytes != null) profileImg = Base64.getEncoder().encodeToString(profileBytes);
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

            if ("YES".equalsIgnoreCase(hideIdentity)) {
                crime.put("displayName", "Anonymous (Identity Hidden from Public)");
            } else {
                crime.put("displayName", fullNameReal + " (Username: " + userNameReal + ")");
            }

            crimeList.add(crime);
        }
        crimesRs.close();
        ps.close();

    } catch (Exception e) {
        feedbackMessage = "System Error: " + e.getMessage();
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception e) {}
        try { if (stmt != null) stmt.close(); } catch (Exception e) {}
        try { if (conn != null) conn.close(); } catch (Exception e) {}
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Police - Report Status Manager</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: url("images/adminHome.jpg") no-repeat center center fixed;
            background-size: cover;
            font-family: Arial, sans-serif;
        }
        .navbar {
            background-color: #FF8C00;
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .menu-icon {
            font-size: 26px;
            cursor: pointer;
            color: white;
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
        .dropdown a:hover { background-color: #f2f2f2; }
        .show { display: flex; }
        .top-right-buttons {
            position: absolute;
            top: 30px;
            left: 80%;
            transform: translateX(0%);
        }
        .top-right-buttons a {
            padding: 10px 15px;
            background-color: #005F5F;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-weight: bold;
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
            font-size: 22px;
        }
        .content-box {
            background-color: rgba(255, 255, 255, 0.96);
            padding: 30px;
            border-radius: 12px;
            max-width: 1000px;
            margin: 40px auto;
            color: black;
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        h2 { text-align: center; color: #222; }
        
        .crime-container {
            border: 1px solid #ddd;
            padding: 20px;
            margin: 20px auto;
            border-radius: 8px;
            background-color: #f9f9f9;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
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
            width: 100%;
            max-width: 500px;
            height: auto;
            display: block;
            margin: 15px 0;
            border-radius: 6px;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 4px;
            font-weight: bold;
            color: white;
        }
        .badge-pending { background-color: orange; }
        .badge-ongoing { background-color: #007BFF; }
        .badge-resolved { background-color: green; }

        .btn-group {
            margin-top: 15px;
            display: flex;
            gap: 10px;
        }
        .status-btn {
            padding: 10px 20px;
            border: none;
            border-radius: 5px;
            color: white;
            font-weight: bold;
            cursor: pointer;
            transition: opacity 0.2s;
        }
        .status-btn:hover { opacity: 0.9; }
        .p-btn { background-color: orange; }
        .o-btn { background-color: #007BFF; }
        .r-btn { background-color: green; }
        
        .meta-info {
            background: #eef2f3;
            padding: 10px;
            border-radius: 5px;
            font-size: 13px;
            margin-top: 10px;
        }
    </style>
</head>
<body>

    <div class="navbar">
        <div class="user-info">
            <% if (imageBytes != null) { %>
                <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" />
            <% } else { %>
                <img class="user-pic" src="images/default.png" />
            <% } %>
            <span class="user-name"><%= currentUser %> (Police Officer)</span>
        </div>
        <div class="top-right-buttons">
            <a href="UserHome.jsp">Dashboard</a>
        </div>
        <div class="menu-icon" onclick="toggleMenu()">☰</div>
        <div id="dropdownMenu" class="dropdown">
            <a href="PoliceHome.jsp">Police Panel</a>
            <a href="Settings.jsp">Settings</a>
            <a href="Logout.jsp">Logout</a>
        </div>
    </div>

    <div class="content-box">
        <h2>Investigative Case Status Management</h2>
        
        <% if(!feedbackMessage.isEmpty()){ %>
            <p style="color: blue; font-weight: bold; text-align: center; background: #e2e3e5; padding: 10px; border-radius: 5px;"><%= feedbackMessage %></p>
        <% } %>

        <%
        if (crimeList != null && !crimeList.isEmpty()) {
            for (Map<String,Object> crime : crimeList) {
                String currentStatus = (String) crime.get("status");
                String upgradedByStr = (String) crime.get("upgradedBy");
                
                String badgeClass = "badge-pending";
                String displayStatus = "Pending";
                
                if("Ongoing".equalsIgnoreCase(currentStatus) || "Under Investigation".equalsIgnoreCase(currentStatus)) {
                    badgeClass = "badge-ongoing";
                    displayStatus = "Under Investigation";
                }
                if("Resolved".equalsIgnoreCase(currentStatus)) {
                    badgeClass = "badge-resolved";
                    displayStatus = "Resolved";
                }
        %>
        
        <div class="crime-container">
            <% String profileImg = (String) crime.get("profileImg"); %>
            <% if (profileImg != null && !profileImg.isEmpty()) { %>
                <img src="data:image/jpeg;base64,<%= profileImg %>" class="profile-image">
            <% } else { %>
                <img src="images/default.png" class="profile-image">
            <% } %>

            <h3><%= crime.get("displayName") %></h3>
            <p><strong>Reporter Contact Mobile:</strong> <%= crime.get("mobileNo") %></p>
            <p><strong>Category:</strong> <%= crime.get("category") %></p>
            <p><strong>Incident Location:</strong> <%= crime.get("fullLocation") %></p>
            <p><strong>Incident Date:</strong> <%= crime.get("date") %></p>
            <p><strong>Details:</strong> <%= crime.get("description") %></p>
            
            <p><strong>Current Status:</strong> 
                <span class="status-badge <%= badgeClass %>"><%= displayStatus %></span>
            </p>

            <div class="meta-info">
                <strong>Vetted By Admin:</strong> <%= crime.get("acceptedBy") %> | 
                <strong>Upgraded By:</strong> <%= (upgradedByStr != null && !upgradedByStr.isEmpty()) ? upgradedByStr : "No Officer Assigned Yet" %>
            </div>

            <% String demoImg = (String) crime.get("demoImg"); %>
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

            <div class="btn-group">
                <form method="post" style="margin:0;">
                    <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                    <input type="hidden" name="newStatus" value="Pending">
                    <button type="submit" class="status-btn p-btn">Set Pending</button>
                </form>
                
                <form method="post" style="margin:0;">
                    <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                    <input type="hidden" name="newStatus" value="Under Investigation">
                    <button type="submit" class="status-btn o-btn">Set Under Investigation</button>
                </form>
                
                <form method="post" style="margin:0;">
                    <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                    <input type="hidden" name="newStatus" value="Resolved">
                    <button type="submit" class="status-btn r-btn">Set Resolved</button>
                </form>
            </div>
        </div>

        <%
            }
        } else {
        %>
            <p style="text-align:center; color:#666; font-size:16px;">No approved case records are available for your regional posting.</p>
        <%
        }
        %>
    </div>

    <script>
        function toggleMenu() {
            document.getElementById("dropdownMenu").classList.toggle("show");
        }
        window.onclick = function(event) {
            if (!event.target.matches('.menu-icon')) {
                var dropdown = document.getElementById("dropdownMenu");
                if (dropdown && dropdown.classList.contains('show')) {
                    dropdown.classList.remove('show');
                }
            }
        };
    </script>
</body>
</html>