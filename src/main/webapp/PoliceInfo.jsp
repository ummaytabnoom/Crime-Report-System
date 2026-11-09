<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="utils.DBConnection" %>
<%!
    private String escapeHtml(String value) {
        if (value == null) return "";
        return value.replace("&", "&amp;").replace("<", "&lt;")
                    .replace(">", "&gt;").replace("\"", "&quot;")
                    .replace("'", "&#39;");
    }
    private String displayValue(String value) {
        return value == null || value.trim().isEmpty() ? "N/A" : escapeHtml(value);
    }
%>
<%
    String currentUser = (String) session.getAttribute("username");
    String userRole = (String) session.getAttribute("userRole");
    if (currentUser == null || !("admin".equalsIgnoreCase(userRole) || "police".equalsIgnoreCase(userRole))) {
        response.sendRedirect("Login.jsp");
        return;
    }
    String searchQuery = request.getParameter("search");
    String searchParam = searchQuery == null || searchQuery.trim().isEmpty()
        ? null : "%" + searchQuery.trim().toLowerCase(java.util.Locale.ROOT) + "%";
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Police Directory - Crime Report System</title>
    <%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-policeinfo">
    <%@ include file="/WEB-INF/jspf/navbar.jspf" %>
    <div class="content-box">
        <h2>Police Directory</h2>
        <div class="search-bar">
            <form method="get" action="PoliceInfo.jsp">
                <input type="text" name="search" placeholder="Search by name, username or Police ID..." value="<%= escapeHtml(searchQuery) %>">
                <button type="submit">Search</button>
                <% if (searchParam != null) { %>
                    <a href="PoliceInfo.jsp">Clear</a>
                <% } %>
            </form>
        </div>
        <div class="directory-table" role="region" aria-label="Police directory results" tabindex="0">
            <table>
                <thead>
                    <tr>
                        <th>Photo</th>
                        <th>Account Details</th>
                        <th>Rank / Designation</th>
                        <th>Deployment Station</th>
                    </tr>
                </thead>
                <tbody>
                <%
                    String sql = "SELECT u.FULL_NAME, u.USER_NAME, u.EMAIL, u.MOBILE, u.PROFILE_PICTURE, u.POLICE_ID, " +
                        "p.POST_NAME, p.POSTING_AREA, p.POSTING_CITY, p.POLICE_STATION " +
                        "FROM REGISTERED_USERS u " +
                        "LEFT JOIN POLICE_INFO p ON UPPER(TRIM(p.POLICE_ID)) = UPPER(TRIM(u.POLICE_ID)) " +
                        "WHERE LOWER(u.ROLE) = 'police'";
                    if (searchParam != null) {
                        sql += " AND (LOWER(u.FULL_NAME) LIKE ? OR LOWER(u.USER_NAME) LIKE ? OR LOWER(u.POLICE_ID) LIKE ?)";
                    }
                    sql += " ORDER BY u.ID ASC";
                    try (Connection conn = DBConnection.getConnection();
                         PreparedStatement stmt = conn.prepareStatement(sql)) {
                        if (searchParam != null) {
                            stmt.setString(1, searchParam);
                            stmt.setString(2, searchParam);
                            stmt.setString(3, searchParam);
                        }
                        try (ResultSet rs = stmt.executeQuery()) {
                            boolean hasResults = false;
                            while (rs.next()) {
                                hasResults = true;
                                String profileSrc = "images/default.png";
                                Blob profileBlob = rs.getBlob("PROFILE_PICTURE");
                                if (profileBlob != null) {
                                    try (InputStream stream = profileBlob.getBinaryStream();
                                         ByteArrayOutputStream bytes = new ByteArrayOutputStream()) {
                                        byte[] buffer = new byte[4096];
                                        int count;
                                        while ((count = stream.read(buffer)) != -1) bytes.write(buffer, 0, count);
                                        if (bytes.size() > 0) {
                                            // Use the image MIME type stored by your upload pipeline if available.
                                            profileSrc = "data:image/jpeg;base64," + Base64.getEncoder().encodeToString(bytes.toByteArray());
                                        }
                                    }
                                }
                %>
                    <tr>
                        <td><img src="<%= profileSrc %>" class="directory-avatar" alt="Officer profile picture"></td>
                        <td>
                            <div class="info-block">
                                <strong>Name:</strong> <%= displayValue(rs.getString("FULL_NAME")) %><br>
                                <strong>Username:</strong> <%= displayValue(rs.getString("USER_NAME")) %><br>
                                <strong>Police ID:</strong> <span class="strong-label"><%= displayValue(rs.getString("POLICE_ID")) %></span><br>
                                <strong>Email:</strong> <%= displayValue(rs.getString("EMAIL")) %><br>
                                <strong>Phone:</strong> <%= displayValue(rs.getString("MOBILE")) %>
                            </div>
                        </td>
                        <td><div class="info-block"><strong>Rank/Post:</strong> <span class="strong-label"><%= displayValue(rs.getString("POST_NAME")) %></span></div></td>
                        <td>
                            <div class="info-block">
                                <strong>City:</strong> <%= displayValue(rs.getString("POSTING_CITY")) %><br>
                                <strong>Police Station:</strong> <%= displayValue(rs.getString("POLICE_STATION")) %><br>
                                <strong>Posting Area:</strong> <%= displayValue(rs.getString("POSTING_AREA")) %>
                            </div>
                        </td>
                    </tr>
                <%
                            }
                            if (!hasResults) {
                %>
                    <tr><td colspan="4" class="empty-row">No matching police profiles found.</td></tr>
                <%
                            }
                        }
                    } catch (SQLException e) {
                        application.log("Police directory database error", e);
                %>
                    <tr><td colspan="4" class="empty-row">Unable to load the police directory. Please try again later.</td></tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>
    </div>
</body>
</html>
