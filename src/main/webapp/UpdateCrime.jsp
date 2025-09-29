<%@ page language="java" contentType="text/plain; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.sql.*" %>
<%
String action = request.getParameter("action");
String crimeIdStr = request.getParameter("crimeId");
String value = request.getParameter("value");

if(action == null || crimeIdStr == null){
    out.print("error: missing parameters");
    return;
}

int crimeId = Integer.parseInt(crimeIdStr);

try {
    Class.forName("oracle.jdbc.OracleDriver");
    Connection conn = DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:XE", "system", "a12345");
    PreparedStatement ps = null;

    switch(action){
        case "toggleIdentity":
            ps = conn.prepareStatement("UPDATE REPORTED_CRIMES SET HIDE_IDENTITY=? WHERE CRIME_ID=?");
            ps.setString(1, value);
            ps.setInt(2, crimeId);
            break;

        case "updateLocation":
            String[] locParts = value.split(",");
            if(locParts.length != 5){
                out.print("error: invalid location format");
                return;
            }
            ps = conn.prepareStatement("UPDATE REPORTED_CRIMES SET ZILLA=?, UPAZILLA=?, POLICE_STATION=?, ROAD_NAME=?, ROAD_NO=? WHERE CRIME_ID=?");
            for(int i=0;i<5;i++) ps.setString(i+1, locParts[i].trim());
            ps.setInt(6, crimeId);
            break;

        case "updateDate":
            ps = conn.prepareStatement("UPDATE REPORTED_CRIMES SET DATE_OF_INCIDENT=? WHERE CRIME_ID=?");
            ps.setString(1, value);
            ps.setInt(2, crimeId);
            break;
        
        case "updateDescription": // <-- new case added
            ps = conn.prepareStatement("UPDATE REPORTED_CRIMES SET DESCRIPTION=? WHERE CRIME_ID=?");
            ps.setString(1, value);
            ps.setInt(2, crimeId);
            break;

        default:
            out.print("error: unknown action");
            return;
    }

    int updated = ps.executeUpdate();
    ps.close();
    conn.close();

    if(updated > 0) out.print("success");
    else out.print("error: update failed");

} catch(Exception e){
    out.print("error: "+e.getMessage());
}
%>
