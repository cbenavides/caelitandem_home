<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');
error_reporting(0);

if(isset($_POST['submit']))
  {
    $contactno=$_SESSION['contactno'];
    $email=$_SESSION['email'];
    $password=md5($_POST['newpassword']);

        $query=mysqli_query($con,"update tbladmin set Password='$password'  where  Email='$email' && MobileNumber='$contactno' ");
   if($query)
   {
echo "<script>alert('Password successfully changed');</script>";
session_destroy();
   }
  
  }
  ?>
<!DOCTYPE HTML>
<html>
<head>
<title>Water Supply Management System | Reset Password</title>

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
  <script type="text/javascript">
function checkpass()
{
if(document.changepassword.newpassword.value!=document.changepassword.confirmpassword.value)
{
alert('New Password and Confirm Password field does not match');
document.changepassword.confirmpassword.focus();
return false;
}
return true;
} 

</script>
</head> 
<body>
	<div class="main-wthree">
	<div class="container">
	<div class="sin-w3-agile">
		<h2>Reset Password</h2>
		<form action="#" method="post" name="changepassword" onsubmit="return checkpass();">
			<p style="font-size:16px; color:red" align="center"> <?php if($msg){
    echo $msg;
  }  ?> </p>
			<div class="username">
				<span class="username">New Password:</span>
				<input type="password" name="newpassword" class="name" placeholder="New Password" required="true">
				<div class="clearfix"></div>
			</div>
			<div class="username">
				<span class="username">Confirm Password:</span>
				<input type="password" name="confirmpassword" class="name" placeholder="Confirm Password" required="true">
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