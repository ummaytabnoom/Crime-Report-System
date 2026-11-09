<%@ page import="java.sql.*, java.io.*" %>
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="org.apache.commons.fileupload.*, org.apache.commons.fileupload.disk.*, org.apache.commons.fileupload.servlet.*, java.util.*" %>
<%@ page import="utils.PasswordUtil" %>
<%@ page import="utils.DBConnection" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Sign in - Crime Report System</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
        <%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-login">
<div class="auth-page">
    <section class="auth-visual">
        <div class="auth-copy">
            <a class="brand brand-link" href="MainHome.jsp">
                <img class="brand-mark" src="images/crslogo.png" alt="">
                <span>Crime Report System</span>
            </a>
            <h1>Your report can help make the community safer.</h1>
    
        </div>
    </section>

    <section class="auth-panel">
        <div class="auth-box">
            <div class="toolbar-end">
                
            </div>
            <div class="auth-head">
                <a class="brand" href="MainHome.jsp"><img class="brand-mark" src="images/crslogo.png" alt=""><span>Crime Report System</span></a>
                <h2>Welcome back</h2>
                <p>Sign in to continue to your dashboard.</p>
            </div>

            <form method="post" action="" class="form">
                <div class="field">
                    <label for="username">Username</label>
                    <input id="username" type="text" name="username" placeholder="Enter your username" required>
                </div>
                <div class="field">
                    <label for="email">Email</label>
                    <input id="email" type="email" name="email" placeholder="you@example.com" required>
                </div>
                <div class="field">
                    <label for="password">Password</label>
                    <div class="input-wrap">
                        <input id="password" type="password" name="password" placeholder="Enter your password" required class="password-input">
                        <button type="button" onclick="togglePassword()" aria-label="Show password" class="password-eye">
                            <i id="toggleIcon" class="fa-solid fa-eye"></i>
                        </button>
                    </div>
                </div>
                
                <button type="submit">Sign in <span>→</span></button>
            </form>

            <div class="auth-footer">Don't have an account? <a href="Registration.jsp">Create one</a></div>

            <%
            if ("POST".equalsIgnoreCase(request.getMethod())) {
                String username = request.getParameter("username");
                String email = request.getParameter("email");
                String rawPassword = request.getParameter("password");
                String hashedPassword = PasswordUtil.hashPassword(rawPassword);

                Connection conn = null;
                PreparedStatement pstmt = null;
                ResultSet rs = null;
                try {
conn = DBConnection.getConnection();
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
                        String normalizedRole = role == null ? "public" : role.trim().toLowerCase(java.util.Locale.ROOT);
                        String redirectPage;
                        if ("admin".equals(normalizedRole)) {
                            redirectPage = "AdminsHome.jsp";
                        } else if ("police".equals(normalizedRole)) {
                            redirectPage = "PoliceHome.jsp";
                        } else {
                            redirectPage = "UserHome.jsp";
                        }
            %>
                        <div class="message success message-gap">Login successful. Redirecting to your dashboard...</div>
                        <script>setTimeout(function(){ sessionStorage.setItem('app-toast', JSON.stringify({message:'Signed in successfully.',type:'success'})); window.location.href='<%= redirectPage %>'; }, 300);</script>
            <%
                    } else {
            %>
                        <div class="message error message-gap">Invalid credentials. Please check your details and try again.</div>
            <%
                    }
                } catch (Exception e) {
            %>
                    <div class="message error message-gap">Unable to sign in: <%= e.getMessage() %></div>
            <%
                } finally {
                    try { if (rs != null) rs.close(); } catch (Exception e) {}
                    try { if (pstmt != null) pstmt.close(); } catch (Exception e) {}
                    try { if (conn != null) conn.close(); } catch (Exception e) {}
                }
            }
            %>
        </div>
    </section>
</div>
<script>
function togglePassword() {
    const pwdField = document.getElementById('password');
    const toggleIcon = document.getElementById('toggleIcon');
    if (pwdField.type === 'password') {
        pwdField.type = 'text';
        toggleIcon.classList.remove('fa-eye');
        toggleIcon.classList.add('fa-eye-slash');
    } else {
        pwdField.type = 'password';
        toggleIcon.classList.remove('fa-eye-slash');
        toggleIcon.classList.add('fa-eye');
    }
}
</script>
</body>
</html>
