<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.util.Base64" %>
<%
String currentUser = (String) session.getAttribute("username");
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
        /* Keep your existing CSS unchanged */
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
            max-width: 1200px;
            margin: 20px auto;
            color: black;
        }

        table {
            width: 100%;
            border-collapse: collapse;
        }

        th, td {
            border: 1px solid #999;
            padding: 10px;
            text-align: center;
        }

        th { background-color: #FFA500; color: white; }

        tr:nth-child(even) { background-color: #f9f9f9; }

        img.profile {
            width: 80px;
            height: 80px;
            object-fit: cover;
            border-radius: 50%;
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
            transition: transform 0.2s ease;
        }

        .user-pic:hover { transform: scale(1.1); }

        .user-name {
            font-size: 16px;
            font-weight: bold;
            color: white;
            letter-spacing: 0.5px;
        }
         .search-bar { text-align:center; margin-bottom:20px; }
        .search-bar input[type="text"] { width:250px; padding:8px; border:1px solid #ccc; border-radius:5px; }
        .search-bar button { padding:8px 15px; border:none; border-radius:5px; background-color:#FF8C00; color:#fff; cursor:pointer; }
        .search-bar button:hover { background-color:#e67300; }
   

        h2 { text-align:center; margin-bottom:20px; color:#333; }
    </style>
</head>
<body>

<div class="navbar">
	<div class="top-right-buttons">
        <a href="PoliceHome.jsp">Police Dashboard</a>
        <a href="UserHomeForPolice.jsp">User Dashboard</a>
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
        <a href="SettingsForPolice.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
    <h2>All Admin Users</h2>
    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name" value="<%= (searchQuery != null) ? searchQuery : "" %>" />
            <button type="submit">Search</button>
            <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                <button type="button" onclick="window.location='AdminInfo.jsp'">Clear</button>
            <% } %>
        </form>
    </div>
    <table>
        <tr>
            <th>Profile Picture</th>
            <th>Full Name</th>
            <th>Username</th>
            <th>Email</th>
            <th>Mobile</th>
        </tr>
        <%
            Connection conn = null;
            PreparedStatement stmt = null;
            ResultSet rs = null;
            try {
                Class.forName("oracle.jdbc.driver.OracleDriver");
                conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");

                String sql;
                if (searchParam != null) {
                    sql = "SELECT FULL_NAME, USER_NAME, EMAIL, MOBILE, PROFILE_PICTURE FROM REGISTERED_USERS " +
                          "WHERE ROLE = 'admin' AND (LOWER(FULL_NAME) LIKE ? OR LOWER(USER_NAME) LIKE ?)";
                } else {
                    sql = "SELECT FULL_NAME, USER_NAME, EMAIL, MOBILE, PROFILE_PICTURE FROM REGISTERED_USERS " +
                          "WHERE ROLE = 'admin'";
                }
                
                stmt = conn.prepareStatement(sql);

                if (searchParam != null) {
                    stmt.setString(1, searchParam);
                    stmt.setString(2, searchParam);
                }

                rs = stmt.executeQuery();
                
                if (!rs.isBeforeFirst() && searchParam != null) {
                    out.println("<tr><td colspan='5'>No admin users found with that name or username.</td></tr>");
                }

                while (rs.next()) {
                    String fullName = rs.getString("FULL_NAME");
                    String userName = rs.getString("USER_NAME");
                    String email = rs.getString("EMAIL");
                    String mobile = rs.getString("MOBILE");
                    Blob blob = rs.getBlob("PROFILE_PICTURE");
                    String base64Image = "";
                    if (blob != null) {
                        InputStream inputStream = blob.getBinaryStream();
                        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        while ((bytesRead = inputStream.read(buffer)) != -1) {
                            outputStream.write(buffer, 0, bytesRead);
                        }
                        byte[] adminImageBytes = outputStream.toByteArray();
                        base64Image = Base64.getEncoder().encodeToString(adminImageBytes);
                        inputStream.close();
                        outputStream.close();
                    }
        %>
        <tr>
            <td>
                <% if (!base64Image.equals("")) { %>
                    <img src="data:image/jpeg;base64,<%= base64Image %>" class="profile"/>
                <% } else { %>
                    <img src="images/default-profile.png" class="profile"/>
                <% } %>
            </td>
            <td><%= fullName %></td>
            <td><%= userName %></td>
            <td><%= email %></td>
            <td><%= mobile %></td>
        </tr>
        <%
                }
            } catch (Exception e) {
                out.println("<tr><td colspan='5' style='color: red;'>Database error: " + e.getMessage() + "</td></tr>");
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