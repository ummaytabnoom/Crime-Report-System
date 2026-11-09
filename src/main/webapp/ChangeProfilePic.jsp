<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.util.*" %>         
<%@ page import="java.io.*" %>          
<%@ page import="java.util.Base64" %>   
<%@ page import="utils.PasswordUtil" %>
<%@ page import="utils.DBConnection" %> <%-- 1. IMPORT YOUR UTILITY CLASS --%>

<%
    String message = "";
    // 1. Get user data from session
    Integer currentUserId = (Integer) session.getAttribute("userId");
    String currentUserName = (String) session.getAttribute("username");

    if (currentUserId == null || currentUserName == null) {
        response.sendRedirect("Login.jsp");
        return;
    }

    // 2. Handle File Upload
    if (request.getMethod().equalsIgnoreCase("POST") && 
        request.getContentType() != null && 
        request.getContentType().startsWith("multipart/form-data")) {
        
        try {
            org.apache.commons.fileupload.servlet.ServletFileUpload upload = new org.apache.commons.fileupload.servlet.ServletFileUpload(new org.apache.commons.fileupload.disk.DiskFileItemFactory());
            java.util.List<org.apache.commons.fileupload.FileItem> items = upload.parseRequest(request);
            
            for (org.apache.commons.fileupload.FileItem item : items) {
                if (!item.isFormField() && item.getFieldName().equals("profilePic")) {
                    byte[] fileBytes = item.get();
                    
                    try (Connection conn = DBConnection.getConnection();
                         PreparedStatement stmt = conn.prepareStatement("UPDATE REGISTERED_USERS SET PROFILE_PICTURE = ? WHERE ID = ?")) {
                        stmt.setBytes(1, fileBytes);
                        stmt.setInt(2, currentUserId);
                        stmt.executeUpdate();
                        message = "Profile picture updated successfully!";
                    }
                }
            }
        } catch (Exception e) {
            message = "Error uploading file: " + e.getMessage();
        }
    }

    // 3. Fetch Profile Picture
    byte[] imageBytes = null;
    try {
try (Connection conn = DBConnection.getConnection();
             PreparedStatement stmt = conn.prepareStatement("SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID=?")) {
            stmt.setInt(1, currentUserId);
            try (ResultSet rs = stmt.executeQuery()) {
                if (rs.next()) {
                    java.sql.Blob blob = rs.getBlob("PROFILE_PICTURE");
                    if (blob != null) {
                        imageBytes = blob.getBytes(1, (int) blob.length());
                    }
                }
            }
        }
    } catch (Exception e) {
        System.out.println("Error fetching picture: " + e.getMessage());
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
<body class="modern page-changeprofilepic">
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
    <% if (!message.isEmpty()) { %>
        <div class="message"><%= message %></div>
    <% } %>

    
    <h2>Change Profile Picture</h2>

    <div class="profile-section">

    <% if (imageBytes != null) { %>
            <img id="preview" class="preview-img" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" />
        <% } else { %>
            <img id="preview" class="preview-img" src="images/default.png" />
        <% } %>

        <form method="post" enctype="multipart/form-data">
            <label>Select New Profile Picture:</label>
            <input type="file" name="profilePic" accept="image/*" required onchange="previewImage(event)" />
            <br><br>
            <input type="submit" value="Upload">
        </form>

    <div class="back-link">
        <a href="Settings.jsp">Back to Settings</a>
    </div>
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
</script>
</body>
</html>