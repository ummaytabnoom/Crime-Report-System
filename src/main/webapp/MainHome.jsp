<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String currentUser = (String) session.getAttribute("username");
    String currentRole = (String) session.getAttribute("userRole");
    String dashboard = "admin".equalsIgnoreCase(currentRole) ? "AdminsHome.jsp" : ("police".equalsIgnoreCase(currentRole) ? "PoliceHome.jsp" : "UserHome.jsp");
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Crime Report System</title>
<%@ include file="/WEB-INF/jspf/common-assets.jspf" %>
</head>
<body class="modern page-mainhome">
<div class="page">
    <header class="nav">
        <a class="brand" href="MainHome.jsp">
            <img class="brand-mark" src="images/crslogo.png" alt="">
            <span>Crime Report System</span>
        </a>
        <nav class="nav-links" aria-label="Main navigation">
            <a href="#home">Home</a>
            <a href="#mission">About</a>
            <a href="#features">Features</a>
        </nav>
        <div class="nav-actions">
            
            <% if (currentUser == null) { %>
                <a class="btn btn-outline" href="Login.jsp">Login</a>
                <a class="btn btn-primary" href="Registration.jsp">Register</a>
            <% } else { %>
                <a class="btn btn-primary" href="<%= dashboard %>">Dashboard</a>
                <a class="btn btn-outline" href="Logout.jsp">Logout</a>
            <% } %>
        </div>
    </header>

    <main id="home">
        <section class="hero">
            <div class="container">
                <div class="hero-content">
                    
                    <h1>Report crimes<br><span class="gradient-text bangla-font">নিরাপদ সমাজ গড়ে তুলুন ।</span></h1>
                    <p>Share incidents safely, track their progress, and help police act fast. Every report makes your neighborhood safer.</p>
                    <div class="hero-actions">
                        <a class="btn btn-primary" href="<%= currentUser == null ? "Login.jsp" : ("public".equalsIgnoreCase(currentRole) ? "ReportSub.jsp" : dashboard) %>">Report a Crime →</a>
                        <a class="btn btn-outline" href="#features">Learn More</a>
                    </div>
                    <div class="trust-row">
                        
<div class="trust-item">
  <span class="trust-icon">
    <img src="images/document-outline.svg" alt="Document" />
  </span>
  <span>
    <strong class="bangla-font">সহজ রিপোর্টিং</strong><br />
    Submit in minutes
  </span>
</div>

<div class="trust-item">
  <span class="trust-icon">
    <img src="images/location-outline.svg" alt="Location" />
  </span>
  <span>
    <strong class="bangla-font">অবস্থা দেখুন</strong><br />
    Stay updated
  </span>
</div>

<div class="trust-item">
  <span class="trust-icon">
    <img src="images/lock-closed-outline.svg" alt="Privacy" />
  </span>
  <span>
    <strong class="bangla-font">গোপনীয়</strong><br />
    Your data is protected
  </span>
</div>
                        
                    </div>
                </div>
            </div>
        </section>

<!-- Why Our System Section -->
<section class="why-section" id="why-system">
  <div class="container">

    <div class="why-section-header ">
     
      <h2>একসাথে গড়ি একটি নিরাপদ সমাজ</h2>
      <p class="bangla-font-m">
        Technology এবং সচেতনতার মাধ্যমে Crime Reporting
        হোক আরও সহজ, দ্রুত ও নিরাপদ।
      </p>
    </div>

    <!-- 1. Why Our System -->
    <div class="why-row">
      <div class="why-visual">
        <img src="${pageContext.request.contextPath}/images/why.svg"
             alt="Why our system" loading="lazy">
      </div>
      <div class="why-content">
   
        <h3 class="bangla-font">কেন আমাদের সিস্টেম?</h3>
        <p class="bangla-font-m">
          অনেক সময় অপরাধের ঘটনা ঘটলেও সঠিক জায়গায়
          Report করা কঠিন হয়ে যায়। আমাদের Crime Report
          System তৈরি করা হয়েছে এই প্রক্রিয়াকে আরও
          সহজ ও Accessible করার জন্য।
        </p>
        <p class="bangla-font-m">
          একটি Digital Platform-এর মাধ্যমে নাগরিকরা
          সহজেই Incident Report করতে পারবেন এবং
          তাদের Report-এর বর্তমান Status জানতে পারবেন।
        </p>
      </div>
    </div>

    <!-- 2. Crime Awareness -->
    <div class="why-row reverse">
      <div class="why-visual">
        <img src="${pageContext.request.contextPath}/images/criminal.svg"
             alt="Crime awareness" loading="lazy">
      </div>
      <div class="why-content">
       
        <h3 class="bangla-font">অপরাধের বিরুদ্ধে সচেতনতা</h3>
        <p class="bangla-font-m">
          অপরাধ প্রতিরোধের প্রথম ধাপ হলো সচেতনতা।
          ছোট কিংবা বড়, যেকোনো অপরাধের তথ্য
          সঠিক কর্তৃপক্ষের কাছে পৌঁছানো গুরুত্বপূর্ণ।
        </p>
        <p class="bangla-font-m">
          আমাদের System নাগরিকদের Responsible
          Reporting-এ উৎসাহিত করে, যাতে অপরাধের
          তথ্য হারিয়ে না যায় এবং প্রয়োজনীয়
          পদক্ষেপ নেওয়া সম্ভব হয়।
        </p>
      </div>
    </div>

    <!-- 3. Easy Reporting -->
    <div class="why-row">
      <div class="why-visual">
        <img src="${pageContext.request.contextPath}/images/report.svg"
             alt="Online crime reporting" loading="lazy">
      </div>
      <div class="why-content">
       
        <h3 class="bangla-font">সহজেই Crime Report করুন</h3>
        <p class="bangla-font-m">
          Crime Report করার জন্য জটিল কোনো
          Process-এর প্রয়োজন নেই। আমাদের
          User-Friendly Form ব্যবহার করে
          ঘটনার বিবরণ, Location এবং প্রয়োজনীয়
          Evidence Submit করতে পারবেন।
        </p>
        <p class="bangla-font-m">
          Report Submit করার পর Dashboard থেকে
          আপনার Complaint-এর Status এবং
          Progress Update দেখতে পারবেন।
        </p>
      </div>
    </div>

    <!-- 4. Police Investigation -->
    <div class="why-row reverse">
      <div class="why-visual">
        <img src="${pageContext.request.contextPath}/images/police.svg"
             alt="Police investigation" loading="lazy">
      </div>
      <div class="why-content">
      
        <h3 class="bangla-font">Police Investigation ও Updates</h3>
        <p class="bangla-font-m">
          একটি Report Submit হওয়ার পর
          Authorized Police Personnel সেটি
          Review করতে পারবেন এবং প্রয়োজন
          অনুযায়ী Investigation Process
          পরিচালনা করতে পারবেন।
        </p>
        <p class="bangla-font-m">
          Report Status Update করার মাধ্যমে
          নাগরিকরা তাদের অভিযোগের Progress
          সম্পর্কে জানতে পারবেন। এতে
          Communication এবং Transparency
          বজায় রাখা সহজ হয়।
        </p>
      </div>
    </div>

    <!-- 5. Safer Community -->
    <div class="why-row">
      <div class="why-visual">
        <img src="${pageContext.request.contextPath}/images/happy.svg"
             alt="Safe and happy community" loading="lazy">
      </div>
      <div class="why-content">
        
        <h3 class="bangla-font">একটি নিরাপদ ও সুন্দর আগামী</h3>
        <p class="bangla-font-m">
          আমাদের লক্ষ্য শুধু Crime Report
          সংগ্রহ করা নয়, বরং নাগরিক ও
          Law Enforcement-এর মধ্যে একটি
          কার্যকর Digital Connection তৈরি করা।
        </p>
        <p class="bangla-font-m">
          সচেতন নাগরিক, Responsible Reporting
          এবং সঠিক সহযোগিতার মাধ্যমে আমরা
          সবাই মিলে একটি নিরাপদ ও সুন্দর
          সমাজ গড়ে তুলতে পারি।
        </p>
      </div>
    </div>

  </div>
