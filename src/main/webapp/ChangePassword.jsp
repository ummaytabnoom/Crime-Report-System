<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.OracleDriver" %>
<%@ page import="java.util.*" %>         
<%@ page import="java.io.*" %>          
<%@ page import="java.util.Base64" %>   
<%@ page import="utils.PasswordUtil" %> <%-- 1. IMPORT YOUR UTILITY CLASS --%>

<%
    String message = "";
    // Get user data from session
    Integer currentUserId = (Integer) session.getAttribute("userId");
    String currentUserName = (String) session.getAttribute("username");

    if (currentUserId == null || currentUserName == null) {
        response.sendRedirect("Login.jsp"); // Redirect to your Login page
        return; // Stop further execution
    }

    byte[] imageBytes = null;
    
    // --- 1. FETCH PROFILE PICTURE (Runs on every page load) ---
    try {
        Class.forName("oracle.jdbc.OracleDriver");
        
        // Using try-with-resources for automatic resource closing
        try (Connection conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");
             PreparedStatement stmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID=?")) {
            
            stmt.setInt(1, currentUserId);
            
            try (ResultSet rs = stmt.executeQuery()) {
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
                            imageBytes = os.toByteArray();
                        }
                    }
                }
            }
        }
    } catch (Exception e) {
        // Log error but allow page to load without a profile picture
        System.out.println("Error fetching profile picture: " + e.getMessage());
    }
    
    // --- 2. HANDLE FORM SUBMISSION (Password Change) ---
    String oldPassword = request.getParameter("oldPassword");
    String newPassword = request.getParameter("newPassword");
    String confirmPassword = request.getParameter("confirmPassword");
    
    // Check if the form was actually submitted (parameters are not null)
    if (oldPassword != null && newPassword != null && confirmPassword != null) {

        if (!newPassword.equals(confirmPassword)) {
            message = "New password and rewrite password do not match.";
        } else {
            try {
                Class.forName("oracle.jdbc.OracleDriver");
                
                // Using a separate try-with-resources for the update logic
                try (Connection conn = DriverManager.getConnection(
                    "jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345")) {

                    // Step A: Hash the user's OLD password input for verification
                    String hashedOldPasswordInput = PasswordUtil.hashPassword(oldPassword);
                    
                    String checkSql = "SELECT PASSWORD FROM REGISTERED_USERS WHERE ID = ?";
                    try (PreparedStatement checkStmt = conn.prepareStatement(checkSql)) {
                        checkStmt.setInt(1, currentUserId);
                        
                        try (ResultSet rs = checkStmt.executeQuery()) {

                            if (rs.next()) {
                                String dbHashedPassword = rs.getString("PASSWORD");

                                // 2. COMPARE the hashed user input with the database hash
                                if (dbHashedPassword.equals(hashedOldPasswordInput)) {
                                    
                                    // 3. HASH the NEW password before storing it
                                    String hashedNewPassword = PasswordUtil.hashPassword(newPassword);
                                    
                                    // Step B: Update New Password
                                    String updateSql = "UPDATE REGISTERED_USERS SET PASSWORD = ? WHERE ID = ?";
                                    try (PreparedStatement updateStmt = conn.prepareStatement(updateSql)) {
                                        updateStmt.setString(1, hashedNewPassword); // Store the HASH
                                        updateStmt.setInt(2, currentUserId);

                                        int rowsUpdated = updateStmt.executeUpdate();

                                        if (rowsUpdated > 0) {
                                            // Redirect after success 
                                            response.sendRedirect("Settings.jsp?msg=password_updated");
                                            return; 
                                        } else {
                                            message = "Error updating password.";
                                        }
                                    }

                                } else {
                                    // Error message for failed old password check
                                    message = "Present password is incorrect.";
                                }
                            } else {
                                message = "User not found.";
                            }
                        }
                    }
                } // Connection conn closed automatically
                // The Hashing utility might throw an exception (e.g., if the algorithm name is wrong)
            } catch (Exception e) { 
                message = "An error occurred during password update: " + e.getMessage();
                System.out.println("Password Change Error: " + e.getMessage());
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <link
      rel="stylesheet"
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
    />

    <title>Change Password</title>
    <style>
            body {
            margin: 0;
            padding: 0;
            height: 100vh;
            font-family: Arial, sans-serif;
            background: url("images/settingsBackground.jpg") no-repeat center center fixed;
            background-size: cover;
            /* Added for container centering */
            display: flex;
            flex-direction: column;
            align-items: center;
            color: white;
        }
        .navbar {
            width: 100%;
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
.container {
    background: #fff;
    padding: 40px;
    border-radius: 10px;
    width: 400px;
    box-shadow: 0 0 10px rgba(0,0,0,0.2);
    /* Increased margin-top for gap below navbar (60px = navbar height + desired gap) */
    margin-top: 60px; 
    margin-bottom: 45px; 
}
        h2 {
            text-align: center;
            color: #333;
        }
        form {
            margin-top: 20px;
        }
        label {
            font-weight: bold;
            display: block;
            margin-bottom: 5px;
            color: #333; 
        }
        .input-wrapper {
            position: relative;
            margin-bottom: 20px;
        }
        input[type="password"], input[type="text"] {
            width: 100%;
            padding: 10px 40px 10px 10px; 
            border-radius: 5px;
            border: 1px solid #ccc;
            box-sizing: border-box;
            font-size: 16px;
        }
        .toggle-icon {
            position: absolute;
            right: 12px;
            top: 70%; 
            transform: translateY(-50%);
            cursor: pointer;
            font-size: 20px;
            color: #555;
            user-select: none;
            transition: color 0.3s ease;
        }
        .toggle-icon:hover {
            color: #FF8C00;
        }
        input[type="submit"] {
            width: 100%;
            padding: 12px;
            background-color: #FF8C00;
            border: none;
            color: white;
            font-size: 16px;
            border-radius: 5px;
            cursor: pointer;
        }
        input[type="submit"]:hover {
            background-color: #e67e00;
        }
        .message {
            text-align: center;
            font-weight: bold;
            color: <%= message.contains("successfully") ? "green" : "red" %>;
            margin-bottom: 15px;
        }
        .back-link {
            text-align: center;
            margin-top: 15px;
        }
        .back-link a {
            text-decoration: none;
            padding: 10px 20px;
            background-color: #005F5F;
            color: white;
            border-radius: 5px;
        }
        .back-link a:hover {
            background-color: #004040;
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
        <span class="user-name"><%= currentUserName %></span>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="container">
    <h2>Change Password</h2>

    <% if (!message.isEmpty()) { %>
        <div class="message"><%= message %></div>
    <% } %>

    <form method="post">
        <div class="input-wrapper">
            <label for="oldPassword">Present Password:</label>
            <input type="password" id="oldPassword" name="oldPassword" required />
            <i
                id="toggleIconOld"
                class="fa-solid fa-eye toggle-icon"
                onclick="togglePassword('oldPassword', 'toggleIconOld')"
                title="Show/Hide Present Password"
            ></i>
        </div>

        <div class="input-wrapper">
            <label for="newPassword">New Password:</label>
            <input type="password" id="newPassword" name="newPassword" required />
            <i
                id="toggleIconNew"
                class="fa-solid fa-eye toggle-icon"
                onclick="togglePassword('newPassword', 'toggleIconNew')"
                title="Show/Hide New Password"
            ></i>
        </div>

        <div class="input-wrapper">
            <label for="confirmPassword">Rewrite Password:</label>
            <input type="password" id="confirmPassword" name="confirmPassword" required />
            <i
                id="toggleIconConfirm"
                class="fa-solid fa-eye toggle-icon"
                onclick="togglePassword('confirmPassword', 'toggleIconConfirm')"
                title="Show/Hide Rewritten Password"
            ></i>
        </div>

        <input type="submit" value="Change Password" />
    </form>
    <div class="back-link">
        <a href="Settings.jsp">Back to Settings</a>
    </div>
</div>

<script>
function togglePassword(inputId, iconId) {
    const pwdField = document.getElementById(inputId);
    const toggleIcon = document.getElementById(iconId);

    if (pwdField.type === "password") {
        pwdField.type = "text";
        toggleIcon.classList.remove("fa-eye");
        toggleIcon.classList.add("fa-eye-slash");
    } else {
        pwdField.type = "password";
        toggleIcon.classList.remove("fa-eye-slash");
        toggleIcon.classList.add("fa-eye");
    }
}

function toggleMenu() {
    document.getElementById("dropdownMenu").classList.toggle("show");
}

/* This function was unused and is removed to keep the code clean */
/* function filterCrimes() {
    const input = document.getElementById("searchInput").value.toLowerCase();
    const containers = document.getElementsByClassName("crime-container");
    for (let i = 0; i < containers.length; i++) {
        const locationElement = containers[i].querySelector(".crime-location");
        containers[i].style.display = locationElement.innerText.toLowerCase().includes(input) ? "block" : "none";
    }
} */
</script>
</body>
</html>