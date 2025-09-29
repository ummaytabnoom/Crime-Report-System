<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>

<%
    // --- Get current user info for navbar ---
    Integer currentUserId = (Integer) session.getAttribute("userId"); // safer as Integer
    String currentUserName = "";
    byte[] imageBytes = null;
    String message = "";

    if (currentUserId != null) {
        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

            String sql = "SELECT USER_NAME, PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, currentUserId);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                currentUserName = rs.getString("USER_NAME");
                Blob blob = rs.getBlob("PROFILE_PICTURE");
                if (blob != null) {
                    try (InputStream is = blob.getBinaryStream(); ByteArrayOutputStream os = new ByteArrayOutputStream()) {
                        byte[] buffer = new byte[1024];
                        int bytesRead;
                        while ((bytesRead = is.read(buffer)) != -1) os.write(buffer, 0, bytesRead);
                        imageBytes = os.toByteArray();
                    }
                }
            } else {
                message = "User not found.";
            }

            rs.close();
            stmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            message = "Error loading user data: " + e.getMessage();
        }
    } else {
        message = "User is not logged in.";
    }

    // --- Handle update/delete actions ---
    if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("action") != null) {
        String action = request.getParameter("action");
        int id = Integer.parseInt(request.getParameter("id"));

        try {
            Class.forName("oracle.jdbc.driver.OracleDriver");
            Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

            if ("update".equals(action)) {
                String newRole = request.getParameter("newRole");
                String updateSQL = "UPDATE REGISTERED_USERS SET ROLE = ? WHERE ID = ?";
                PreparedStatement pstmt = conn.prepareStatement(updateSQL);
                pstmt.setString(1, newRole);
                pstmt.setInt(2, id);
                pstmt.executeUpdate();
                pstmt.close();
            } else if ("delete".equals(action)) {
                String deleteSQL = "DELETE FROM REGISTERED_USERS WHERE ID = ?";
                PreparedStatement pstmt = conn.prepareStatement(deleteSQL);
                pstmt.setInt(1, id);
                pstmt.executeUpdate();
                pstmt.close();
            }

            conn.close();
        } catch (Exception e) {
            out.println("<p style='color:red;'>Action Error: " + e.getMessage() + "</p>");
        }
    }

    // --- Get search query ---
    String searchQuery = request.getParameter("search");
%>