</section>

        <section class="section" id="features">
            <div class="container">
                <div class="section-header" id="mission">
                    <h2>Everything you need to report responsibly</h2>
                    <p>A focused workflow for citizens, police personnel, and administrators.</p>
                </div>
                <div class="grid-3">
                    <article class="card feature-card">
                        <div class="feature-icon"> <img src="images/document-outline.svg" alt="Document" /></div>
                        <h3>Report incidents</h3>
                        <p>Submit accurate incident details, location information, and supporting evidence through a simple guided form.</p>
                    </article>
                    <article class="card feature-card">
                        <div class="feature-icon"><img src="images/lock-closed-outline.svg" alt="Privacy" /></div>
                        <h3>Verified workflow</h3>
                        <p>Reports move through review and verification so authorized teams can focus on credible cases.</p>
                    </article>
                    <article class="card feature-card">
                        <div class="feature-icon"><img src="images/location-outline.svg" alt="Location" /></div>
                        <h3>Track progress</h3>
                        <p>Follow report status and updates from submission through investigation and resolution.</p>
                    </article>
                </div>
            </div>
        </section>
    </main>
    
    
<!-- Main Footer -->
<footer class="crs-footer">
  <div class="container">

    <div class="crs-footer-main">

      <!-- Brand -->
      <div class="crs-footer-brand">
        <a href="MainHome.jsp" class="crs-footer-logo">
          <img
            src="${pageContext.request.contextPath}/images/crslogo.png"
            alt="Crime Report System Logo"
          />
          <span>Crime Report System</span>
        </a>

        <p>
          A safer community starts with awareness.
          Report incidents responsibly, stay informed,
          and help build a better tomorrow.
        </p>
      </div>

      <!-- Quick Links -->
      <div class="crs-footer-column">
        <h3>Quick Links</h3>
        <nav aria-label="Footer navigation">
          <a href="#home">Home</a>
          <a href="#why-system">Why Our System</a>
          <a href="#mission">About Us</a>
          <a href="#features">Features</a>
        </nav>
      </div>

      <!-- Account -->
      <div class="crs-footer-column">
        <h3>Account</h3>
        <nav aria-label="Account navigation">
          <% if (currentUser == null) { %>
            <a href="Login.jsp">Login</a>
            <a href="Registration.jsp">Register</a>
          <% } else { %>
            <a href="<%= dashboard %>">Dashboard</a>
            <a href="Logout.jsp">Logout</a>
          <% } %>
        </nav>
      </div>

      <!-- Information -->
      <div class="crs-footer-column">
        <h3>Our Mission</h3>
        <p class="bangla-font">
          সহজলভ্য ডিজিটাল রিপোর্টিং ও দায়িত্বশীল অংশগ্রহণের মাধ্যমে নাগরিকরা সোচ্চার হয়ে একটি সচেতন, সুশাসিত ও নিরাপদ সমাজ গড়ে তুলতে পারেন।
        </p>
      </div>

    </div>

    <!-- Footer Bottom -->
    <div class="crs-footer-bottom">
      <span>
        &copy; <%= java.time.Year.now().getValue() %>
        Crime Report System. All rights reserved.
      </span>

      <span>
        Built for a safer community.
      </span>
    </div>

  </div>
</footer>
    
</div>
</body>
</html>
