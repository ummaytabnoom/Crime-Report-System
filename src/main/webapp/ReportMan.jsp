
<%@ page language="java" contentType="text/html; charset=UTF-8"
    pageEncoding="UTF-8" isELIgnored="false" %>

<%@ page import="java.sql.*" %>
<%@ page import="java.io.*" %>
<%@ page import="java.util.*" %>
<%@ page import="java.util.Base64" %>
<%@ page import="java.text.SimpleDateFormat" %>
<%@ page import="utils.DBConnection" %>

<%
    String currentUser = (String) session.getAttribute("username");

    if(currentUser == null){
        response.sendRedirect("Login.jsp");
        return;
    }

    byte[] imageBytes = null;
    List<Map<String,Object>> crimeList = new ArrayList<>();
    String message = "";

    Connection conn = null;
    PreparedStatement stmt = null;
    ResultSet rs = null;

    try{
conn = DBConnection.getConnection();

        /* =========================================================
           HANDLE POST REQUESTS
        ========================================================= */
        if("POST".equalsIgnoreCase(request.getMethod())){
            String action = request.getParameter("action");
            String crimeIdParam = request.getParameter("crimeId");

            if(action != null && crimeIdParam != null){
                int crimeId = Integer.parseInt(crimeIdParam);

                /* =====================================================
                   DELETE REPORT
                ===================================================== */
                if("delete".equalsIgnoreCase(action)){
                    PreparedStatement delStmt = conn.prepareStatement(
                        "DELETE FROM REPORTED_CRIMES WHERE CRIME_ID=?"
                    );
                    delStmt.setInt(1, crimeId);
                    int deleted = delStmt.executeUpdate();
                    delStmt.close();

                    if(deleted > 0){
                        message = "Crime report deleted successfully.";
                    } else {
                        message = "Failed to delete report.";
                    }
                }
                /* =====================================================
                   ACCEPT REPORT (UPDATES BOTH TEXT TRACKING FIELDS)
                ===================================================== */
                else if("accepted".equalsIgnoreCase(action)){
                    PreparedStatement updateStmt = conn.prepareStatement(
                        "UPDATE REPORTED_CRIMES SET ACCEPTED='ACCEPTED', ACCEPTED_BY=? WHERE CRIME_ID=?"
                    );
                    updateStmt.setString(1, currentUser);
                    updateStmt.setInt(2, crimeId);
                    
                    int updated = updateStmt.executeUpdate();
                    updateStmt.close();

                    if(updated > 0){
                        message = "Report approved successfully!";
                    } else {
                        message = "Failed to accept report.";
                    }
                }
            }
        }

        /* =========================================================
           FETCH CURRENT ADMIN PROFILE PICTURE
        ========================================================= */
        stmt = conn.prepareStatement(
            "SELECT PROFILE_PICTURE FROM REGISTERED_USERS WHERE USER_NAME=?"
        );
        stmt.setString(1, currentUser);
        rs = stmt.executeQuery();

        if(rs.next()){
            Blob blob = rs.getBlob("PROFILE_PICTURE");
            if(blob != null){
                InputStream is = blob.getBinaryStream();
                ByteArrayOutputStream os = new ByteArrayOutputStream();
                byte[] buffer = new byte[1024];
                int bytesRead;
                while((bytesRead = is.read(buffer)) != -1){
                    os.write(buffer,0,bytesRead);
                }
                imageBytes = os.toByteArray();
                is.close();
            }
        }
        rs.close();
        stmt.close();

        /* =========================================================
           SEARCH AND FETCH ALL REPORTS FROM REPORTED_CRIMES
        ========================================================= */
        String searchQuery = request.getParameter("search");
        String sql = "SELECT * FROM REPORTED_CRIMES ";

        if(searchQuery != null && !searchQuery.trim().isEmpty()){
            sql += "WHERE USER_NAME LIKE ? OR FULL_NAME LIKE ? ";
        }
        sql += "ORDER BY CRIME_ID DESC";

        PreparedStatement ps = conn.prepareStatement(sql);
        int paramIndex = 1;

        if(searchQuery != null && !searchQuery.trim().isEmpty()){
            ps.setString(paramIndex++, "%" + searchQuery + "%");
            ps.setString(paramIndex++, "%" + searchQuery + "%");
        }

        ResultSet crimesRs = ps.executeQuery();
        SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");

        while(crimesRs.next()){
            Map<String,Object> crime = new HashMap<>();
            String hideIdentity = crimesRs.getString("HIDE_IDENTITY");

            crime.put("crimeId", crimesRs.getInt("CRIME_ID"));
            crime.put("category", crimesRs.getString("CATEGORY"));
            crime.put("description", crimesRs.getString("DESCRIPTION"));
            crime.put("status", crimesRs.getString("STATUS")); 
            crime.put("acceptedBy", crimesRs.getString("ACCEPTED_BY")); 
            crime.put("accepted", crimesRs.getString("ACCEPTED"));

            Timestamp ts = crimesRs.getTimestamp("DATE_OF_INCIDENT");
            String formattedDate = (ts != null) ? sdf.format(ts) : "";
            crime.put("date", formattedDate);

            // CHANGED: Added structural string building mapping to print the explicit crime area column
            String areaVal = crimesRs.getString("AREA");
            String location = crimesRs.getString("ZILLA") + ", " +
                              crimesRs.getString("UPAZILLA") + ", " +
                              crimesRs.getString("POLICE_STATION") + ", " +
                              ((areaVal != null && !areaVal.trim().isEmpty()) ? areaVal.trim() + ", " : "") +
                              crimesRs.getString("ROAD_NAME") + ", Road No: " +
                              crimesRs.getString("ROAD_NO");
            crime.put("fullLocation", location);

         // Fetch media file and media type
            byte[] mediaBytes = crimesRs.getBytes("MEDIA_FILE");
            String mediaType = crimesRs.getString("MEDIA_TYPE");

            crime.put("mediaType", mediaType);

            if (mediaBytes != null) {
                crime.put("mediaData", Base64.getEncoder().encodeToString(mediaBytes));
            } else {
                crime.put("mediaData", "");
            }
            /* ==============================================
               GET REPORTER INFORMATION
            ============================================== */
            PreparedStatement userStmt = conn.prepareStatement(
                "SELECT PROFILE_PICTURE, MOBILE, FULL_NAME, USER_NAME FROM REGISTERED_USERS WHERE USER_NAME=?"
            );
            userStmt.setString(1, crimesRs.getString("USER_NAME"));
            ResultSet userRs = userStmt.executeQuery();

            String profileImg = "";
            String mobileNo = "";
            String fullNameReal = "";
            String userNameReal = "";

            if(userRs.next()){
                byte[] profileBytes = userRs.getBytes("PROFILE_PICTURE");
                if(profileBytes != null){
                    profileImg = Base64.getEncoder().encodeToString(profileBytes);
                }
                mobileNo = userRs.getString("MOBILE");
                fullNameReal = userRs.getString("FULL_NAME");
                userNameReal = userRs.getString("USER_NAME");
            }
            userRs.close();
            userStmt.close();

            crime.put("profileImg", profileImg);
            crime.put("mobileNo", mobileNo);
            crime.put("realFullName", fullNameReal);
            crime.put("realUsername", userNameReal);

            if("YES".equalsIgnoreCase(hideIdentity)){
                crime.put("displayName", "Anonymous");
                crime.put("displayUsername", "");
            } else {
                crime.put("displayName", fullNameReal);
                crime.put("displayUsername", "@" + userNameReal);
            }

            crimeList.add(crime);
        }
        crimesRs.close();
        ps.close();
    }
    catch(Exception e){
        out.println("<p class='message error'>Error: " + e.getMessage() + "</p>");
    }
    finally{
        try{ if(rs != null) rs.close(); }catch(Exception e){}
        try{ if(stmt != null) stmt.close(); }catch(Exception e){}
        try{ if(conn != null) conn.close(); }catch(Exception e){}
    }