<!DOCTYPE html>
<html>
<head>
    <title>Admin Panel - User Management</title>
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

        .dropdown a:hover {
            background-color: #f2f2f2;
        }

        .show {
            display: flex;
        }

        .top-right-buttons {
            position: absolute;
            top: 30px;
            left: 58%;
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

        th {
            background-color: #FFA500;
            color: white;
        }

        tr:nth-child(even) {
            background-color: #f9f9f9;
        }

        select, input[type="submit"] {
            padding: 6px 10px;
            border-radius: 4px;
            border: none;
        }

        .btn-change {
            background-color: #007BFF;
            color: white;
            cursor: pointer;
        }

        .btn-delete {
            background-color: red;
            color: white;
            cursor: pointer;
        }

        img.profile {
            width: 80px;
            height: 80px;
            object-fit: cover;
            border-radius: 50%;
        }

        h2 {
            text-align: center;
            margin-bottom: 20px;
            color: #333;
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

        .user-pic:hover {
            transform: scale(1.1);
        }

        .user-name {
            font-size: 16px;
            font-weight: bold;
            color: white;
            letter-spacing: 0.5px;
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
    </style>
</head>
<body>

<div class="navbar">
    <div class="navbar-title">
        <div class="user-info">
            <% 
                if (imageBytes != null && imageBytes.length > 0) { 
                    String base64Image = Base64.getEncoder().encodeToString(imageBytes);
            %>
                <img src="data:image/jpeg;base64,<%= base64Image %>" alt="Profile Picture" class="user-pic">
            <% } else { %>
                <img src="images/default_profile.png" alt="Default Profile Picture" class="user-pic">
            <% } %>
            <span class="user-name">Hello, <%= currentUserName %></span>
        </div>
    </div>
        
    <div class="top-right-buttons">
        <a href="AdminsHome.jsp">Admin Dashboard</a>
        <a href="ReportMan.jsp">Crime Report Management</a>
        <a href="UserHomeForAdmin.jsp">User Dashboard</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="SettingsForAdmin.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
    <h2>User Management Panel</h2>

    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name" value="<%= (searchQuery != null) ? searchQuery : "" %>" />
            <button type="submit">Search</button>
            <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                <button type="button" onclick="window.location='UserManage.jsp'">Clear</button>
            <% } %>
        </form>
    </div>

<%
    // --- Fetch user list ---
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
        Class.forName("oracle.jdbc.driver.OracleDriver");
        conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");

        String sql;
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            sql = "SELECT ID, FULL_NAME, USER_NAME, EMAIL, DOB, MOBILE, ROLE, PROFILE_PICTURE FROM REGISTERED_USERS WHERE LOWER(FULL_NAME) LIKE ? OR LOWER(USER_NAME) LIKE ?";
            pstmt = conn.prepareStatement(sql);
            String pattern = "%" + searchQuery.toLowerCase() + "%";
            pstmt.setString(1, pattern);
            pstmt.setString(2, pattern);
        } else {
            sql = "SELECT ID, FULL_NAME, USER_NAME, EMAIL, DOB, MOBILE, ROLE, PROFILE_PICTURE FROM REGISTERED_USERS";
            pstmt = conn.prepareStatement(sql);
        }

        rs = pstmt.executeQuery();
%>

    <table>
        <tr>
            <th>Profile</th>
            <th>Full Name</th>
            <th>Username</th>
            <th>Email</th>
            <th>DOB</th>
            <th>Mobile</th>
            <th>Role</th>
            <th>Change Role</th>
            <th>Delete</th>
        </tr>

<%
    while (rs.next()) {
        int id = rs.getInt("ID");
        String fullName = rs.getString("FULL_NAME");
        String userName = rs.getString("USER_NAME");
        String email = rs.getString("EMAIL");
        Date dob = rs.getDate("DOB");
        String mobile = rs.getString("MOBILE");
        String role = rs.getString("ROLE");
        Blob blob = rs.getBlob("PROFILE_PICTURE");
        String base64Image = "";

        if (blob != null) {
            try (InputStream is = blob.getBinaryStream(); ByteArrayOutputStream os = new ByteArrayOutputStream()) {
                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) os.write(buffer, 0, bytesRead);
                base64Image = Base64.getEncoder().encodeToString(os.toByteArray());
            } catch (Exception ex) { base64Image = ""; }
        }
%>
        <tr>
            <td>
                <% if (!base64Image.equals("")) { %>
                    <img src="data:image/jpeg;base64,<%= base64Image %>" class="profile" />
                <% } else { %>
                    No Image
                <% } %>
            </td>
            <td><%= fullName %></td>
            <td><%= userName %></td>
            <td><%= email %></td>
            <td><%= dob %></td>
            <td><%= mobile %></td>
            <td><%= role %></td>
            <td>
                <form method="post" class="inline">
                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="action" value="update">
                    <select name="newRole">
                        <option value="public" <%= "public".equals(role)?"selected":"" %>>Public</option>
                        <option value="admin" <%= "admin".equals(role)?"selected":"" %>>Admin</option>
                        <option value="police" <%= "police".equals(role)?"selected":"" %>>Police</option>
                    </select>
                    <input type="submit" value="Change" class="btn-change">
                </form>
            </td>
            <td>
                <form method="post" class="inline" onsubmit="return confirm('Are you sure to delete?');">
                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="action" value="delete">
                    <input type="submit" value="Delete" class="btn-delete">
                </form>
            </td>
        </tr>
<% } %>
    </table>

<%
    } catch (Exception e) { out.println("<p style='color:red;'>Database Error: " + e.getMessage() + "</p>"); }
    finally {
        if(rs != null) try{rs.close();} catch(Exception ignored){}
        if(pstmt != null) try{pstmt.close();} catch(Exception ignored){}
        if(conn != null) try{conn.close();} catch(Exception ignored){}
    }
%>
</div>

<script>
    function toggleMenu() {
        var menu = document.getElementById("dropdownMenu");
        menu.classList.toggle("show");
    }

    window.onclick = function(event) {
        if (!event.target.matches('.menu-icon')) {
            var dropdowns = document.getElementsByClassName("dropdown");
            for (var i = 0; i < dropdowns.length; i++) {
                dropdowns[i].classList.remove("show");
            }
        }
    }
</script>

</body>
</html>
