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

        // Server-side role normalization: registration can create only public or police accounts.
        registeredRole = registeredRole == null ? "public" : registeredRole.trim().toLowerCase(java.util.Locale.ROOT);
        if (!"police".equals(registeredRole)) {
            registeredRole = "public";
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
conn = DBConnection.getConnection();
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
<body class="crs-modern">
<div class="crs-auth-page">
    <section class="crs-auth-visual">
        <div class="crs-auth-copy">
            <a class="crs-brand" href="MainHome.jsp" style="color:#fff; margin-bottom:26px; display:inline-flex;">
                <span class="crs-brand-mark">◈</span><span>Crime Report System</span>
            </a>
            <h1>Create your account and start reporting responsibly.</h1>
            <p>Use the secure registration flow to create a citizen or police account. Police accounts include additional verification fields.</p>
        </div>
    </section>
    <section class="crs-auth-panel">
        <div class="crs-auth-box" style="max-width:620px;">
            <div style="display:flex;justify-content:flex-end;margin-bottom:8px;"><button class="crs-btn crs-theme-toggle" type="button" onclick="CRSTheme.toggle()"><span data-theme-icon>☾</span></button></div>
            <div class="crs-auth-head">
                <a class="crs-brand" href="MainHome.jsp"><span class="crs-brand-mark">◈</span><span>Crime Report System</span></a>
                <h2>Create an account</h2>
                <p>Enter your details below. Fields marked required must be completed.</p>
            </div>
            <%= message %>
            <form method="post" enctype="multipart/form-data" class="crs-form">
                <div class="crs-field"><label for="fullName">Full Name</label><input type="text" name="fullName" id="fullName" placeholder="Your full name" required></div>
                <div class="crs-field"><label for="userName">Username</label><input type="text" name="userName" id="userName" placeholder="Username with 4 digits" required></div>
                <div class="crs-field"><label for="email">Email</label><input type="email" name="email" id="email" placeholder="you@example.com" required></div>
                <div class="crs-field"><label for="dob">Date of Birth</label><input type="date" id="dob" name="dob" required onchange="validateDate()"><span id="dob-error" class="error-message"></span></div>
                <div class="crs-field"><label for="mobile">Mobile Number</label><input type="text" name="mobile" id="mobile" pattern="01[0-9]{9}" placeholder="01XXXXXXXXX" required></div>
                <div class="crs-field"><label for="roleSelect">Account Role</label><select name="role" id="roleSelect" required onchange="togglePoliceId()"><option value="public">Public</option><option value="police">Police</option></select></div>

                <div id="policeIdField" class="crs-card" style="display:none;padding:18px;">
                    <h3 style="margin:0 0 15px;font-size:15px;">Police verification details</h3>
                    <div class="crs-form">
                        <div class="crs-field"><label for="police_id_input">Police ID</label><input type="text" name="police_id" id="police_id_input" placeholder="e.g. 123456789001"></div>
                        <div class="crs-field"><label for="postName_input">Rank / Designation</label><input type="text" name="postName" id="postName_input" placeholder="e.g. SI, Inspector, Constable"></div>
                        <div class="crs-field"><label for="selectionYear_input">Selection Year</label><input type="number" name="selectionYear" id="selectionYear_input" min="1950" max="2030" placeholder="e.g. 2018"></div>
                        <div class="crs-field"><label for="fathersName_input">Father's Name</label><input type="text" name="fathersName" id="fathersName_input"></div>
                        <div class="crs-field"><label for="mothersName_input">Mother's Name</label><input type="text" name="mothersName" id="mothersName_input"></div>
                        <div class="crs-field"><label for="maritalStatus_input">Marital Status</label><select name="maritalStatus" id="maritalStatus_input"><option value="Single">Single</option><option value="Married">Married</option></select></div>
                        <div class="crs-field"><label for="permanentAddress_input">Permanent Address</label><textarea name="permanentAddress" id="permanentAddress_input" placeholder="Must match your file exactly"></textarea></div>
                        <div class="crs-field"><label for="injuries_input">Medical Records / Injuries</label><input type="text" name="injuries" id="injuries_input" value="None" placeholder="e.g. None, Left Hand Injury"></div>
                    </div>
                </div>

                <div class="crs-field"><label for="password">Password</label><div style="position:relative;"><input type="password" id="password" name="newpassword" placeholder="Create a strong password" required style="padding-right:44px;"><button type="button" onclick="togglePassword()" aria-label="Show password" style="position:absolute;right:8px;top:3px;width:38px;height:38px;border:0;background:transparent;color:var(--text-muted);cursor:pointer;"><i id="toggleIcon" class="fa-solid fa-eye"></i></button></div></div>
                <div class="crs-field"><label for="profilePictureInput">Profile Picture</label><div id="pic-mandatory-block" class="mandatory-block crs-message" style="display:none;">Profile picture is required for police personnel registration.</div><input type="file" id="profilePictureInput" name="profilePicture" accept="image/*"></div>
                <button type="submit">Create account</button>
            </form>
            <div class="crs-auth-footer">Already have an account? <a href="Login.jsp">Sign in</a></div>
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
    const fields=['police_id_input','postName_input','selectionYear_input','fathersName_input','mothersName_input','permanentAddress_input','injuries_input'];
    policeField.style.display=police?'block':'none'; notice.style.display=police?'block':'none'; pic.required=police; fields.forEach(function(id){document.getElementById(id).required=police;});
}
</script>
</body>
</html>