%>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Report Management</title>

<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-reportman">
<%@ include file="/WEB-INF/jspf/navbar.jspf" %>


<div class="navbar">
    <div class="user-info">
        <% if(imageBytes != null){ %>
            <img class="user-pic" src="data:image/jpeg;base64,<%= Base64.getEncoder().encodeToString(imageBytes) %>" />
        <% } else { %>
            <img class="user-pic" src="images/default.png" />
        <% } %>
        <span class="user-name"><%= currentUser %></span>
    </div>
    <div class="top-right-buttons">
        <a href="UserHome.jsp">Dashboard</a>
    </div>
    <div class="menu-icon" onclick="toggleMenu()">☰</div>
    <div id="dropdownMenu" class="dropdown">
        <a href="AdminsHome.jsp">Admin Panel</a>
        <a href="Settings.jsp">Settings</a>
        <a href="Logout.jsp">Logout</a>
    </div>
</div>

<div class="post-content-box">
    <h2>Report Management Panel</h2>

    <% if(!message.isEmpty()){ %>
        <p class="message" data-toast><%= message %></p>
    <% } %>

    <div class="search-bar">
        <form method="get">
            <input type="text" name="search" placeholder="Search by username or full name">
            <button type="submit">Search</button>
        </form>
    </div>

    <% 
    if(crimeList != null && !crimeList.isEmpty()){
        for(Map<String,Object> crime : crimeList){
            String status = (String) crime.get("status");
            String acceptedBy = (String) crime.get("acceptedBy");
            String dbAcceptedField = (String) crime.get("accepted");
            
            boolean isAllowedByAdmin = false;
            if(dbAcceptedField != null) {
                String cleanVal = dbAcceptedField.replaceAll("\\s+", "").toLowerCase();
                if(cleanVal.contains("accepted") && !cleanVal.contains("notaccepted")) {
                    isAllowedByAdmin = true;
                }
            }
    %>
    <div class="crime-container">
        <% 
        String profileImg = (String) crime.get("profileImg");
        if(profileImg != null && !profileImg.isEmpty()){ 
        %>
            <img src="data:image/jpeg;base64,<%= profileImg %>" class="profile-image" />
        <% } else { %>
            <img src="images/default.png" class="profile-image" />
        <% } %>

        <h3>
            <%= crime.get("displayName") %>
            <small class="report-username"><%= crime.get("displayUsername") %></small>
        </h3>
        <p><strong>Category:</strong> <%= crime.get("category") %></p>
        <p><strong>Location:</strong> <%= crime.get("fullLocation") %></p>
        <p><strong>Date:</strong> <%= crime.get("date") %></p>
        <p><strong>Description:</strong> <%= crime.get("description") %></p>
        
        <p><strong>Status:</strong> <%= status %></p>
        
        <p><strong>Verification State:</strong> 
           <span class="status-badge <%= isAllowedByAdmin ? "text-success" : "text-danger" %>">
               <%= dbAcceptedField %>
           </span>
        </p>
        
        <% if(isAllowedByAdmin) { %>
            <p class="text-bold">
                <strong>Accepted By:</strong> <%= acceptedBy == null || String.valueOf(acceptedBy).trim().isEmpty() ? "Not reviewed" : "@" + acceptedBy %>
            </p>
        <% } %>

        <%
String mediaData = (String) crime.get("mediaData");
String mediaType = (String) crime.get("mediaType");

if (mediaData != null && !mediaData.isEmpty()) {

    if (mediaType != null && mediaType.startsWith("image/")) {
%>

        <img src="data:<%=mediaType%>;base64,<%=mediaData%>" class="crime-image">

<%
    } else if (mediaType != null && mediaType.startsWith("video/")) {
%>

        <video class="crime-video" controls width="350">
            <source src="data:<%=mediaType%>;base64,<%=mediaData%>" type="<%=mediaType%>">
            Your browser does not support the video tag.
        </video>

<%
    } else {
%>

        <p><i>Unsupported media type.</i></p>

<%
    }

} else {
%>

    <p><i>No media uploaded.</i></p>

<%
}
%>

        <div class="status-buttons">
            <% if(isAllowedByAdmin) { %>
                <button class="btn" disabled>ACCEPTED</button>

                <form method="post" onsubmit="return confirm('Delete this report?');">
                    <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                    <input type="hidden" name="action" value="delete">
                    <button type="submit" class="btn delete-btn">Delete Report</button>
                </form>
            <% } else { %>
                <form method="post">
                    <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                    <input type="hidden" name="action" value="accepted">
                    <button type="submit" class="btn allow-btn">Allow Post</button>
                </form>

                <form method="post" onsubmit="return confirm('Delete this report?');">
                    <input type="hidden" name="crimeId" value="<%= crime.get("crimeId") %>">
                    <input type="hidden" name="action" value="delete">
                    <button type="submit" class="btn delete-btn">Delete Report</button>
                </form>
            <% } %>
        </div>
    </div>
    <% 
        }
    } else { 
    %>
        <p class="centered-lead">No crime reports found.</p>
    <% } %>
</div>

<script>
    function toggleMenu() {
        var menu = document.getElementById("dropdownMenu");
        menu.classList.toggle("show");
    }

    window.onclick = function(event) {
        if (!event.target.matches('.menu-icon')) {
            var dropdowns = document.getElementsByClassName("dropdown");
            for (var i = 0; i < dropdowns.length; i++) {
                dropdowns[i].classList.remove("show");
            }
        }
    }
</script>
</body>
</html>

```