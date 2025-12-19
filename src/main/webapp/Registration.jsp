<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>
<%@ page import="java.sql.*, java.io.*" %>
<%@ page import="javax.servlet.http.Part" %>
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*, org.apache.commons.io.output.*" %>
<%@ page import="java.util.*, java.security.MessageDigest" %>
<%@ page import="utils.PasswordUtil" %>

<%
String message = "";
String registeredRole = ""; 
String registeredId = ""; 

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

    Connection conn = null;
    PreparedStatement stmt = null;

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
                    case "police_id": registeredId = fieldValue; break; 
                    case "newpassword": password = fieldValue; break;
                }
            } else {
                if (item.getName() != null && item.getSize() > 0) {
                    profilePicStream = item.getInputStream();
                }
            }
        }

        // ----------- VALIDATE USERNAME DIGITS -------------
        int digitCount = 0;
        for (char c : userName.toCharArray()) {
            if (Character.isDigit(c)) digitCount++;
        }
        if (digitCount < 4) {
            message = "<p class='message error'>Username must contain at least 4 digits.</p>";
        } else {
            // Hash password
            String hashedPassword = PasswordUtil.hashPassword(password);

            Class.forName("oracle.jdbc.OracleDriver");
            conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");
            conn.setAutoCommit(false);

            // ----------- POLICE ID VALIDATION -------------
            if ("police".equalsIgnoreCase(registeredRole)) {
                if (registeredId == null || registeredId.trim().isEmpty()) {
                    message = "<p class='message error'>Police ID is required for police users.</p>";
                } else {
                    // Check if police ID exists in POLICE_INFO
                    PreparedStatement checkPolice = conn.prepareStatement("SELECT COUNT(*) FROM POLICE_INFO WHERE POLICE_ID = ?");
                    checkPolice.setString(1, registeredId);
                    ResultSet rsPolice = checkPolice.executeQuery();
                    boolean policeExists = false;
                    if (rsPolice.next() && rsPolice.getInt(1) > 0) policeExists = true;
                    rsPolice.close();
                    checkPolice.close();

                    if (!policeExists) {
                        message = "<p class='message error'>This Police ID doesn't exist. Registration cannot proceed.</p>";
                    } else {
                        // Check if Police ID already used in REGISTERED_USERS
                        PreparedStatement usedPolice = conn.prepareStatement("SELECT COUNT(*) FROM REGISTERED_USERS WHERE POLICE_ID = ?");
                        usedPolice.setString(1, registeredId);
                        ResultSet rsUsed = usedPolice.executeQuery();
                        boolean policeUsed = false;
                        if (rsUsed.next() && rsUsed.getInt(1) > 0) policeUsed = true;
                        rsUsed.close();
                        usedPolice.close();

                        if (policeUsed) {
                            message = "<p class='message error'>This Police ID has already been registered. Registration cannot proceed.</p>";
                        }
                    }
                }
            }

            // Only continue registration if no police ID error
            if (message.isEmpty()) {
                // ----------- CHECK USERNAME EXISTS -------------
                PreparedStatement checkUser = conn.prepareStatement("SELECT COUNT(*) FROM REGISTERED_USERS WHERE USER_NAME = ?");
                checkUser.setString(1, userName);
                ResultSet rsUser = checkUser.executeQuery();
                boolean userExists = false;
                if (rsUser.next() && rsUser.getInt(1) > 0) userExists = true;
                rsUser.close();
                checkUser.close();

                if (userExists) {
                    message = "<p class='message error'>Username already exists. Add 4 different numbers to your username.</p>";
                } else {
                    // ----------- CHECK EMAIL EXISTS -------------
                    PreparedStatement checkEmail = conn.prepareStatement("SELECT COUNT(*) FROM REGISTERED_USERS WHERE EMAIL = ?");
                    checkEmail.setString(1, email);
                    ResultSet rsEmail = checkEmail.executeQuery();
                    boolean emailExists = false;
                    if (rsEmail.next() && rsEmail.getInt(1) > 0) emailExists = true;
                    rsEmail.close();
                    checkEmail.close();

                    if (emailExists) {
                        message = "<p class='message error'>Email already exists. Please use a different email.</p>";
                    } else {
                        // ----------- INSERT USER -------------
                        String sql = "INSERT INTO REGISTERED_USERS "
                                   + "(FULL_NAME, USER_NAME, EMAIL, DOB, MOBILE, ROLE, POLICE_ID, PASSWORD, PROFILE_PICTURE) "
                                   + "VALUES (?, ?, ?, TO_DATE(?, 'YYYY-MM-DD'), ?, ?, ?, ?, ?)";
                        stmt = conn.prepareStatement(sql, new String[]{"ID"});

                        stmt.setString(1, fullName);
                        stmt.setString(2, userName);
                        stmt.setString(3, email);
                        stmt.setString(4, dob);
                        stmt.setString(5, mobile);
                        stmt.setString(6, registeredRole);
                        stmt.setString(7, registeredId);
                        stmt.setString(8, hashedPassword);

                        if (profilePicStream != null) {
                            stmt.setBlob(9, profilePicStream);
                        } else {
                            String defaultPicPath = application.getRealPath("images/default.png");
                            File defaultFile = new File(defaultPicPath);
                            if(defaultFile.exists()) {
                                InputStream defaultStream = new FileInputStream(defaultFile);
                                stmt.setBlob(9, defaultStream);
                                defaultStream.close();
                            } else {
                                stmt.setNull(9, Types.BLOB);
                            }
                        }

                        int row = stmt.executeUpdate();

                        if (row > 0) {
                            ResultSet rs = stmt.getGeneratedKeys();
                            int userId = 0;
                            if (rs.next()) { userId = rs.getInt(1); }
                            rs.close();
                            conn.commit();

                            session.setAttribute("userId", userId);
                            session.setAttribute("username", userName);
                            session.setAttribute("userRole", registeredRole);

                            // Redirect based on role
                            if ("admin".equalsIgnoreCase(registeredRole)) {
                                response.sendRedirect("UserHomeForAdmin.jsp");
                            } else if ("police".equalsIgnoreCase(registeredRole)) {
                                response.sendRedirect("UserHomeForPolice.jsp");
                            } else {
                                response.sendRedirect("UserHome.jsp");
                            }
                            return;
                        } else {
                            message = "<p class='message error'>Registration failed!</p>";
                        }
                    }
                }
            }
        }

    } catch (SQLIntegrityConstraintViolationException ex) {
        message = "<p class='message error'>User with this username or email already exists.</p>";
        ex.printStackTrace();
    } catch (Exception ex) {
        message = "<p class='message error'>An error occurred during registration. Please try again.</p>";
        ex.printStackTrace();
    } finally {
        if (profilePicStream != null) try { profilePicStream.close(); } catch (Exception ignore) {}
        if (stmt != null) try { stmt.close(); } catch (Exception ignore) {}
        if (conn != null) try { conn.close(); } catch (Exception ignore) {}
    }
}
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Register - Crime Report System</title>
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
<style>
* { box-sizing: border-box; }
body { margin: 0; padding: 0; height: 100vh; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: url("images/HomePagePic.jpg") no-repeat center center fixed; background-size: cover; display: flex; flex-direction: column; }
nav { background-color: rgba(0,0,0,0.7); padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; }
nav h2 { margin:0; color:#fff; font-weight:500; }
nav .nav-right a { text-decoration:none; color:#fff; background-color:#005F5F; padding:8px 14px; border-radius:5px; margin-left:15px; transition:0.3s; }
nav .nav-right a:hover { background-color:#007777; }
.login-wrapper { flex:1; display:flex; justify-content:center; align-items:center; padding:30px; background-color: rgba(255,255,255,0.2); }
.login-box { background:#ffffffd9; padding:40px; border-radius:15px; width:100%; max-width:500px; box-shadow:0px 0px 20px rgba(0,0,0,0.25);}
.login-box h2 { text-align:center; color:#222; margin-bottom:25px;}
label { font-weight:600;color:#333; }
input[type="text"], input[type="email"], input[type="date"], input[type="password"], select { width:100%; padding:10px; margin:6px 0 15px 0; border:1px solid #ccc; border-radius:5px;}
input[type="file"] { padding:10px; border:1px solid #bbb; border-radius:6px; font-size:14px; width:100%; box-sizing:border-box; background-color:white; cursor:pointer;}
button[type="submit"] { display:block; margin:25px auto 0; padding:12px 25px; background-color:#FF8C00; color:white; border:none; border-radius:8px; cursor:pointer; font-size:16px;}
button[type="submit"]:hover { background-color:#e67300; }
.register-button { margin-top:10px; background-color:#005F5F; padding:10px 20px; font-size:15px; font-weight:500;}
.register-button:hover { background-color:#004747; }
.message { text-align:center; margin-top:10px; font-weight:bold; }
.message.success { color:green; }
.message.error { color:red; }
.already-have-account { text-align:center; margin-top:20px; }
.already-have-account h3 { color:#333; margin-bottom:10px; }
#error-message { color:#d9534f; font-size:0.9em; margin-top:-10px; margin-bottom:10px; display:none; }
#policeIdField { display:none; }
</style>
</head>
<body>
<nav>
<div class="nav-left"><h2>Crime Report System - Registration</h2></div>
<div class="nav-right"><a href="MainHome.jsp">Home</a><a href="Login.jsp">Login</a></div>
</nav>

<div class="login-wrapper">
<div class="login-box">
<h2>User Registration Form</h2>
<%= message %>
<form method="post" enctype="multipart/form-data">
<label for="fullName">Full Name:</label>
<input type="text" name="fullName" required />

<label for="userName">Username(With 4 digits):</label>
<input type="text" name="userName" required />

<label for="email">Email:</label>
<input type="email" name="email" required />

<label for="dob">Date of Birth:</label>
<input type="date" id="dob" name="dob" required onchange="validateDate()" />
<span id="dob-error" class="error-message"></span>

<label for="mobile">Mobile No:</label>
<input type="text" name="mobile" pattern="01[0-9]{9}" required />

<label for="role">User Role:</label>
<select name="role" id="roleSelect" required onchange="togglePoliceId()">
<option value="public">Public</option>
<option value="police">Police</option>
</select>

<div id="policeIdField">
<label for="police_id">Police ID:</label>
<input type="text" name="police_id" id="police_id_input" />
</div>

<label for="newpassword">New Password:</label>
<div style="position: relative;">
<input type="password" id="password" name="newpassword" required>
<span onclick="togglePassword()" style="position:absolute; right:10px; top:12px; cursor:pointer; font-size:18px; color:#555;">
<i id="toggleIcon" class="fa-solid fa-eye"></i></span>
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
    if (pwdField.type === "password") { pwdField.type = "text"; toggleIcon.classList.remove("fa-eye"); toggleIcon.classList.add("fa-eye-slash"); }
    else { pwdField.type = "password"; toggleIcon.classList.remove("fa-eye-slash"); toggleIcon.classList.add("fa-eye"); }
}

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

// Set max date
document.addEventListener("DOMContentLoaded", function() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const maxDate = `${yyyy}-${mm}-${dd}`;
    document.getElementById("dob").setAttribute("max", maxDate);
});

// Toggle Police ID field
function togglePoliceId() {
    const roleSelect = document.getElementById("roleSelect");
    const policeField = document.getElementById("policeIdField");
    if (roleSelect.value === "police") {
        policeField.style.display = "block";
        document.getElementById("police_id_input").required = true;
    } else {
        policeField.style.display = "none";
        document.getElementById("police_id_input").required = false;
    }
}
</script>
</body>
</html>
