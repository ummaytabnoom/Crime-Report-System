<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.util.*, java.io.*, java.util.Base64" %>
<%@ page import="utils.DBConnection" %>
<%
String currentUser = (String) session.getAttribute("username");
String userRole = (String) session.getAttribute("userRole");
boolean isAdmin = "admin".equals(userRole);
boolean isPolice = "police".equalsIgnoreCase(userRole);
String username = (String) session.getAttribute("username");

byte[] imageBytes = null;
List<Map<String, Object>> crimeList = new ArrayList<>();
String message = ""; // FIX: Declared the missing message variable here


// Load current user's profile picture
if (currentUser != null) {
    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;
    try {
conn = DBConnection.getConnection();

        String sql = "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME = ?";
        stmt = conn.prepareStatement(sql);
        stmt.setString(1, currentUser);
        rs = stmt.executeQuery();

        if (rs.next()) {
            Blob blob = rs.getBlob("PROFILE_PICTURE");
            if (blob != null) {
                InputStream is = blob.getBinaryStream();
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                byte[] buffer = new byte[1024];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) {
                    os.write(buffer, 0, bytesRead);
                }
                imageBytes = os.toByteArray();
                is.close();
            }
        }

        rs.close();
        stmt.close();
        conn.close();
    } catch (Exception e) {
        e.printStackTrace();
        message = "Error loading profile picture: " + e.getMessage();
    } finally {
        try { if (rs != null) rs.close(); } catch (SQLException e) { /* Ignored */ }
        try { if (stmt != null) stmt.close(); } catch (SQLException e) { /* Ignored */ }
        try { if (conn != null) conn.close(); } catch (SQLException e) { /* Ignored */ }
    }
}
// Get search query
String searchQuery = request.getParameter("search");
String searchParam = (searchQuery != null && !searchQuery.trim().isEmpty()) ? "%" + searchQuery.trim().toLowerCase() + "%" : null;
%>

<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1">
    <meta charset="UTF-8">
    <title>Admin Users</title>
    
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-admininfo">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>


<div class="navbar">
	<div class="top-right-buttons">
        <a href="UserHome.jsp">Dashboard</a>
    </div>

    <div class="user-info">
        <% if (imageBytes != null) { %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" alt="Profile Picture" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" alt="Default Profile Picture" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>


    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
         <% if(isAdmin){ %>
            <a href="AdminsHome.jsp">Admin Panel</a>
        <% } %>
        <% if(isPolice){ %>
            <a href="PoliceHome.jsp">Police Panel</a>
        <% } %>
        
        <a href="Settings.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
    <% if(message != null && !message.isEmpty()) { %>
        <div class="message error"><%= message %></div>
    <% } %>

    <h2>All Admin Users</h2>
    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name" value="<%= (searchQuery != null) ? searchQuery : "" %>" />
            <button type="submit">Search</button>
            <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                <button type="button" onclick="window.location='AdminInfo.jsp'">Clear</button>
            <% } %>
        </form>
    </div>
    <div class="directory-table" role="region" aria-label="Directory results" tabindex="0">
    <table>
        <tr>
            <th>Profile Picture</th>
            <th>Full Name</th>
            <th>Username</th>
            <th>Email</th>
            <th>Mobile</th>
        </tr>
        <%
            Connection conn = null;
            PreparedStatement stmt = null;
            ResultSet rs = null;
            try {
conn = DBConnection.getConnection();

                String sql;
                if (searchParam != null) {
                    sql = "SELECT FULL_NAME, USER_NAME, EMAIL, MOBILE, PROFILE_PICTURE FROM REGISTERED_USERS " +
                          "WHERE ROLE = 'admin' AND (LOWER(FULL_NAME) LIKE ? OR LOWER(USER_NAME) LIKE ?)";
                } else {
                    sql = "SELECT FULL_NAME, USER_NAME, EMAIL, MOBILE, PROFILE_PICTURE FROM REGISTERED_USERS " +
                          "WHERE ROLE = 'admin'";
                }
                
                stmt = conn.prepareStatement(sql);

                if (searchParam != null) {
                    stmt.setString(1, searchParam);
                    stmt.setString(2, searchParam);
                }

                rs = stmt.executeQuery();
                
                if (!rs.isBeforeFirst() && searchParam != null) {
                    out.println("<tr><td colspan='5'>No admin users found with that name or username.</td></tr>");
                }

                while (rs.next()) {
                    String fullName = rs.getString("FULL_NAME");
                    String userName = rs.getString("USER_NAME");
                    String email = rs.getString("EMAIL");
                    String mobile = rs.getString("MOBILE");
                    Blob blob = rs.getBlob("PROFILE_PICTURE");
                    String base64Image = "";
                    if (blob != null) {
                        InputStream inputStream = blob.getBinaryStream();
                        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                        byte[] buffer = new byte[4096];
                        int bytesRead;
                        while ((bytesRead = inputStream.read(buffer)) != -1) {
                            outputStream.write(buffer, 0, bytesRead);
                        }
                        byte[] adminImageBytes = outputStream.toByteArray();
                        base64Image = Base64.getEncoder().encodeToString(adminImageBytes);
                        inputStream.close();
                        outputStream.close();
                    }
        %>
        <tr>
            <td>
                <% if (!base64Image.equals("")) { %>
                    <img src="data:image/jpeg;base64,<%= base64Image %>" class="directory-avatar"/>
                <% } else { %>
                    <img src="images/default.png" class="directory-avatar"/>
                <% } %>
            </td>
            <td><%= fullName %></td>
            <td><%= userName %></td>
            <td><%= email %></td>
            <td><%= mobile %></td>
        </tr>
        <%
                }
            } catch (Exception e) {
                out.println("<tr><td colspan='5' class='error-message'>Database error: " + e.getMessage() + "</td></tr>");
                e.printStackTrace();
            } finally {
                if (rs != null) try { rs.close(); } catch (SQLException e) { /* Ignored */ }
                if (stmt != null) try { stmt.close(); } catch (SQLException e) { /* Ignored */ }
                if (conn != null) try { conn.close(); } catch (SQLException e) { /* Ignored */ }
            }
        %>
    </table>
    </div>
</div>

<script>
    function toggleMenu() {
        document.getElementById("dropdownMenu").classList.toggle("show");
    }
</script>

</body>
</html>