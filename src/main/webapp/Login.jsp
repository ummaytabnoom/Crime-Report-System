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
<body class="crs-modern">
<div class="crs-auth-page">
    <section class="crs-auth-visual">
        <div class="crs-auth-copy">
            <a class="crs-brand" href="MainHome.jsp" style="color:#fff; margin-bottom:26px; display:inline-flex;">
                <span class="crs-brand-mark">◈</span>
                <span>Crime Report System</span>
            </a>
            <h1>Your report can help make the community safer.</h1>
            <p>Sign in to submit reports, follow investigations, and keep your information up to date.</p>
        </div>
    </section>

    <section class="crs-auth-panel">
        <div class="crs-auth-box">
            <div style="display:flex;justify-content:flex-end;margin-bottom:8px;">
                <button class="crs-btn crs-theme-toggle" type="button" onclick="CRSTheme.toggle()" aria-label="Toggle theme"><span data-theme-icon>☾</span></button>
            </div>
            <div class="crs-auth-head">
                <a class="crs-brand" href="MainHome.jsp"><span class="crs-brand-mark">◈</span><span>Crime Report System</span></a>
                <h2>Welcome back</h2>
                <p>Sign in to continue to your dashboard.</p>
            </div>

            <form method="post" action="" class="crs-form">
                <div class="crs-field">
                    <label for="username">Username</label>
                    <input id="username" type="text" name="username" placeholder="Enter your username" required>
                </div>
                <div class="crs-field">
                    <label for="email">Email</label>
                    <input id="email" type="email" name="email" placeholder="you@example.com" required>
                </div>
                <div class="crs-field">
                    <label for="password">Password</label>
                    <div style="position:relative;">
                        <input id="password" type="password" name="password" placeholder="Enter your password" required style="padding-right:44px;">
                        <button type="button" onclick="togglePassword()" aria-label="Show password" style="position:absolute;right:8px;top:3px;width:38px;height:38px;border:0;background:transparent;color:var(--text-muted);cursor:pointer;box-shadow:none;">
                            <i id="toggleIcon" class="fa-solid fa-eye"></i>
                        </button>
                    </div>
                </div>
                <div class="crs-form-meta">
                    <span>Secure sign in</span>
                    <a href="ForgotPassword.jsp">Forgot password?</a>
                </div>
                <button type="submit">Sign in <span>→</span></button>
            </form>

            <div class="crs-auth-footer">Don't have an account? <a href="Registration.jsp">Create one</a></div>

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
                        <div class="crs-message success" style="margin-top:16px;">Login successful. Redirecting to your dashboard...</div>
                        <script>setTimeout(function(){ window.location.href='<%= redirectPage %>'; }, 300);</script>
            <%
                    } else {
            %>
                        <div class="crs-message error" style="margin-top:16px;">Invalid credentials. Please check your details and try again.</div>
            <%
                    }
                } catch (Exception e) {
            %>
                    <div class="crs-message error" style="margin-top:16px;">Unable to sign in: <%= e.getMessage() %></div>
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
