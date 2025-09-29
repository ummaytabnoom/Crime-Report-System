<%@ page import="java.sql.*, java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*, java.util.*" %>
<%@ page import="utils.PasswordUtil" %>

<!DOCTYPE html>
<html>
<head>
    <title>User Login</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    
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

        input[type="text"], input[type="password"] {
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

        .already-have-account {
            text-align: center;
            margin-top: 20px;
        }

        .already-have-account h3 {
            color: #333;
            margin-bottom: 10px;
        }

        .register-button {
            background-color: #005F5F;
            padding: 10px 20px;
            text-decoration: none;
            color: white;
            border-radius: 4px;
            display: inline-block;
            margin-top: 10px;
        }

        .register-button:hover {
            background-color: #004747;
        }
        
        /* Forgot Password link style */
.forgot-password {
    text-align: center;
    margin: 15px 0;
}

.forgot-password a {
    color: #005F5F;
    text-decoration: none;
    font-weight: bold;
    display: inline-flex;
    align-items: center;
    gap: 8px;
    transition: color 0.3s;
}

.forgot-password a:hover {
    color: #004747;
}

/* Icon styling */
.forgot-password i {
    font-size: 18px;
}
button[type="submit"] {
             display: block;
            margin: 25px auto 0;
            padding: 12px 25px;
            background-color: #FF8C00;
            color: white;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 16px;
        }
        button[type="submit"]:hover { background-color: #e67300; }
        .register-button {
            margin-top: 10px;
            background-color: #005F5F;
            padding: 10px 20px;
            font-size: 15px;
            font-weight: 500;
        }
        .register-button:hover { background-color: #004747; }
    </style>
</head>
<body>

<!-- Navbar -->
<nav>
    <div class="nav-left">
        <h2>My Website : Login Page</h2>
    </div>
    <div class="nav-right">
        <a href="MainHome.jsp">Home</a>
    </div>
</nav>

<div class="login-wrapper">
    <div class="login-box">
        <h2>User Login</h2>
        <form method="post" action="">
            <label for="username">User Name:</label>
            <input type="text" name="username" required>

            <label for="email">Email:</label>
            <input type="text" name="email" required>
             
            <label for="password">Password:</label>
<div style="position: relative;">
    <input type="password" id="password" name="password"  required>
    <span onclick="togglePassword()" 
          style="position: absolute; right: 0px; top: 12px; cursor: pointer; font-size: 18px; color: #555;">
        <i id="toggleIcon" class="fa-solid fa-eye"></i>
    </span>
       <button type="submit">Login</button>
</div>

	

        </form>
        
        <div class="forgot-password">
        <a href="ForgotPassword.jsp">Forgot Password?</a>
        </div>

        <div class="already-have-account">
            <h3>Not registered?</h3>
            <button onclick="location.href='Registration.jsp'" class="register-button">Register here</button>
        </div>

        <%
        

        if ("POST".equalsIgnoreCase(request.getMethod())) {
            String username = request.getParameter("username");
            String email = request.getParameter("email");
            String rawPassword = request.getParameter("password");
            String hashedPassword = PasswordUtil.hashPassword(rawPassword);
            System.out.println(hashedPassword);


            Connection conn = null;
            PreparedStatement pstmt = null;
            ResultSet rs = null;

                try {
                    Class.forName("oracle.jdbc.driver.OracleDriver");
                    conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");

                    String sql = "SELECT * FROM REGISTERED_USERS WHERE USER_NAME = ? AND EMAIL = ? AND PASSWORD = ? ";
                    pstmt = conn.prepareStatement(sql);
                    pstmt.setString(1, username.trim());
                    pstmt.setString(2, email.trim());
                    pstmt.setString(3, hashedPassword);
                    

                    rs = pstmt.executeQuery();

                    if (rs.next()) {
                    	session.setAttribute("userId", rs.getInt("ID"));
                    	session.setAttribute("username", username);
                        String role = rs.getString("ROLE");
                        session.setAttribute("userRole", role);
                        
                        
                        

                        String redirectPage = "";
                        if ("admin".equalsIgnoreCase(role)) {
                            redirectPage = "UserHomeForAdmin.jsp";
                        } else if ("police".equalsIgnoreCase(role)) {
                            redirectPage = "UserHomeForPolice.jsp";
                        } else if ("public".equalsIgnoreCase(role)) {
                            redirectPage = "UserHome.jsp";
                        }
                        //System.out.println(session);
                        //System.out.println(redirectPage);
        %>
                        <p class="message success">Login successful! Redirecting to your dashboard...</p>
                        <script>
                        
                            setTimeout(function () {
                                window.location.href = '<%= redirectPage %>';
                            }, 300);
                        </script>
        <%
                    } else {
        %>
                        <p class="message error">Invalid credentials. Please register if you don't have an account.</p>
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
