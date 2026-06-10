<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');

if(isset($_POST['submit']))
  {
    $contactno=$_POST['contactno'];
    $email=$_POST['email'];

        $query=mysqli_query($con,"select ID from tbladmin where  Email='$email' and MobileNumber='$contactno' ");
    $ret=mysqli_fetch_array($query);
    if($ret>0){
      $_SESSION['contactno']=$contactno;
      $_SESSION['email']=$email;
     header('location:reset-password.php');
    }
    else{
      $msg="Invalid Details. Please try again.";
    }
  }
  ?>
<!DOCTYPE HTML>
<html>
<head>
<title>Water Supply Management System | Forgot Password</title>

<script type="application/x-javascript"> addEventListener("load", function() { setTimeout(hideURLbar, 0); }, false); function hideURLbar(){ window.scrollTo(0,1); } </script>
<!-- Bootstrap Core CSS -->
<link href="css/bootstrap.min.css" rel='stylesheet' type='text/css' />
<!-- Custom CSS -->
<link href="css/style.css" rel='stylesheet' type='text/css' />
<link rel="stylesheet" href="css/morris.css" type="text/css"/>
<!-- Graph CSS -->
<link href="css/font-awesome.css" rel="stylesheet">
<link rel="stylesheet" href="css/jquery-ui.css"> 
<!-- jQuery -->
<script src="js/jquery-2.1.4.min.js"></script>
<!-- //jQuery -->
<link href='//fonts.googleapis.com/css?family=Roboto:700,500,300,100italic,100,400' rel='stylesheet' type='text/css'/>
<link href='//fonts.googleapis.com/css?family=Montserrat:400,700' rel='stylesheet' type='text/css'>
<!-- lined-icons -->
<link rel="stylesheet" href="css/icon-font.min.css" type='text/css' />
<!-- //lined-icons -->
</head> 
<body>
	<div class="main-wthree">
	<div class="container">
	<div class="sin-w3-agile">
		<h2>Forgot Password</h2>
		<form action="#" method="post">
			<p style="font-size:16px; color:red" align="center"> <?php if($msg){
    echo $msg;
  }  ?> </p>
			<div class="username">
				<span class="username">Email:</span>
				<input type="email" name="email" class="name" placeholder="Email" required="true">
				<div class="clearfix"></div>
			</div>
			<div class="password-agileits">
				<span class="username">Mobile Number:</span>
				<input type="text" name="contactno" class="password" placeholder="Mobile Number" required="true">
				<div class="clearfix"></div>
			</div>
			<div class="rem-for-agile">
				
				<a href="index.php">Already Have Account</a><br>
			</div>
			<div class="login-w3">
					<input type="submit" class="login" name="submit" value="Reset">
			</div>
			<div class="clearfix"></div>
		</form>
				<div class="back">
					<a href="../index.php">Back to home</a>
				</div>
				<?php include_once('includes/footer.php');?>

	</div>
	</div>
	</div>
</body>
</html>