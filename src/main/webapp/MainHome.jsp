<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Home Page</title>
    <style>
        body {
            margin: 0;
            padding: 0;
            background-image: url("images/HomePagePic.jpg");
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
            height: 100vh;
            font-family: Arial, sans-serif;
            color: white;
        }

        nav {
            background-color: rgba(0, 0, 0, 0.6);
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 10px 20px;
        }

        nav .nav-left h2 {
            margin: 0;
            color: #fff;
        }

        nav .nav-right a {
            color: white;
            text-decoration: none;
            margin-left: 20px;
            padding: 8px 12px;
            border-radius: 4px;
            background-color: #005F5F;
            transition: background 0.3s;
        }

        nav .nav-right a:hover {
            background-color: #0056b3;
        }

        .login-icon {
            background-image: url("images/login.jpg");
            background-size: cover;
            background-repeat: no-repeat;
            background-position: center;
            width: 30px;
            height: 30px;
            display: inline-block;
            vertical-align: middle;
            margin-right: 5px;
            border-radius: 50%;
        }

       .content {
    text-align: center;
    position: relative;
    top: 0;
    transform: none;
    color: #FF8C00;
}


.info-section {
    display: flex;
    justify-content: center;
    gap: 40px;
    margin-top: 30px;
    flex-wrap: wrap;
}

.info-card {
    background: rgba(0, 0, 0, 0.6);
    padding: 20px 25px;
    border-radius: 12px;
    width: 250px;
    color: #fff;
    text-align: center;
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.4);
    transition: transform 0.3s ease, background 0.3s ease;
    border: 1px solid #FF8C00;
}

.info-card:hover {
    transform: translateY(-8px);
    background: rgba(255, 140, 0, 0.8);
    color: #000;
}

.info-icon {
    font-size: 40px;
    margin-bottom: 10px;
}

    </style>
</head>
<body>
<body style="font-family: Arial; background-color: #FFD580; padding: 40px;">
    <!-- Navbar -->
    <nav>
        <div class="nav-left">
            <h2>Crime Report System</h2>
        </div>
        <div class="nav-right">
          <%String currentUser = (String) session.getAttribute("username");
          System.out.println(currentUser);

          if (currentUser == null) { %>
          <a href="Registration.jsp">Registration</a>
            <a href="Login.jsp">
                <span class="login-icon"></span> Login
            </a>
            <% } 
            else {
            	%>
            	<a href="UserHome.jsp">User Dashboard</a>
            	<a href="Logout.jsp">
                <span class="login-icon"></span> Logout</a>
            <% 
            }%>
            
        </div>
    </nav>

    <!-- Main Content -->
    <div class="content">
        <h1>Let’s Build Safer Roads!</h1>
<p>Share your road experiences — your voice helps us take action and protect our community.</p>


<h2 style="text-align: center; color: #FF8C00; margin-top: 40px; font-size: 32px; text-shadow: 1px 1px 4px #000;">
    The Vision Behind the site !?
</h2>


<div class="info-section">
    <div class="info-card">
        <div class="info-icon">🔍</div>
        <h3>Report Incidents</h3>
        <p>Your report could stop the next crime.</p>
    </div>
    <div class="info-card">
        <div class="info-icon">✔️</div>
        <h3>Admin Verified</h3>
        <p>Each report is carefully reviewed for action.</p>
    </div>
    <div class="info-card">
        <div class="info-icon">👮</div>
        <h3>Police In Action</h3>
        <p>We ensure justice by tracking and resolving cases.</p>
    </div>
</div>



    </div>

</body>
</html>

