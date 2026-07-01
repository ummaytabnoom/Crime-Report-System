<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.util.Base64" %>
<%
String currentUser = (String) session.getAttribute("username");
String userRole = (String) session.getAttribute("userRole");
boolean isAdmin = "admin".equals(userRole);
boolean isPolice = "police".equalsIgnoreCase(userRole);
String username = (String) session.getAttribute("username");

String message = "";
byte[] imageBytes = null;

// Load current user's profile picture
if (currentUser != null) {
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    try {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

        String sql = "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME = ?";
        stmt = conn.prepareStatement(sql);
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
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
        message = "Error loading profile picture: " + e.getMessage();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) { /* Ignored */ }
        try { if (stmt != null) stmt.close(); } catch (SQLException e) { /* Ignored */ }
        try { if (conn != null) conn.close(); } catch (SQLException e) { /* Ignored */ }
    }
}
// Get search query
String searchQuery = request.getParameter("search");
String searchParam = (searchQuery != null && !searchQuery.trim().isEmpty()) ? "%" + searchQuery.trim().toLowerCase() + "%" : null;
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Admin Users</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background: url("images/adminMan.png") no-repeat center center/cover;
            font-family: Arial, sans-serif;
            color: white;
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
        }

        .dropdown {
            position: absolute;
            top: 60px;
            right: 20px;
            background-color: white;
            color: black;
            border-radius: 6px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.2);
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
            left: 70%;
            transform: translateX(0%);
        }

        .top-right-buttons a {
            background-color: #005F5F;
            color: white;
            padding: 8px 20px;
            text-decoration: none;
            border-radius: 5px;
            margin-right: 10px;
        }

        .content-box {
            background-color: rgba(255, 255, 255, 0.95);
            padding: 30px;
            border-radius: 10px;
            max-width: 1350px;
            margin: 20px auto;
            color: black;
            box-shadow: 0 4px 15px rgba(0,0,0,0.3);
            overflow-x: auto;
        }

        table {
            width: 100%;
            border-collapse: collapse;
            font-size: 13px;
        }

        th, td {
            border: 1px solid #bbb;
            padding: 10px 6px;
            text-align: center;
            vertical-align: middle;
        }

        th { 
            background-color: #FFA500; 
            color: white; 
            font-size: 14px;
            white-space: nowrap;
        }

        tr:nth-child(even) { background-color: #f9f9f9; }
        tr:hover { background-color: #f1f5f9; }

        img.profile {
            width: 70px;
            height: 70px;
            object-fit: cover;
            border-radius: 50%;
            border: 2px solid #005F5F;
        }
        
        img.front-pic {
            width: 80px;
            height: auto;
            border-radius: 4px;
            box-shadow: 0 1px 4px rgba(0,0,0,0.15);
            margin-top: 5px;
        }

        .user-info {
            display: flex;
            align-items: center;
            gap: 10px;
        }

        .user-pic {
            width: 50px;
            height: 50px;
            border-radius: 50%;
            object-fit: cover;
            border: 2px solid white;
            box-shadow: 0 2px 6px rgba(0,0,0,0.3);
        }

        .user-name {
            font-size: 16px;
            font-weight: bold;
            color: white;
        }

        .search-bar { text-align:center; margin-bottom:20px; }
        .search-bar input[type="text"] { width:250px; padding:8px; border:1px solid #ccc; border-radius:5px; }
        .search-bar button { padding:8px 15px; border:none; border-radius:5px; background-color:#FF8C00; color:#fff; cursor:pointer; }
        .search-bar button:hover { background-color:#e67300; }

        h2 { text-align:center; margin-bottom:20px; color:#333; }
        
        .info-block {
            text-align: left;
            font-size: 12px;
            line-height: 1.4;
        }
    </style>
</head>
<body>

<div class="navbar">
    <div class="top-right-buttons">
        <a href="UserHome.jsp">Dashboard</a>
    </div>

    <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
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

<div class="content-box">
    <h2>Detailed Police Directory Panel</h2>
    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by name or username..." value="<%= (searchQuery != null) ? searchQuery : "" %>" />
            <button type="submit">Search</button>
            <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                <button type="button" onclick="window.location='PoliceInfo.jsp'">Clear</button>
            <% } %>
        </form>
    </div>
    <table>
        <tr>
            <th>Photos</th>
            <th>Account Details</th>
            <th>Designation Details</th>
            <th>Deployment Station</th>
            <th>Parental Lineage</th>
            <th>Permanent Address</th>
            <th>Medical Records / Injuries</th>
        </tr>
        <%
            Connection conn = null;
            PreparedStatement stmt = null;
            ResultSet rs = null;
            try {
                Class.forName("oracle.jdbc.driver.OracleDriver");
                conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");

                // CHANGED: The inner query selection string maps p.POSTING_CITY and p.POLICE_STATION directly out of the JOIN database view.
               String sql = "SELECT u.FULL_NAME, u.USER_NAME, u.EMAIL, u.MOBILE, u.PROFILE_PICTURE, u.POLICE_ID, " +
             "       p.POST_NAME, p.POSTING_AREA, p.POSTING_CITY, p.POLICE_STATION, " +
             "       p.SELECTION_YEAR, p.POSTING_YEAR, p.FATHERS_NAME, p.MOTHERS_NAME, " +
             "       p.PERMANENT_ADDRESS, p.MERITAL_STATUS, p.INJURIES, p.PICTURE_FRONT " +
             "FROM REGISTERED_USERS u " +
             "LEFT JOIN POLICE_INFO p ON UPPER(TRIM(p.POLICE_ID)) = UPPER(TRIM(u.POLICE_ID)) " +
             "WHERE u.ROLE = 'police'";

if (searchParam != null) {
    sql += " AND (LOWER(u.FULL_NAME) LIKE ? OR LOWER(u.USER_NAME) LIKE ?)";
}

sql += " ORDER BY u.ID ASC";
                
                stmt = conn.prepareStatement(sql);

                if (searchParam != null) {
                    stmt.setString(1, searchParam);
                    stmt.setString(2, searchParam);
                }

                rs = stmt.executeQuery();
                
                if (!rs.isBeforeFirst()) {
                    out.println("<tr><td colspan='7' style='padding:20px; font-weight:bold; text-align:center;'>No matching deployment profiles found.</td></tr>");
                }
                
                while (rs.next()) {
                    String fullName = rs.getString("FULL_NAME");
                    String userName = rs.getString("USER_NAME");
                    String email = rs.getString("EMAIL");
                    String mobile = rs.getString("MOBILE");
                    String targetPoliceId = rs.getString("POLICE_ID") != null ? rs.getString("POLICE_ID") : "N/A";

                    // Fetch police records securely
                    String postName = rs.getString("POST_NAME") != null ? rs.getString("POST_NAME") : "N/A";
                    String postingArea = rs.getString("POSTING_AREA") != null ? rs.getString("POSTING_AREA") : "N/A";
                    
                    // ADDED columns extraction logic from database result set
                    String postingCity = rs.getString("POSTING_CITY") != null ? rs.getString("POSTING_CITY") : "N/A";
                    String policeStation = rs.getString("POLICE_STATION") != null ? rs.getString("POLICE_STATION") : "N/A";
                    
                    int selectionYear = rs.getInt("SELECTION_YEAR");
                    int postingYear = rs.getInt("POSTING_YEAR");
                    String fathersName = rs.getString("FATHERS_NAME") != null ? rs.getString("FATHERS_NAME") : "N/A";
                    String mothersName = rs.getString("MOTHERS_NAME") != null ? rs.getString("MOTHERS_NAME") : "N/A";
                    String permanentAddress = rs.getString("PERMANENT_ADDRESS") != null ? rs.getString("PERMANENT_ADDRESS") : "N/A";
                    String maritalStatus = rs.getString("MERITAL_STATUS") != null ? rs.getString("MERITAL_STATUS") : "N/A";
                    String injuries = rs.getString("INJURIES") != null ? rs.getString("INJURIES") : "None Reported";

                    // Binary conversion parsing for account photo avatar
                    Blob profileBlob = rs.getBlob("PROFILE_PICTURE");
                    String base64Profile = "";
                    if (profileBlob != null) {
                        InputStream is = profileBlob.getBinaryStream();
                        ByteArrayOutputStream os = new ByteArrayOutputStream();
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        while ((bytesRead = is.read(buffer)) != -1) {
                            os.write(buffer, 0, bytesRead);
                        }
                        base64Profile = Base64.getEncoder().encodeToString(os.toByteArray());
                        is.close(); os.close();
                    }

                    // Binary conversion parsing for uniform profile picture
                    Blob frontBlob = rs.getBlob("PICTURE_FRONT");
                    String base64Front = "";
                    if (frontBlob != null) {
                        InputStream is = frontBlob.getBinaryStream();
                        ByteArrayOutputStream os = new ByteArrayOutputStream();
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        while ((bytesRead = is.read(buffer)) != -1) {
                            os.write(buffer, 0, bytesRead);
                        }
                        base64Front = Base64.getEncoder().encodeToString(os.toByteArray());
                        is.close(); os.close();
                    }
        %>
        <tr>
            <td>
                <div style="display:flex; flex-direction:column; gap:8px; align-items:center;">
                    <% if (!base64Profile.isEmpty()) { %>
                        <img src="data:image/jpeg;base64,<%= base64Profile %>" class="profile" alt="Avatar"/>
                    <% } else { %>
                        <img src="images/default-profile.png" class="profile" alt="Default Avatar"/>
                    <% } %>
                    
                    <% if (!base64Front.isEmpty()) { %>
                        <img src="data:image/jpeg;base64,<%= base64Front %>" class="front-pic" alt="Uniform Photo"/>
                    <% } %>
                </div>
            </td>
            
            <td>
                <div class="info-block">
                    <strong>Name:</strong> <%= fullName %><br>
                    <strong>Username:</strong> <%= userName %><br>
                    <strong>Mapped ID:</strong> <span style="color:#FF8C00; font-weight:bold;"><%= targetPoliceId %></span><br>
                    <strong>Email:</strong> <%= email %><br>
                    <strong>Mobile:</strong> <%= mobile %>
                </div>
            </td>
            
            <td>
                <div class="info-block">
                    <strong>Rank/Post:</strong> <span style="color:#005F5F; font-weight:bold;"><%= postName %></span><br>
                    <strong>Enlistment Year:</strong> <%= (selectionYear > 0 ? String.valueOf(selectionYear) : "N/A") %><br>
                    <strong>Station Assignment Year:</strong> <%= (postingYear > 0 ? String.valueOf(postingYear) : "N/A") %>
                </div>
            </td>

            <td>
                <div class="info-block">
                    <strong>Zilla/City:</strong> <span style="color:#FF8C00; font-weight:bold;"><%= postingCity %></span><br>
                    <strong>Thana/Station:</strong> <%= policeStation %><br>
                    <strong>Specific Area:</strong> <%= postingArea %>
                </div>
            </td>
            
            <td>
                <div class="info-block">
                    <strong>Father:</strong> <%= fathersName %><br>
                    <strong>Mother:</strong> <%= mothersName %><br>
                    <strong>Marital Status:</strong> <%= maritalStatus %>
                </div>
            </td>
            
            <td style="max-width: 200px; text-align: left; word-break: break-word;"><%= permanentAddress %></td>
            
            <td style="max-width: 200px; text-align: left; color: #dc3545; font-weight: 500; word-break: break-word;"><%= injuries %></td>
        </tr>
        <%
                }
            } catch (Exception e) {
                out.println("<tr><td colspan='7' style='color: red; font-weight:bold;'>Database runtime fault: " + e.getMessage() + "</td></tr>");
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException e) { /* Ignored */ }
                if (stmt != null) try { stmt.close(); } catch (SQLException e) { /* Ignored */ }
                if (conn != null) try { conn.close(); } catch (SQLException e) { /* Ignored */ }
            }
        %>
    </table>
</div>

<script>
    function toggleMenu() {
        document.getElementById("dropdownMenu").classList.toggle("show");
    }
</script>

</body>
</html>