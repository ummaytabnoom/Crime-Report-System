<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    // Invalidate session to log out the user
    session.invalidate();

    // Optional: Set a logout success message
    String message = "You have been logged out successfully.";
%>
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Logout</title>
    
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-logout">
<div class="login-wrapper">
	<div class="logout-container">
   	 <h2>Thank you for your contribution.</h2>
   	 <p class="logout-message"><%= message %></p>
   	 <button onclick="location.href='MainHome.jsp'" class="mainHome-button">Return to Home</button>
	</div>
</div>
</body>
</html>
