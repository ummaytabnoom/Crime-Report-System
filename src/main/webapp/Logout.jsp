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
    <title>Logout</title>
    <style>
       
        
       body {
    font-family: Arial, sans-serif;
    background-image: url("images/logoutBackground.jpg");
    background-size: cover;
    background-repeat: no-repeat;
    margin: 0;
    height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
}


        .logout-container {
            background-color: #E5CFFB;
            padding: 30px;
            border-radius: 10px;
            max-width: 500px;
            margin: auto;
            text-align: center;
        }

        .logout-container h2 {
            color: #333;
        }

        .logout-message {
            margin-bottom: 20px;
            color: green;
            font-weight: bold;
        }

        .mainHome-button {
            width: 100%;
            padding: 10px;
            background-color: #FF8C00;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
            font-size: 16px;
            transition: background-color 0.3s ease;
        }
        .login-wrapper {
            flex: 1;
            display: flex;
            justify-content: center;
            align-items: center;
            background-color: rgba(255, 255, 255, 0.2);
            padding: 20px;
        }
        .mainHome-button:hover {
            background-color: #e67300;
        }
    
    </style>
</head>
<body>
<div class="login-wrapper">
	<div class="logout-container">
   	 <h2>Thank you for your contribution.</h2>
   	 <p class="logout-message"><%= message %></p>
   	 <button onclick="location.href='MainHome.jsp'" class="mainHome-button">Return to Home</button>
	</div>
</div>
</body>
</html>
