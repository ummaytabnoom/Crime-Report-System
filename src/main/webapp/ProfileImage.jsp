<%@ page trimDirectiveWhitespaces="true" import="java.sql.*,utils.DBConnection" %><%
    String avatarUser = (String) session.getAttribute("username");
    byte[] avatarBytes = null;
    if (avatarUser != null) {
        try (Connection avatarConn = DBConnection.getConnection();
             PreparedStatement avatarStmt = avatarConn.prepareStatement("SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?")) {
            avatarStmt.setString(1, avatarUser);
            try (ResultSet avatarResult = avatarStmt.executeQuery()) {
                if (avatarResult.next()) avatarBytes = avatarResult.getBytes(1);
            }
        } catch (Exception ignored) { }
    }
    response.setHeader("Cache-Control", "no-store");
    if (avatarBytes == null || avatarBytes.length == 0) {
        response.sendRedirect(request.getContextPath() + "/images/default.png");
        return;
    }
    String avatarMime = "image/jpeg";
    if (avatarBytes.length > 3 && (avatarBytes[0] & 255) == 137 && avatarBytes[1] == 80) avatarMime = "image/png";
    else if (avatarBytes.length > 3 && avatarBytes[0] == 71 && avatarBytes[1] == 73) avatarMime = "image/gif";
    else if (avatarBytes.length > 11 && avatarBytes[8] == 87 && avatarBytes[9] == 69) avatarMime = "image/webp";
    response.setContentType(avatarMime);
    response.setContentLength(avatarBytes.length);
    out.clear();
    response.getOutputStream().write(avatarBytes);
    response.getOutputStream().flush();
%>