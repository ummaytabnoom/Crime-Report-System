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
    
    // Additional Police verification inputs
    String inputFather = "";
    String inputMother = "";
    String inputMarital = "";
    String inputAddress = "";
    String inputPost = "";
    String inputInjuries = "";
    String inputSelectionYear = ""; 
    
    InputStream profilePicStream = null;
    long profilePicSize = 0; 

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
                    case "fathersName": inputFather = fieldValue; break;
                    case "mothersName": inputMother = fieldValue; break;
                    case "maritalStatus": inputMarital = fieldValue; break;
                    case "permanentAddress": inputAddress = fieldValue; break;
                    case "postName": inputPost = fieldValue; break;
                    case "injuries": inputInjuries = fieldValue; break;
                    case "selectionYear": inputSelectionYear = fieldValue; break; 
                    case "newpassword": password = fieldValue; break;
                }
            } else {
                if (item.getName() != null && item.getSize() > 0) {
                    profilePicStream = item.getInputStream();
                    profilePicSize = item.getSize();
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
        } else if ("police".equalsIgnoreCase(registeredRole) && profilePicSize == 0) {
            // ----------- MANDATORY PICTURE CHECK FOR POLICE -------------
            message = "<p class='message error'>Verification Failed: Profile picture is mandatory for police registrations.</p>";
        } else {
            // Hash password
            String hashedPassword = PasswordUtil.hashPassword(password);

            Class.forName("oracle.jdbc.OracleDriver");
            conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe", "system", "a12345");
            conn.setAutoCommit(false);

            // ----------- POLICE ID & INFORMATION VALIDATION -------------
            if ("police".equalsIgnoreCase(registeredRole)) {
                if (registeredId == null || registeredId.trim().isEmpty()) {
                    message = "<p class='message error'>Police ID is required for police users.</p>";
                } else {
                    PreparedStatement checkPolice = conn.prepareStatement(
                        "SELECT FATHERS_NAME, MOTHERS_NAME, PERMANENT_ADDRESS, MERITAL_STATUS, INJURIES, POST_NAME, SELECTION_YEAR " +
                        "FROM POLICE_INFO WHERE LOWER(TRIM(POLICE_ID)) = LOWER(TRIM(?))"
                    );
                    checkPolice.setString(1, registeredId);
                    ResultSet rsPolice = checkPolice.executeQuery();
                    
                    if (!rsPolice.next()) {
                        message = "<p class='message error'>This Police ID doesn't exist. Registration cannot proceed.</p>";
                    } else {
                        String dbFather = rsPolice.getString("FATHERS_NAME");
                        String dbMother = rsPolice.getString("MOTHERS_NAME");
                        String dbAddress = rsPolice.getString("PERMANENT_ADDRESS");
                        String dbMarital = rsPolice.getString("MERITAL_STATUS");
                        String dbInjuries = rsPolice.getString("INJURIES");
                        String dbPost = rsPolice.getString("POST_NAME");
                        int dbSelectionYear = rsPolice.getInt("SELECTION_YEAR");

                        if (dbFather == null || !dbFather.trim().equalsIgnoreCase(inputFather.trim())) {
                            message = "<p class='message error'>Verification Failed: Father's Name does not match official police records.</p>";
                        } else if (dbMother == null || !dbMother.trim().equalsIgnoreCase(inputMother.trim())) {
                            message = "<p class='message error'>Verification Failed: Mother's Name does not match official police records.</p>";
                        } else if (dbPost == null || !dbPost.trim().equalsIgnoreCase(inputPost.trim())) {
                            message = "<p class='message error'>Verification Failed: Rank/Post configuration does not match official records.</p>";
                        } else if (!String.valueOf(dbSelectionYear).equals(inputSelectionYear.trim())) {
                            message = "<p class='message error'>Verification Failed: Selection Year does not match official recruitment logs.</p>";
                        } else if (dbMarital == null || !dbMarital.trim().equalsIgnoreCase(inputMarital.trim())) {
                            message = "<p class='message error'>Verification Failed: Marital Status mismatch recorded.</p>";
                        } else if (dbAddress == null || !dbAddress.trim().equalsIgnoreCase(inputAddress.trim())) {
                            message = "<p class='message error'>Verification Failed: Permanent Address entry is incorrect.</p>";
                        } else if (dbInjuries == null || !dbInjuries.trim().equalsIgnoreCase(inputInjuries.trim())) {
                            message = "<p class='message error'>Verification Failed: Medical Records/Injuries report does not match official files.</p>";
                        }

                        if (message.isEmpty()) {
                            PreparedStatement usedPolice = conn.prepareStatement("SELECT COUNT(*) FROM REGISTERED_USERS WHERE POLICE_ID = ?");
                            usedPolice.setString(1, registeredId);
                            ResultSet rsUsed = usedPolice.executeQuery();
                            if (rsUsed.next() && rsUsed.getInt(1) > 0) {
                                message = "<p class='message error'>This Police ID has already been registered. Registration cannot proceed.</p>";
                            }
                            rsUsed.close();
                            usedPolice.close();
                        }
                    }
                    rsPolice.close();
                    checkPolice.close();
                }
            }

            // Only continue registration if no validations failed
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

                            response.sendRedirect("UserHome.jsp");
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
body { margin: 0; padding: 0; min-height: 100vh; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background: url("images/HomePagePic.jpg") no-repeat center center fixed; background-size: cover; display: flex; flex-direction: column; }
nav { background-color: rgba(0,0,0,0.7); padding: 15px 30px; display: flex; justify-content: space-between; align-items: center; }
nav h2 { margin:0; color:#fff; font-weight:500; }
nav .nav-right a { text-decoration:none; color:#fff; background-color:#005F5F; padding:8px 14px; border-radius:5px; margin-left:15px; transition:0.3s; }
nav .nav-right a:hover { background-color:#007777; }
.login-wrapper { flex:1; display:flex; justify-content:center; align-items:center; padding:30px; background-color: rgba(255,255,255,0.2); }
.login-box { background:#ffffffd9; padding:40px; border-radius:15px; width:100%; max-width:550px; box-shadow:0px 0px 20px rgba(0,0,0,0.25); margin: 20px 0;}
.login-box h2 { text-align:center; color:#222; margin-bottom:25px;}
label { font-weight:600;color:#333; display: block; margin-top: 10px;}
input[type="text"], input[type="email"], input[type="date"], input[type="password"], input[type="number"], select, textarea { width:100%; padding:10px; margin:6px 0 12px 0; border:1px solid #ccc; border-radius:5px;}
textarea { resize: vertical; height: 60px; font-family: inherit; }
input[type="file"] { padding:10px; border:1px solid #bbb; border-radius:6px; font-size:14px; width:100%; box-sizing:border-box; background-color:white; cursor:pointer; margin-top: 6px;}
button[type="submit"] { display:block; margin:25px auto 0; padding:12px 25px; background-color:#FF8C00; color:white; border:none; border-radius:8px; cursor:pointer; font-size:16px;}
button[type="submit"]:hover { background-color:#e67300; }
.register-button { margin-top:10px; background-color:#005F5F; padding:10px 20px; font-size:15px; font-weight:500; border:none; color:white; border-radius:5px; cursor:pointer;}
.register-button:hover { background-color:#004747; }
.message { text-align:center; margin-top:10px; font-weight:bold; padding: 10px; border-radius: 5px; }
.message.success { color:green; background: #d4edda; }
.message.error { color:#721c24; background: #f8d7da; border: 1px solid #f5c6cb; }
.already-have-account { text-align:center; margin-top:20px; }
.already-have-account h3 { color:#333; margin-bottom:10px; }
#error-message { color:#d9534f; font-size:0.9em; margin-top:-10px; margin-bottom:10px; display:none; }
#policeIdField { display:none; background: rgba(0, 95, 95, 0.08); padding: 15px; border-radius: 8px; border-left: 4px solid #005F5F; margin: 15px 0; }

/* Highly visible block layout for structural requirements notice */
.mandatory-block {
    display: none;
    background-color: #fff3cd;
    color: #856404;
    border: 1px solid #ffeeba;
    padding: 8px 12px;
    margin: 6px 0 2px 0;
    border-radius: 5px;
    font-size: 13px;
    font-weight: bold;
    text-transform: uppercase;
    letter-spacing: 0.5px;
}
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
    <h3 style="margin-top:0; color:#005F5F; border-bottom: 1px solid #005F5F; padding-bottom:5px;">Official Police Credentials</h3>
    
    <label for="police_id">Police ID:</label>
    <input type="text" name="police_id" id="police_id_input" placeholder="e.g. 123456789001" />
    
    <label for="postName">Rank / Designation Post:</label>
    <input type="text" name="postName" id="postName_input" placeholder="e.g. SI, Inspector, Constable" />

    <label for="selectionYear">Selection Year:</label>
    <input type="number" name="selectionYear" id="selectionYear_input" min="1950" max="2030" placeholder="e.g. 2018" />
    
    <label for="fathersName">Father's Name:</label>
    <input type="text" name="fathersName" id="fathersName_input" />
    
    <label for="mothersName">Mother's Name:</label>
    <input type="text" name="mothersName" id="mothersName_input" />
    
    <label for="maritalStatus">Marital Status:</label>
    <select name="maritalStatus" id="maritalStatus_input">
        <option value="Single">Single</option>
        <option value="Married">Married</option>
    </select>
    
    <label for="permanentAddress">Permanent Address:</label>
    <textarea name="permanentAddress" id="permanentAddress_input" placeholder="Must match your file exactly"></textarea>
    
    <label for="injuries">Medical Records / Injuries:</label>
    <input type="text" name="injuries" id="injuries_input" value="None" placeholder="e.g. None, Left Hand Injury" />
</div>

<label for="newpassword">New Password:</label>
<div style="position: relative;">
<input type="password" id="password" name="newpassword" required>
<span onclick="togglePassword()" style="position:absolute; right:10px; top:12px; cursor:pointer; font-size:18px; color:#555;">
<i id="toggleIcon" class="fa-solid fa-eye"></i></span>
</div>

<label for="profilePicture">Profile Picture:</label>
<div id="pic-mandatory-block" class="mandatory-block">
    <i class="fa-solid fa-triangle-exclamation"></i> Profile picture is required for police personnel registration!
</div>
<input type="file" id="profilePictureInput" name="profilePicture" accept="image/*"  />

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

document.addEventListener("DOMContentLoaded", function() {
    const today = new Date();
    const yyyy = today.getFullYear();
    const mm = String(today.getMonth() + 1).padStart(2, '0');
    const dd = String(today.getDate()).padStart(2, '0');
    const maxDate = `${yyyy}-${mm}-${dd}`;
    document.getElementById("dob").setAttribute("max", maxDate);
    togglePoliceId();
});

function togglePoliceId() {
    const roleSelect = document.getElementById("roleSelect");
    const policeField = document.getElementById("policeIdField");
    const picInput = document.getElementById("profilePictureInput");
    const picMandatoryBlock = document.getElementById("pic-mandatory-block");
    
    const fields = [
        "police_id_input", "postName_input", "selectionYear_input", 
        "fathersName_input", "mothersName_input", "permanentAddress_input", "injuries_input"
    ];
    
    if (roleSelect.value === "police") {
        policeField.style.display = "block";
        picMandatoryBlock.style.display = "block"; // Displays notification directly above input field
        picInput.required = true; 
        fields.forEach(id => {
            document.getElementById(id).required = true;
        });
    } else {
        policeField.style.display = "none";
        picMandatoryBlock.style.display = "none"; // Hides requirement box for regular citizens
        picInput.required = false; 
        fields.forEach(id => {
            document.getElementById(id).required = false;
        });
    }
}
</script>
</body>
</html>