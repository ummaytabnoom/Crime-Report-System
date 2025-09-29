<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*, java.util.*" %>
<%@ page import="java.sql.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <title>Forget Password</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            height: 100vh;
            font-family: Arial, sans-serif;
            background-image: url("images/HomePagePic.jpg");
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
            display: flex;
            flex-direction: column;
        }
        nav {
            background-color: rgba(0, 0, 0, 0.7);
            padding: 20px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        nav .nav-left h2 {
            margin: 0;
            color: #fff;
        }
        nav .nav-right a {
            color: white;
            text-decoration: none;
            margin-left: 20px;
            padding: 8px 12px;
            border-radius: 4px;
            background-color: #005F5F;
            transition: background 0.3s;
        }
        nav .nav-right a:hover {
            background-color: #0056b3;
        }
        .login-wrapper {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: rgba(255, 255, 255, 0.2);
            padding: 20px;
        }
        .login-box {
            background: #E5CFFB;
            padding: 30px;
            border-radius: 10px;
            max-width: 400px;
            width: 100%;
        }
        h2 {
            text-align: center;
            color: black;
        }
        label {
            color: black;
            font-weight: bold;
        }
        input[type="text"], input[type="password"], input[type="email"], input[type="date"] {
            width: 100%;
            padding: 8px;
            margin-top: 5px;
            margin-bottom: 15px;
            border: none;
            border-radius: 4px;
        }
        input[type="submit"] {
            width: 100%;
            padding: 10px;
            background-color: #FF8C00;
            color: white;
            border: none;
            cursor: pointer;
            border-radius: 4px;
        }
        input[type="submit"]:hover {
            background-color: #e67300;
        }
        .message {
            text-align: center;
            font-weight: bold;
            margin-top: 20px;
        }
        .message.success {
            color: green;
        }
        .message.error {
            color: red;
        }
    </style>
</head>
<body>

<nav>
    <div class="nav-left">
        <h2>My Website : Forget Password</h2>
    </div>
    <div class="nav-right">
        <a href="MainHome.jsp">Home</a>
        <a href="Login.jsp">Login</a>
    </div>
</nav>

<div class="login-wrapper">
    <div class="login-box">
        <h2>Forgot Password</h2>

        <%
            String step = request.getParameter("step");
            if (step == null) step = "verify";

            if ("verify".equals(step)) {
        %>
            <form method="post" action="ForgotPassword.jsp?step=verifyProcess">
                <label>Full Name:</label>
                <input type="text" name="fullname" required>

                <label>User Name:</label>
                <input type="text" name="username" required>

                <label>Email:</label>
                <input type="email" name="email" required>

                <label>Date of Birth:</label>
                <input type="date" name="dob" required>

                <label>Mobile:</label>
                <input type="text" name="mobile" required>

                <label>Role:</label>
                <input type="text" name="role" required>

                <input type="submit" value="Verify Information">
            </form>
        <%
            } else if ("verifyProcess".equals(step)) {
                String fullname = request.getParameter("fullname");
                String username = request.getParameter("username");
                String email = request.getParameter("email");
                String dob = request.getParameter("dob");
                String mobile = request.getParameter("mobile");
                String role = request.getParameter("role");

                Connection conn = null;
                PreparedStatement pstmt = null;
                ResultSet rs = null;

                try {
                    Class.forName("oracle.jdbc.driver.OracleDriver");
                    conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

                    String sql = "SELECT * FROM REGISTERED_USERS " +
                                 "WHERE FULL_NAME=? AND USER_NAME=? AND EMAIL=? " +
                                 "AND DOB=TO_DATE(?, 'YYYY-MM-DD') AND MOBILE=? AND ROLE=?";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, fullname.trim());
                    pstmt.setString(2, username.trim());
                    pstmt.setString(3, email.trim());
                    pstmt.setString(4, dob.trim());
                    pstmt.setString(5, mobile.trim());
                    pstmt.setString(6, role.trim());

                    rs = pstmt.executeQuery();

                    if (rs.next()) {
                        session.setAttribute("resetUsername", username);
        %>
                        <p class="message success">Information verified! Please enter your new password.</p>
                        <form method="post" action="ForgotPassword.jsp?step=resetPassword">
                            <label for="newpassword">New Password:</label>
                            <div style="position: relative;">
                                <input type="password" id="password" name="newpassword" required>
                                <span onclick="togglePassword()" 
                                      style="position: absolute; right: 0px; top: 12px; cursor: pointer; font-size: 18px; color: #555;">
                                    <i id="toggleIcon" class="fa-solid fa-eye"></i>
                                </span>
                            </div>
                            <input type="submit" value="Update Password">
                        </form>

        <%
                    } else {
        %>
                        <p class="message error">Information does not match our records!</p>
                        <a href="ForgotPassword.jsp" style="display:block;text-align:center;color:#005F5F;">Try Again</a>
        <%
                    }
                } catch (Exception e) {
        %>
                    <p class="message error">Error: <%= e.getMessage() %></p>
        <%
                } finally {
                    try { if (rs != null) rs.close(); } catch (Exception e) {}
                    try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
                    try { if (conn != null) conn.close(); } catch (Exception e) {}
                }
            } else if ("resetPassword".equals(step)) {
                String newPass = request.getParameter("newpassword");
                String resetUser = (String) session.getAttribute("resetUsername");

                if (resetUser != null && newPass != null && !newPass.trim().isEmpty()) {
                    Connection conn = null;
                    PreparedStatement pstmt = null;
                    try {
                        Class.forName("oracle.jdbc.driver.OracleDriver");
                        conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

                        String updateSql = "UPDATE REGISTERED_USERS SET PASSWORD=? WHERE USER_NAME=?";
                        pstmt = conn.prepareStatement(updateSql);
                        pstmt.setString(1, newPass.trim());
                        pstmt.setString(2, resetUser.trim());
                        int updated = pstmt.executeUpdate();

                        if (updated > 0) {
                            session.removeAttribute("resetUsername");
        %>
                            <p class="message success">Password updated successfully! You can now <a href="Login.jsp">Login</a>.</p>
        <%
                        } else {
        %>
                            <p class="message error">Failed to update password.</p>
        <%
                        }
                    } catch (Exception e) {
        %>
                        <p class="message error">Error: <%= e.getMessage() %></p>
        <%
                    } finally {
                        try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
                        try { if (conn != null) conn.close(); } catch (Exception e) {}
                    }
                } else {
        %>
                    <p class="message error">Please enter a valid password to update.</p>
        <%
                }
            }
        %>
    </div>
</div>

<script>
function togglePassword() {
    const pwdField = document.getElementById("password");
    const toggleIcon = document.getElementById("toggleIcon");

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
