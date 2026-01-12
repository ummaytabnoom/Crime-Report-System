<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*" %>
<%@ page import="javax.servlet.http.Part" %>
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*, org.apache.commons.io.output.*" %>
<%@ page import="java.util.*, java.sql.*, java.io.*" %>
<%@ page import="java.security.MessageDigest" %>
<%@ page import="utils.PasswordUtil" %>


<%
    String message = "";
    String registeredRole = ""; 
boolean policeExists = false;
    if (ServletFileUpload.isMultipartContent(request)) {
        DiskFileItemFactory factory = new DiskFileItemFactory();
        ServletFileUpload upload = new ServletFileUpload(factory);
        
        String fullName = "";
        String userName = "";
        String email = "";
        String dob = "";
        String mobile = "";
        String password = "";
        InputStream profilePicStream = null;

        try {
            List<FileItem> formItems = upload.parseRequest(request);

            for (FileItem item : formItems) {
                if (item.isFormField()) {
                    String fieldName = item.getFieldName();
                    String fieldValue = item.getString("UTF-8");

                    switch (fieldName) {
                        case "fullName": fullName = fieldValue; break;
                        case "userName": userName = fieldValue; break;
                        case "email": email = fieldValue; break;
                        case "dob": dob = fieldValue; break;
                        case "mobile": mobile = fieldValue; break;
                        case "role": registeredRole = fieldValue; break; 
                        case "newpassword": password = fieldValue; break;
                    }
                } else {
                    if (item.getName() != null && item.getSize() > 0) {
                        profilePicStream = item.getInputStream();
                    }
                }
            }

            // hash the password before saving
            
            String hashedPassword = PasswordUtil.hashPassword(password);

            Class.forName("oracle.jdbc.OracleDriver");
            Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");
            
            conn.setAutoCommit(false);

            String sql = "INSERT INTO REGISTERED_USERS (FULL_NAME, USER_NAME, EMAIL, DOB, MOBILE, ROLE, PASSWORD, PROFILE_PICTURE) " +
                         "VALUES ( ?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?)";
            PreparedStatement stmt = conn.prepareStatement(sql);
            
            stmt.setString(1, fullName);
            stmt.setString(2, userName);
            stmt.setString(3, email);
            stmt.setString(4, dob);
            stmt.setString(5, mobile);
            stmt.setString(6, registeredRole); 
            stmt.setString(7, hashedPassword);

            if (profilePicStream != null) {
                stmt.setBlob(8, profilePicStream);
            } else {
                String defaultPicPath = application.getRealPath("images/default.png");
                File defaultFile = new File(defaultPicPath);
                if(defaultFile.exists()) {
                    InputStream defaultStream = new FileInputStream(defaultFile);
                    stmt.setBlob(8, defaultStream);
                    defaultStream.close();
                } else {
                    stmt.setNull(8, Types.BLOB);
                }
            }

    

            int row = stmt.executeUpdate();
            conn.commit();
            
            
            if (row > 0) {
                // Successful registration
                int userId = 0;
                  String idQuery = "SELECT ID FROM REGISTERED_USERS WHERE USER_NAME = ? AND EMAIL = ?";
                  PreparedStatement idStmt = conn.prepareStatement(idQuery);
                  idStmt.setString(1, userName);
                  idStmt.setString(2, email);

                  ResultSet rs = idStmt.executeQuery();
                  if (rs.next()) {
                     userId = rs.getInt("ID");
                     }
                  rs.close();
                  idStmt.close();
                  
                  session.setAttribute("userId", userId);
                  session.setAttribute("username", userName);
                  session.setAttribute("userRole", registeredRole);
                  
                // Determine the redirect page based on the role
          
                String redirectPage = "";

                if (registeredRole != null) {
                    if (registeredRole.equalsIgnoreCase("admin")) {
                        redirectPage = "UserHomeForAdmin.jsp";
                    } else if (registeredRole.equalsIgnoreCase("police")) {
                        redirectPage = "UserHomeForPolice.jsp";
                    } else if (registeredRole.equalsIgnoreCase("public")) {
                        redirectPage = "UserHome.jsp";
                    } else {
                        redirectPage = "Login.jsp"; 
                    }
                }

                
                response.sendRedirect(redirectPage);
                return; 

                
            } else {
                message = "<p class='message error'>Registration failed!</p>";
            }

            stmt.close();
            conn.close();

        } catch (SQLIntegrityConstraintViolationException ex) {
            // Handle the unique constraint error specifically
            message = "<p class='message error'>Registration failed. A user with that username or email already exists.</p>";
            ex.printStackTrace();
        } catch (Exception ex) {
            ex.printStackTrace();
            message = "<p class='message error'>An error occurred during registration. Please try again.</p>";
        } finally {
            if (profilePicStream != null) {
                try {
                    profilePicStream.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    <meta charset="UTF-8">
    <title>Register - Crime Report System</title>
    <style>
        * { box-sizing: border-box; }
        body {
            margin: 0;
            padding: 0;
            height: 100vh;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: url("images/HomePagePic.jpg") no-repeat center center fixed;
            background-size: cover;
            display: flex;
            flex-direction: column;
        }
        nav {
            background-color: rgba(0, 0, 0, 0.7);
            padding: 15px 30px;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        nav h2 { margin: 0; color: #fff; font-weight: 500; }
        nav .nav-right a {
            text-decoration: none;
            color: #fff;
            background-color: #005F5F;
            padding: 8px 14px;
            border-radius: 5px;
            margin-left: 15px;
            transition: background-color 0.3s;
        }
        nav .nav-right a:hover { background-color: #007777; }
        .login-wrapper {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            padding: 30px;
            background-color: rgba(255, 255, 255, 0.2);
        }
        .login-box {
            background: #ffffffd9;
            padding: 40px;
            border-radius: 15px;
            width: 100%;
            max-width: 500px;
            box-shadow: 0px 0px 20px rgba(0, 0, 0, 0.25);
        }
        .login-box h2 {
            text-align: center;
            color: #222;
            margin-bottom: 25px;
        }
        label { font-weight: 600; color: #333; }
        input[type="text"],
        input[type="email"],
        input[type="date"],
        input[type="password"],
        select {
            width: 100%;
            padding: 10px;
            margin: 6px 0 15px 0;
            border: 1px solid #ccc;
            border-radius: 5px;
        }
        input[type="file"] {
            padding: 10px;
            border: 1px solid #bbb;
            border-radius: 6px;
            font-size: 14px;
            width: 100%;
            box-sizing: border-box;
            background-color: white;
            cursor: pointer;
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
        .message {
            text-align: center;
            margin-top: 10px;
            font-weight: bold;
        }
        .message.success { color: green; }
        .message.error { color: red; }
        .already-have-account {
            text-align: center;
            margin-top: 20px;
        }
        .already-have-account h3 {
            color: #333;
            margin-bottom: 10px;
        }
        
        .search-box { text-align: center; margin-bottom: 20px; }
        .search-box input[type="text"] { padding: 8px 12px; width: 250px; border-radius: 5px; border: 1px solid #ccc; }
        .search-box button { padding: 8px 15px; border: none; border-radius: 5px; background-color: #FF8C00; color: #fff; cursor: pointer; }
        .search-box button:hover { background-color: #e67300; }
        
        .error-message {
            color: #d9534f;
            font-size: 0.9em;
            margin-top: -10px;
            margin-bottom: 10px;
            display: none;
        }
        
    </style>
</head>
<body>
<meta charset="UTF-8">
<nav>
    <div class="nav-left">
        <h2>Crime Report System - Registration</h2>
    </div>
    <div class="nav-right">
        <a href="MainHome.jsp">Home</a>
        <a href="Login.jsp">Login</a>
    </div>
</nav>

<div class="login-wrapper">
    <div class="login-box">
        <h2>User Registration Form</h2>
        <%= message %>
        <form method="post" enctype="multipart/form-data">
            <label for="fullName">Full Name:</label>
            <input type="text" name="fullName" required />

            <label for="userName">Username:</label>
            <input type="text" name="userName" required />

            <label for="email">Email:</label>
            <input type="email" name="email" required />

            <label for="dob">Date of Birth:</label>
            <input type="date" id="dob" name="dob" required onchange="validateDate()" />
            <span id="dob-error" class="error-message"></span>

            <label for="mobile">Mobile No:</label>
            <input type="text" name="mobile" pattern="01[0-9]{9}" required />

            <label for="role">User Role:</label>
            <select name="role" required>
                <option value="public">Public</option>
                <option value="police">Police</option>
            </select>
            
           <label for="newpassword">New Password:</label>
           <div style="position: relative;">
               <input type="password" id="password" name="newpassword" required>
               <span onclick="togglePassword()" 
                     style="position: absolute; right: 10px; top: 12px; cursor: pointer; font-size: 18px; color: #555;">
                   <i id="toggleIcon" class="fa-solid fa-eye"></i>
               </span>
           </div>

            <label for="profilePicture">Profile Picture:</label>
            <input type="file" name="profilePicture" accept="image/*"  />

            <button type="submit">Register</button>
        </form>

        <div class="already-have-account">
            <h3>Already have an account?</h3>
            <button onclick="location.href='Login.jsp'" class="register-button">Login here</button>
        </div>
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

    // Function to set the maximum date and validate
    function validateDate() {
        const dobInput = document.getElementById("dob");
        const dobError = document.getElementById("dob-error");
        const selectedDate = new Date(dobInput.value);
        const today = new Date();

        if (selectedDate > today) {
            dobInput.setCustomValidity("Invalid date.");
            dobError.textContent = "Invalid date.";
            dobError.style.display = "block";
        } else {
            dobInput.setCustomValidity("");
            dobError.textContent = "";
            dobError.style.display = "none";
        }
    }
    
    document.addEventListener("DOMContentLoaded", function() {
        const today = new Date();
        const yyyy = today.getFullYear();
        const mm = String(today.getMonth() + 1).padStart(2, '0');
        const dd = String(today.getDate()).padStart(2, '0');
        const maxDate = `${yyyy}-${mm}-${dd}`;
        document.getElementById("dob").setAttribute("max", maxDate);
    });
</script>
</body>
</html>