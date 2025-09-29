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
%><!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Settings Page</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-image: url("images/settingsBackground.jpg");
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
        }

        .navbar-title {
            font-size: 22px;
            font-weight: bold;
        }

        .menu-icon {
            font-size: 26px;
            background: none;
            border: none;
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

        .dropdown a:hover {
            background-color: #f2f2f2;
        }

        .show {
            display: flex;
        }

        .top-right-buttons {
            position: absolute;
            top: 25px;
            left: 90%;
            transform: translateX(-50%);
            display: flex;
            gap: 20px;
        }

        .top-right-buttons a {
            padding: 8px 12px;
            background-color: #005F5F;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-size: 14px;
            transition: background-color 0.3s;
        }

        .top-right-buttons a:hover {
            background-color: #004747;
        }

        .content {
            padding: 20px;
            background-color: rgba(255, 255, 255, 0.95);
            border-radius: 12px;
            max-width: 450px;
            margin: 80px auto;
            text-align: center;
            box-shadow: 0 6px 15px rgba(0, 0, 0, 0.25);
        }

        .card-section {
            background-color: #f9f9f9;
            border-radius: 8px;
            padding: 15px;
            margin-bottom: 20px;
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.1);
        }

        .card-section h2 {
            color: #333;
            margin-bottom: 10px;
            font-size: 18px;
        }

        .action-button {
            display: inline-block;
            padding: 10px 16px;
            background-color: #005F5F;
            color: white;
            text-decoration: none;
            border-radius: 5px;
            font-size: 14px;
            transition: all 0.3s ease;
        }

        .action-button:hover {
            background-color: #004040;
            transform: scale(1.05);
        }

        @media (max-width: 768px) {
            .top-right-buttons {
                left: 80%;
                flex-direction: column;
            }

            .content {
                margin: 20px;
                padding: 15px;
            }

            .action-button {
                width: 100%;
                font-size: 14px;
            }
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
    </style>
</head>
<body>

    <!-- Navbar -->
    <div class="navbar">
         <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>
        <button class="menu-icon" onclick="toggleMenu()">☰</button>
        <div id="dropdownMenu" class="dropdown">
            <a href="Settings.jsp">Settings</a>
            <a href="Logout.jsp">Logout</a>
        </div>
    </div>

    <!-- Top Right Button -->
    <div class="top-right-buttons">
        <a href="UserHome.jsp">User Dashboard</a>
    </div>

    <!-- Main Content -->
    <div class="content">
        <div class="card-section">
            <h2>Change your Profile Picture</h2>
            <a href="ChangeProfilePic.jsp" class="action-button">Change Profile Picture</a>
        </div>

        <div class="card-section">
            <h2>Change your Profile Information</h2>
            <a href="ChangeProfileInfo.jsp" class="action-button">Change Profile Information</a>
        </div>

        <div class="card-section">
            <h2>Change your Password</h2>
            <a href="ChangePassword.jsp" class="action-button">Change Password</a>
        </div>
    </div>

    <!-- JavaScript -->
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
        });
    </script>
</body>
</html>
