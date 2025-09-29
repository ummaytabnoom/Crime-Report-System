<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%
    String currentUser = (String) session.getAttribute("username");
    byte[] imageBytes = null;
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
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Police Dashboard</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-image: url("images/adminHome.jpg");
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
            height: 100vh;
            font-family: Arial, sans-serif;
            color: white;
        }

        .navbar {
            background-color: #FF8C00;
            color: white;
            padding: 14px 20px;
            display: flex;
            justify-content: space-between;
            align-items: center;
            position: relative;
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
            top: 20px;
            left: 87%;
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
        }

        .content {
            padding: 40px;
            text-align: center;
        }
        
        h2 {
        color: #222;
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
            .action-button {
        display: inline-block;
        padding: 30px 70px;
        background-color: #005F5F;
        color: white;
        text-decoration: none;
        border-radius: 80px;
        font-weight: bold;
        text-align: center;
        transition: all 0.3s ease;
        box-shadow: 0 4px 8px rgba(0,0,0,0.2);
    }

    .action-button:hover {
        background-color: #008080; /* lighter shade */
        transform: translateY(-3px);
        box-shadow: 0 6px 12px rgba(0,0,0,0.3);
    }
    </style>
</head>
<body>

    <!-- Navigation Bar -->
    <div class="navbar">
         <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>
        <div class="menu-icon" onclick="toggleMenu()">☰</div>

        <!-- Dropdown menu -->
        <div id="dropdownMenu" class="dropdown">
            <a href="SettingsForPolice.jsp">Settings</a>
            <a href="Logout.jsp">Logout</a>
        </div>
    </div>
    
    <div class="top-right-buttons">
        <a href="UserHomeForPolice.jsp">User Dashboard</a>
        
    </div>

    <!-- Main Content -->
    <div class="content">
        <h2>Welcome <span class="user-name" style="color: black;"><%= currentUser %></span> !</h2>

       
    </div>
    <div style="display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; margin-top: 20px;">
    <a href="StateUpgrade.jsp" class="action-button">Upgrade Report Status</a>
    <a href="AdminInfo.jsp" class="action-button">All Admin Information</a>
</div>
    
    <!-- JavaScript -->
    <script>
        function toggleMenu() {
            document.getElementById("dropdownMenu").classList.toggle("show");
        }

        // Close the dropdown when clicking outside
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
