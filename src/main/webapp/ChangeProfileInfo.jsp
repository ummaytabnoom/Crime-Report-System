<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.OracleDriver" %>
<%@ page import="java.util.*" %>         
<%@ page import="java.io.*" %>          
<%@ page import="java.util.Base64" %>   

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
String currentFullName = "";
String currentEmail = "";
String currentMobile = "";

// --- 1. FETCH PROFILE DATA AND PICTURE ---
try {
    Class.forName("oracle.jdbc.OracleDriver");
    
    // Use one connection block for both fetching profile data and picture
    try (Connection conn = DriverManager.getConnection(
            "jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");
         PreparedStatement stmt = conn.prepareStatement(
            "SELECT PROFILE_PICTURE, FULL_NAME, EMAIL, MOBILE FROM REGISTERED_USERS WHERE ID=?")) {
        
        stmt.setInt(1, currentUserId);
        
        try (ResultSet rs = stmt.executeQuery()) {
            if (rs.next()) {
                // Fetch text data to pre-fill the form
                currentFullName = rs.getString("FULL_NAME");
                currentEmail = rs.getString("EMAIL");
                currentMobile = rs.getString("MOBILE");

                // Fetch image data
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
    System.out.println("Error fetching user data: " + e.getMessage());
}
    
// --- 2. HANDLE FORM SUBMISSION (Only process if it's a POST request) ---
if ("POST".equalsIgnoreCase(request.getMethod())) {

    // Get inputs from the form (these will be the new values)
    String newFullName = request.getParameter("fullName");
    String newEmail = request.getParameter("email");
    String newMobile = request.getParameter("mobile");

    // Re-validate input data
    if (newFullName == null || newEmail == null || newMobile == null) {
        message = "Error: All fields are required.";
    } else {
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            
            // Use a separate connection for the update for clarity
            try (Connection conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345")) {

                String sql = "UPDATE REGISTERED_USERS SET FULL_NAME = ?, EMAIL = ?, MOBILE = ? WHERE ID = ?";
                
                try (PreparedStatement updateStmt = conn.prepareStatement(sql)) {
                    updateStmt.setString(1, newFullName);
                    updateStmt.setString(2, newEmail);
                    updateStmt.setString(3, newMobile);
                    updateStmt.setInt(4, currentUserId);

                    int rowsUpdated = updateStmt.executeUpdate();

                    if (rowsUpdated > 0) {
                        message = "Profile updated successfully.";
                        
                        // Update the session with the new full name (if used for display)
                        session.setAttribute("username", newFullName);
                        currentUserName = newFullName;
                        
                        // Update the current variables so the form reloads with the new data
                        currentFullName = newFullName;
                        currentEmail = newEmail;
                        currentMobile = newMobile;

                    } else {
                        message = "Failed to update profile.";
                    }
                }
            }
        } catch (Exception e) {
            message = "Error: " + e.getMessage();
            e.printStackTrace();
        }
    }
}
%>

<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Update Profile</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            height: 100vh;
            font-family: Arial, sans-serif;
            background: url("images/settingsBackground.jpg") no-repeat center center fixed;
            background-size: cover;
            color: white;
            /* Added for container centering below navbar */
            display: flex; 
            flex-direction: column;
            align-items: center;
        }
        .navbar {
            width: 100%; /* Ensure navbar spans full width */
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
            /* Matching the margin from your last provided CSS */
            margin-top: 45px; 
            margin-bottom: 45px;
        }
        h2 {
            text-align: center;
            color: #333;
            /* Added bottom border for visual separation, typical for update forms */
            border-bottom: 2px solid #FFA500; 
            padding-bottom: 10px;
        }
        form {
            margin-top: 20px;
        }
        label {
            font-weight: bold;
            display: block;
            margin-bottom: 5px;
            color: #333; /* Ensure label text is visible */
        }
        /* Style for all text/email/number inputs in the form */
        input[type="text"],
        input[type="email"],
        input[type="date"],
        select {
            width: 100%;
            padding: 10px;
            margin: 6px 0 15px 0;
            border: 1px solid #ccc;
            border-radius: 5px;
            box-sizing: border-box; /* Crucial for 100% width compatibility */
            font-size: 16px;
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
            margin-bottom: 15px;
            color: <%= message.contains("successfully") ? "green" : "red" %>;
        }
        .error {
            color: red;
        }
        .success {
            color: green;
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
    <h2>Update Your Profile</h2>

    <% if (!message.isEmpty()) { %>
        <p class="message <%= message.contains("Error") || message.contains("Failed") ? "error" : "success" %>">
            <%= message %>
        </p>
    <% } %>

    <form method="post">
        
        <label for="fullName">Change Full Name:</label>
        <input type="text" id="fullName" name="fullName" value="<%= currentFullName %>" required />

        <label for="email">Change Email:</label>
        <input type="email" id="email" name="email" value="<%= currentEmail %>" required />

        <label for="mobile">Change Mobile No:</label>
        <input type="text" id="mobile" name="mobile" value="<%= currentMobile %>" pattern="01[0-9]{9}" required />

        <input type="submit" value="Update Profile Information">
    </form>

    <div class="back-link">
        <a href="Settings.jsp">Back to Settings</a>
    </div>
</div>
<script>
function toggleMenu() {
    document.getElementById("dropdownMenu").classList.toggle("show");
}
</script>
</body>
</html>