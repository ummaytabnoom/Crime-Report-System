<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="java.sql.*, java.io.*, java.util.Base64" %>
<%@ page import="utils.DBConnection" %>

<%
    // --- Get current user info for navbar ---
    Integer currentUserId = (Integer) session.getAttribute("userId"); // safer as Integer
    String userRole = (String) session.getAttribute("userRole");
    boolean isAdmin = "admin".equals(userRole);
    String currentUserName = "";
    byte[] imageBytes = null;
    String message = "";
    
    
// ONLY ADMIN 
if (currentUserId == null) {
    response.sendRedirect("Login.jsp");
    return;
}
if (!isAdmin) {
	response.sendRedirect("MainHome.jsp");
    return;
}

    if (currentUserId != null) {
        try {
Connection conn = DBConnection.getConnection();

            String sql = "SELECT USER_NAME, PROFILE_PICTURE FROM REGISTERED_USERS WHERE ID = ?";
            PreparedStatement stmt = conn.prepareStatement(sql);
            stmt.setInt(1, currentUserId);
            ResultSet rs = stmt.executeQuery();

            if (rs.next()) {
                currentUserName = rs.getString("USER_NAME");
                Blob blob = rs.getBlob("PROFILE_PICTURE");
                if (blob != null) {
                    try (InputStream is = blob.getBinaryStream(); ByteArrayOutputStream os = new ByteArrayOutputStream()) {
                        byte[] buffer = new byte[1024];
                        int bytesRead;
                        while ((bytesRead = is.read(buffer)) != -1) os.write(buffer, 0, bytesRead);
                        imageBytes = os.toByteArray();
                    }
                }
            } else {
                message = "User not found.";
            }

            rs.close();
            stmt.close();
            conn.close();
        } catch (Exception e) {
            e.printStackTrace();
            message = "Error loading user data: " + e.getMessage();
        }
    } else {
        message = "User is not logged in.";
    }

    // --- Handle update/delete actions ---
    if ("POST".equalsIgnoreCase(request.getMethod()) && request.getParameter("action") != null) {
        String action = request.getParameter("action");
        int id = Integer.parseInt(request.getParameter("id"));

        try {
Connection conn = DBConnection.getConnection();

            if ("update".equals(action)) {
                String newRole = request.getParameter("newRole");
                String updateSQL = "UPDATE REGISTERED_USERS SET ROLE = ? WHERE ID = ?";
                PreparedStatement pstmt = conn.prepareStatement(updateSQL);
                pstmt.setString(1, newRole);
                pstmt.setInt(2, id);
                pstmt.executeUpdate();
                pstmt.close();
            } else if ("delete".equals(action)) {
                String deleteSQL = "DELETE FROM REGISTERED_USERS WHERE ID = ?";
                PreparedStatement pstmt = conn.prepareStatement(deleteSQL);
                pstmt.setInt(1, id);
                pstmt.executeUpdate();
                pstmt.close();
            }

            conn.close();
        } catch (Exception e) {
            out.println("<p class='message error'>Action Error: " + e.getMessage() + "</p>");
        }
    }

    // --- Get search query ---
    String searchQuery = request.getParameter("search");
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Admin Panel - User Management</title>
    
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-usermanage">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>


<div class="navbar">
    <div class="navbar-title">
        <div class="user-info">
            <% 
                if (imageBytes != null && imageBytes.length > 0) { 
                    String base64Image = Base64.getEncoder().encodeToString(imageBytes);
            %>
                <img src="data:image/jpeg;base64,<%= base64Image %>" alt="Profile Picture" class="user-pic">
            <% } else { %>
                <img src="images/default.png" alt="Default Profile Picture" class="user-pic">
            <% } %>
            <span class="user-name"> <%= currentUserName %></span>
        </div>
    </div>
        
    <div class="top-right-buttons">
        <a href="UserHome.jsp">Dashboard</a>
        <a href="MyReports.jsp">My Reports</a>
        <a href="ReportSub.jsp">Report Crime</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="AdminsHome.jsp">Admin Penel</a>
        <a href="Settings.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="content-box">
    <h2>User Management Panel</h2>

    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name" value="<%= (searchQuery != null) ? searchQuery : "" %>" />
            <button type="submit">Search</button>
            <% if (searchQuery != null && !searchQuery.trim().isEmpty()) { %>
                <button type="button" onclick="window.location='UserManage.jsp'">Clear</button>
            <% } %>
        </form>
    </div>

