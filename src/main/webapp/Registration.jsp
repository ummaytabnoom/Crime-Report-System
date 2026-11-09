<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="false" %>

<%@ page import="java.sql.*, java.io.*" %>

<%@ page import="javax.servlet.http.Part" %>

<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*, org.apache.commons.io.output.*" %>

<%@ page import="java.util.*, java.security.MessageDigest" %>

<%@ page import="utils.PasswordUtil" %>

<%@ page import="utils.DBConnection" %>


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



    String inputPost = "";



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


                    case "postName": inputPost = fieldValue; break;


                    case "newpassword": password = fieldValue; break;

                }

            } else {

                if (item.getName() != null && item.getSize() > 0) {

                    profilePicStream = item.getInputStream();

                    profilePicSize = item.getSize();

                }

            }

        }


        // Server-side role normalization: registration can create only public or police accounts.

        registeredRole = registeredRole == null ? "public" : registeredRole.trim().toLowerCase(java.util.Locale.ROOT);

        if (!"police".equals(registeredRole)) {

            registeredRole = "public";

        }


        if (!"police".equals(registeredRole)) { registeredId = null; }

        // Username: at least 4 characters, lowercase letters, optional digits and underscores.
        // Digits are not required.
        if (userName == null || !userName.matches("[a-z0-9_]{4,}")) {
            message = "<p class='message error'>Username must be at least 4 characters and contain only lowercase letters, numbers, or underscores.</p>";
        } else if ("police".equalsIgnoreCase(registeredRole) && profilePicSize == 0) {

            // ----------- MANDATORY PICTURE CHECK FOR POLICE -------------

            message = "<p class='message error'>Verification Failed: Profile picture is mandatory for police registrations.</p>";

        } else {

            // Hash password

            String hashedPassword = PasswordUtil.hashPassword(password);

conn = DBConnection.getConnection();

            conn.setAutoCommit(false);


            // ----------- POLICE ID & INFORMATION VALIDATION -------------

            if ("police".equalsIgnoreCase(registeredRole)) {

                if (registeredId == null || registeredId.trim().isEmpty()) {

                    message = "<p class='message error'>Police ID is required for police users.</p>";

                } else {

                    PreparedStatement checkPolice = conn.prepareStatement(
                       "SELECT POST_NAME FROM POLICE_INFO WHERE LOWER(TRIM(POLICE_ID)) = LOWER(TRIM(?))"
                   );
                   checkPolice.setString(1, registeredId);
                   ResultSet rsPolice = checkPolice.executeQuery();
                   if (!rsPolice.next()) {
                       message = "<p class='message error'>This Police ID doesn't exist. Registration cannot proceed.</p>";
                   } else {
                       String dbPost = rsPolice.getString("POST_NAME");
                       if (inputPost == null || inputPost.trim().isEmpty() ||
                           dbPost == null || !dbPost.trim().equalsIgnoreCase(inputPost.trim())) {
                           message = "<p class='message error'>Verification Failed: Rank / Designation does not match official police records.</p>";
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

                PreparedStatement checkUser = conn.prepareStatement("SELECT COUNT(*) FROM REGISTERED_USERS WHERE LOWER(USER_NAME) = ?");

                checkUser.setString(1, userName);

                ResultSet rsUser = checkUser.executeQuery();

                boolean userExists = false;

                if (rsUser.next() && rsUser.getInt(1) > 0) userExists = true;

                rsUser.close();

                checkUser.close();


                if (userExists) {

                    message = "<p class='message error'>Username already exists. Please choose a different username.</p>";

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


                            String normalizedRole = registeredRole == null ? "public" : registeredRole.toLowerCase(java.util.Locale.ROOT);

                            String redirectPage = "police".equals(normalizedRole) ? "PoliceHome.jsp" : "UserHome.jsp";

                            response.sendRedirect(redirectPage);

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

<html lang="en">

<head>

<meta charset="UTF-8">

<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Create account - Crime Report System</title>

<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">

    <%@ include file="/WEB-INF/jspf/common-assets.jspf" %>

</head>

<body class="modern page-registration">

<div class="auth-page">

    <section class="auth-visual">

        <div class="auth-copy">

            <a class="brand brand-link" href="MainHome.jsp">

                <img class="brand-mark" src="images/crslogo.png" alt=""><span>Crime Report System</span>

            </a>

            <h1>Create your account and start reporting responsibly.</h1>


        </div>

    </section>

    <section class="auth-panel">

        <div class="auth-box form-width">

            <div class="toolbar-end"></div>

            <div class="auth-head">

                <a class="brand" href="MainHome.jsp"><img class="brand-mark" src="images/crslogo.png" alt=""><span>Crime Report System</span></a>

                <h2>Create an account</h2>

                <p>Enter your details below. Fields marked required must be completed.</p>

            </div>

            <%= message %>

            <form method="post" enctype="multipart/form-data" class="form">

                <div class="field"><label for="fullName">Full Name</label><input type="text" name="fullName" id="fullName" placeholder="Your full name" required></div>

                <div class="field"><label for="userName">Username</label><input type="text" name="userName" id="userName" placeholder="e.g. rahim_ahmed" minlength="4" pattern="[a-z0-9_]{4,}" title="At least 4 characters; lowercase letters, numbers and underscores only" required></div>

                <div class="field"><label for="email">Email</label><input type="email" name="email" id="email" placeholder="you@example.com" required></div>

                <div class="field"><label for="dob">Date of Birth</label><input type="date" id="dob" name="dob" required onchange="validateDate()"><span id="dob-error" class="error-message"></span></div>

                <div class="field"><label for="mobile">Mobile Number</label><input type="text" name="mobile" id="mobile" pattern="01[0-9]{9}" placeholder="01XXXXXXXXX" required></div>

                <div class="field"><label for="roleSelect">Account Role</label><select name="role" id="roleSelect" required onchange="togglePoliceId()"><option value="public">Public</option><option value="police">Police</option></select></div>


                <div id="policeIdField" class="card police-fields">

                    <h3 class="field-title">Police verification details</h3>

                    <div class="form">

                        <div class="field"><label for="police_id_input">Police ID</label><input type="text" name="police_id" id="police_id_input" placeholder="e.g. 123456789001"></div>

                        <div class="field"><label for="postName_input">Rank / Designation</label><input type="text" name="postName" id="postName_input" placeholder="e.g. SI, Inspector, Constable"></div>


                    </div>

                </div>


                <div class="field"><label for="password">Password</label><div class="input-wrap"><input type="password" id="password" name="newpassword" placeholder="Create a strong password" required class="password-input"><button type="button" onclick="togglePassword()" aria-label="Show password" class="password-toggle"><i id="toggleIcon" class="fa-solid fa-eye"></i></button></div></div>

                <div class="field"><label for="profilePictureInput">Profile Picture</label><div id="pic-mandatory-block" class="mandatory-block message hidden">Profile picture is required for police personnel registration.</div><input type="file" id="profilePictureInput" name="profilePicture" accept="image/*"></div>

                <button type="submit">Create account</button>

            </form>

            <div class="auth-footer">Already have an account? <a href="Login.jsp">Sign in</a></div>

        </div>

    </section>

</div>

<script>

function togglePassword() {

    const pwdField = document.getElementById('password');

    const toggleIcon = document.getElementById('toggleIcon');

    if (pwdField.type === 'password') { pwdField.type='text'; toggleIcon.classList.remove('fa-eye'); toggleIcon.classList.add('fa-eye-slash'); }

    else { pwdField.type='password'; toggleIcon.classList.remove('fa-eye-slash'); toggleIcon.classList.add('fa-eye'); }

}

function validateDate() {

    const dobInput=document.getElementById('dob'), dobError=document.getElementById('dob-error'), selectedDate=new Date(dobInput.value), today=new Date();

    if(selectedDate>today){dobInput.setCustomValidity('Invalid date.');dobError.textContent='Invalid date.';dobError.style.display='block';}

    else{dobInput.setCustomValidity('');dobError.textContent='';dobError.style.display='none';}

}

document.addEventListener('DOMContentLoaded', function(){

    const today=new Date(), yyyy=today.getFullYear(), mm=String(today.getMonth()+1).padStart(2,'0'), dd=String(today.getDate()).padStart(2,'0');

    document.getElementById('dob').setAttribute('max', yyyy+'-'+mm+'-'+dd); togglePoliceId();

});

function togglePoliceId(){

    const police=document.getElementById('roleSelect').value==='police';

    const policeField=document.getElementById('policeIdField'), pic=document.getElementById('profilePictureInput'), notice=document.getElementById('pic-mandatory-block');

    const fields=['police_id_input','postName_input'];

    policeField.style.display=police?'block':'none'; notice.style.display=police?'block':'none'; pic.required=police; fields.forEach(function(id){document.getElementById(id).required=police;});

}

</script>

</body>

</html>
