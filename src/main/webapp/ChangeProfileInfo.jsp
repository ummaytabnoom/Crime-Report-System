<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>         
<%@ page import="java.io.*" %>          
<%@ page import="java.util.Base64" %>
<%@ page import="utils.DBConnection" %>   

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
// Use one connection block for both fetching profile data and picture
    try (Connection conn = DBConnection.getConnection();
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
// Use a separate connection for the update for clarity
            try (Connection conn = DBConnection.getConnection()) {

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
<meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="UTF-8">
    <title>Update Profile</title>
    
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-changeprofileinfo">
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