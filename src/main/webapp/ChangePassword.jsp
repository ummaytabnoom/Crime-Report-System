<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>         
<%@ page import="java.io.*" %>          
<%@ page import="java.util.Base64" %>   
<%@ page import="utils.PasswordUtil" %>
<%@ page import="utils.DBConnection" %> <%-- 1. IMPORT YOUR UTILITY CLASS --%>

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
// Using try-with-resources for automatic resource closing
        try (Connection conn = DBConnection.getConnection();
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
// Using a separate try-with-resources for the update logic
                try (Connection conn = DBConnection.getConnection()) {

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
<meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="UTF-8" />
    <link
      rel="stylesheet"
      href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css"
    />

    <title>Change Password</title>
    
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-changepassword">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>


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

<div class="form-panel">
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