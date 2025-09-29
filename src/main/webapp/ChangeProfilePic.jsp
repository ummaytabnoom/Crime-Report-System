<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="java.util.List" %>
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*" %>

<%
    request.setCharacterEncoding("UTF-8");
    boolean isMultipart = ServletFileUpload.isMultipartContent(request);

    String currentUser = (String) session.getAttribute("username");
    byte[] imageBytes = null;
    String message = "";
    byte[] fileBytes = null;

    if (isMultipart && request.getMethod().equalsIgnoreCase("POST")) {
        DiskFileItemFactory factory = new DiskFileItemFactory();
        ServletFileUpload upload = new ServletFileUpload(factory);

        try {
            List<FileItem> items = upload.parseRequest(request);
           

            for (FileItem item : items) {
                if (!item.isFormField() && item.getFieldName().equals("profilePic")) {
                    InputStream fileContent = item.getInputStream();

                    // Convert InputStream to byte[]
                    ByteArrayOutputStream buffer = new ByteArrayOutputStream();
                    byte[] temp = new byte[1024];
                    int bytesRead;
                    while ((bytesRead = fileContent.read(temp)) != -1) {
                        buffer.write(temp, 0, bytesRead);
                    }
                    fileBytes = buffer.toByteArray();

                    fileContent.close();
                }
            }

            if (fileBytes != null && currentUser != null) {
                Class.forName("oracle.jdbc.OracleDriver");
                Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

                String updateSQL = "UPDATE REGISTERED_USERS SET PROFILE_PICTURE = ? WHERE USER_NAME = ?";
                PreparedStatement pstmt = conn.prepareStatement(updateSQL);
                pstmt.setBytes(1, fileBytes);
                pstmt.setString(2, currentUser);

                int row = pstmt.executeUpdate();
                if (row > 0) {
                    message = "Profile picture updated successfully.";
                    response.sendRedirect("ChangeProfilePic.jsp");
                } else {
                    message = "Failed to update profile picture.";
                }

                pstmt.close();
                conn.close();
            }
        } catch (Exception e) {
            e.printStackTrace();
            message = "Error uploading file: " + e.getMessage();
        }
    }

    // Load current profile picture
    if (currentUser != null) {
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
            message = "Error loading profile picture: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Change Profile Picture</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #FAFAD2;
            display: flex;
            justify-content: center;
            align-items: center;
            height: 100vh;
        }
        .container {
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            width: 500px;
            box-shadow: 0px 0px 10px rgba(0,0,0,0.1);
        }
        h2 {
            text-align: center;
            color: #333;
            border-bottom: 2px solid #FFA500;
            padding-bottom: 10px;
        }
        label {
            font-weight: bold;
            margin-top: 10px;
        }
        input[type="file"] {
            width: 100%;
            padding: 12px;
            margin-top: 5px;
            margin-bottom: 15px;
            border-radius: 5px;
            border: 1px solid #ccc;
        }
        input[type="submit"] {
            background-color: #FFA500;
            color: white;
            border: none;
            padding: 12px;
            width: 100%;
            border-radius: 5px;
            font-size: 16px;
        }
        input[type="submit"]:hover {
            background-color: #e68a00;
        }
        .message {
            text-align: center;
            font-weight: bold;
            color: green;
            margin-bottom: 15px;
        }
        .error {
            color: red;
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
        .preview-img {
            display: block;
            margin: 0 auto 20px auto;
            max-width: 200px;
            height: auto;
            border: 2px solid #ccc;
            border-radius: 5px;
        }
    </style>
</head>
<body>
<div class="container">
    <h2>Change Profile Picture</h2>

    <% if (!message.isEmpty()) { %>
        <div class="message <%= message.contains("Error") || message.contains("Failed") ? "error" : "" %>">
            <%= message %>
        </div>
    <% } %>

    <% if (imageBytes != null) { %>
        <img class="preview-img" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" />
    <% } else { %>
        <p class="message">No profile picture uploaded.</p>
    <% } %>

    <form method="post" enctype="multipart/form-data">
        <label>Select New Profile Picture:</label>
        <input type="file" name="profilePic" accept="image/*" required />
        <input type="submit" value="Upload">
    </form>

    <div class="back-link">
        <a href="Settings.jsp">Back to Settings</a>
    </div>
</div>
</body>
</html>
