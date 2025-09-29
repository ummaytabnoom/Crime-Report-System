<%@ page language="java" contentType="text/html; charset=UTF-8" %>
<%@ page import="java.sql.*" %>
<%@ page import="oracle.jdbc.OracleDriver" %>

<%
    String message = "";

    String currentUser = (String) session.getAttribute("username");
    System.out.println("Current user from session: " + currentUser);

    String oldPassword = request.getParameter("oldPassword");
    String newPassword = request.getParameter("newPassword");
    String confirmPassword = request.getParameter("confirmPassword");

    if (currentUser == null) {
        message = "Session expired. Please log in again.";
    } else if (oldPassword == null || newPassword == null || confirmPassword == null) {
        message = "Please fill all password fields.";
    } else if (!newPassword.equals(confirmPassword)) {
        message = "New password and confirm password do not match.";
    } else {
        try {
            Class.forName("oracle.jdbc.OracleDriver");
            Connection conn = DriverManager.getConnection(
                "jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345"
            );

            String checkSql = "SELECT PASSWORD FROM REGISTERED_USERS WHERE USER_NAME = ?";
            PreparedStatement checkStmt = conn.prepareStatement(checkSql);
            checkStmt.setString(1, currentUser);
            ResultSet rs = checkStmt.executeQuery();

            if (rs.next()) {
                String dbPassword = rs.getString("PASSWORD");

                if (dbPassword.equals(oldPassword)) {
                    String updateSql = "UPDATE REGISTERED_USERS SET PASSWORD = ? WHERE USER_NAME = ?";
                    PreparedStatement updateStmt = conn.prepareStatement(updateSql);
                    updateStmt.setString(1, newPassword);
                    updateStmt.setString(2, currentUser);

                    int rowsUpdated = updateStmt.executeUpdate();

                    updateStmt.close();
                    conn.close();
                    checkStmt.close();
                    rs.close();

                    if (rowsUpdated > 0) {
                        response.sendRedirect("Settings.jsp");
                        return;
                    } else {
                        message = "Error updating password.";
                    }

                } else {
                    message = "Old password is incorrect.";
                }
            } else {
                message = "User not found.";
            }

            rs.close();
            checkStmt.close();
            conn.close();

        } catch (Exception e) {
            message = "Error: " + e.getMessage();
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
            font-family: Arial, sans-serif;
            background-color: #FFE4B5;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
        }
        .container {
            background: #fff;
            padding: 40px;
            border-radius: 10px;
            width: 400px;
            box-shadow: 0 0 10px rgba(0,0,0,0.2);
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
        }
        .input-wrapper {
            position: relative;
            margin-bottom: 20px;
        }
        input[type="password"], input[type="text"] {
            width: 100%;
            padding: 10px 40px 10px 10px; /* leave right padding for icon */
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
    </style>
</head>
<body>
<div class="container">
    <h2>Change Password</h2>

    <% if (!message.isEmpty()) { %>
        <div class="message"><%= message %></div>
    <% } %>

    <form method="post">
        <div class="input-wrapper">
            <label for="oldPassword">Old Password:</label>
            <input type="password" id="oldPassword" name="oldPassword" required />
            <i
                id="toggleIconOld"
                class="fa-solid fa-eye toggle-icon"
                onclick="togglePassword('oldPassword', 'toggleIconOld')"
                title="Show/Hide password"
            ></i>
        </div>

        <div class="input-wrapper">
            <label for="newPassword">New Password:</label>
            <input type="password" id="newPassword" name="newPassword" required />
            <i
                id="toggleIconNew"
                class="fa-solid fa-eye toggle-icon"
                onclick="togglePassword('newPassword', 'toggleIconNew')"
                title="Show/Hide password"
            ></i>
        </div>

        <div class="input-wrapper">
            <label for="confirmPassword">Confirm New Password:</label>
            <input type="password" id="confirmPassword" name="confirmPassword" required />
            <i
                id="toggleIconConfirm"
                class="fa-solid fa-eye toggle-icon"
                onclick="togglePassword('confirmPassword', 'toggleIconConfirm')"
                title="Show/Hide password"
            ></i>
        </div>

        <input type="submit" value="Change Password" />
    </form>
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
</script>
</body>
</html>
