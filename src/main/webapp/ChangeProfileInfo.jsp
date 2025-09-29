<%@ page import="java.sql.*" %>
<%@ page import="javax.servlet.*" %>
<%@ page import="javax.servlet.http.*" %>
<%@ page import="oracle.jdbc.OracleDriver" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>

<%
    String message = "";
    String currentUser = (String) session.getAttribute("username");
    System.out.println("Current user from session: " + currentUser);

    // Only process the form if it's a POST request
    if ("POST".equalsIgnoreCase(request.getMethod())) {

        // Step 2: Get inputs from the form
        String fullName = request.getParameter("fullName");
        String email = request.getParameter("email");
        String mobile = request.getParameter("mobile");

        if (currentUser == null) {
            message = "Error: Session expired. Please log in again.";
        } else {
            try {
                Class.forName("oracle.jdbc.OracleDriver");
                Connection conn = DriverManager.getConnection(
                    "jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345"
                );

                String sql = "UPDATE REGISTERED_USERS SET FULL_NAME = ?, EMAIL = ?, MOBILE = ? WHERE USER_NAME = ?";
                PreparedStatement stmt = conn.prepareStatement(sql);

                stmt.setString(1, fullName);
                stmt.setString(2, email);
                stmt.setString(3, mobile);
                stmt.setString(4, currentUser);

                int rowsUpdated = stmt.executeUpdate();

                stmt.close();
                conn.close();

                if (rowsUpdated > 0) {
                    message = "Profile updated successfully.";
                } else {
                    message = "Failed to update profile.";
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
        input[type="text"], input[type="email"] {
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
            margin-bottom: 15px;
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
<div class="container">
    <h2>Update Your Profile</h2>

    <% if (!message.isEmpty()) { %>
        <p class="message <%= message.contains("Error") || message.contains("Failed") ? "error" : "success" %>">
            <%= message %>
        </p>
    <% } %>

    <form method="post" action="ChangeProfileInfo.jsp">
        <label>Full Name:</label>
        <input type="text" name="fullName" required>

        <label>Email:</label>
        <input type="email" name="email" required>

        <label>Mobile:</label>
        <input type="text" name="mobile" required>

        <input type="submit" value="Update Profile Information">
    </form>

    <div class="back-link">
        <a href="Settings.jsp">Back to Settings</a>
    </div>
</div>
</body>
</html>