<%
    // --- Fetch user list ---
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    try {
conn = DBConnection.getConnection();

        String sql;
        if (searchQuery != null && !searchQuery.trim().isEmpty()) {
            sql = "SELECT ID, FULL_NAME, USER_NAME, EMAIL, DOB, MOBILE, ROLE, PROFILE_PICTURE FROM REGISTERED_USERS WHERE LOWER(FULL_NAME) LIKE ? OR LOWER(USER_NAME) LIKE ?";
            pstmt = conn.prepareStatement(sql);
            String pattern = "%" + searchQuery.toLowerCase() + "%";
            pstmt.setString(1, pattern);
            pstmt.setString(2, pattern);
        } else {
            sql = "SELECT ID, FULL_NAME, USER_NAME, EMAIL, DOB, MOBILE, ROLE, PROFILE_PICTURE FROM REGISTERED_USERS";
            pstmt = conn.prepareStatement(sql);
        }

        rs = pstmt.executeQuery();
%>

    <div class="directory-table" role="region" aria-label="Directory results" tabindex="0">
    <table>
        <tr>
            <th>Profile</th>
            <th>Full Name</th>
            <th>Username</th>
            <th>Email</th>
            <th>DOB</th>
            <th>Mobile</th>
            <th>Role</th>
            <th>Change Role</th>
            <th>Delete</th>
        </tr>

<%
    while (rs.next()) {
        int id = rs.getInt("ID");
        String fullName = rs.getString("FULL_NAME");
        String userName = rs.getString("USER_NAME");
        String email = rs.getString("EMAIL");
        Date dob = rs.getDate("DOB");
        String mobile = rs.getString("MOBILE");
        String role = rs.getString("ROLE");
        Blob blob = rs.getBlob("PROFILE_PICTURE");
        String base64Image = "";

        if (blob != null) {
            try (InputStream is = blob.getBinaryStream(); ByteArrayOutputStream os = new ByteArrayOutputStream()) {
                byte[] buffer = new byte[4096];
                int bytesRead;
                while ((bytesRead = is.read(buffer)) != -1) os.write(buffer, 0, bytesRead);
                base64Image = Base64.getEncoder().encodeToString(os.toByteArray());
            } catch (Exception ex) { base64Image = ""; }
        }
%>
        <tr>
            <td>
                <% if (!base64Image.equals("")) { %>
                    <img src="data:image/jpeg;base64,<%= base64Image %>" class="directory-avatar" />
                <% } else { %>
                    <img src="images/default.png" class="directory-avatar" alt="Default profile">
                <% } %>
            </td>
            <td><%= fullName %></td>
            <td><%= userName %></td>
            <td><%= email %></td>
            <td><%= dob %></td>
            <td><%= mobile %></td>
            <td><%= role %></td>
            <td>
                <form method="post" class="inline">
                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="action" value="update">
                    <select name="newRole">
                        <option value="public" <%= "public".equals(role)?"selected":"" %>>Public</option>
                        <option value="admin" <%= "admin".equals(role)?"selected":"" %>>Admin</option>
                        <option value="police" <%= "police".equals(role)?"selected":"" %>>Police</option>
                    </select>
                    <input type="submit" value="Change" class="btn-change">
                </form>
            </td>
            <td>
                <form method="post" class="inline" onsubmit="return confirm('Are you sure to delete?');">
                    <input type="hidden" name="id" value="<%= id %>">
                    <input type="hidden" name="action" value="delete">
                    <input type="submit" value="Delete" class="btn-delete">
                </form>
            </td>
        </tr>
<% } %>
    </table>
    </div>

<%
    } catch (Exception e) { out.println("<p class='message error'>Database Error: " + e.getMessage() + "</p>"); }
    finally {
        if(rs != null) try{rs.close();} catch(Exception ignored){}
        if(pstmt != null) try{pstmt.close();} catch(Exception ignored){}
        if(conn != null) try{conn.close();} catch(Exception ignored){}
    }
%>
</div>

<script>
function showUserInfo(fullName, userName, mobile, profileImg) {
    const imgEl = document.getElementById("modalProfileImg");

    if(profileImg && profileImg !== "") {
        imgEl.src = "data:image/jpeg;base64," + profileImg;
        imgEl.style.display = "block";
    } else {
        imgEl.src = "images/default.png";
        imgEl.style.display = "block";
    }

    document.getElementById("modalFullName").innerText = "Full Name: " + fullName;
    document.getElementById("modalUsername").innerText = "Username: " + userName;
    document.getElementById("modalMobile").innerText = "Mobile No: " + mobile;

    document.getElementById("userModal").style.display = "flex";
}

function closeModal() {
    document.getElementById("userModal").style.display = "none";
}


function toggleMenu() {
    document.getElementById("dropdownMenu").classList.toggle("show");
}


function filterCrimes() {
    const input = document.getElementById("searchInput").value.toLowerCase();
    const containers = document.getElementsByClassName("crime-container");

    for (let i = 0; i < containers.length; i++) {
        const text = containers[i].innerText.toLowerCase();
        containers[i].style.display = text.includes(input) ? "block" : "none";
    }
}


window.onclick = function(event) {
    if (!event.target.matches('.menu-icon')) {
        let dropdown = document.getElementById("dropdownMenu");
        if (dropdown.classList.contains("show")) {
            dropdown.classList.remove("show");
        }
    }
}
</script>

</body>
</html>
