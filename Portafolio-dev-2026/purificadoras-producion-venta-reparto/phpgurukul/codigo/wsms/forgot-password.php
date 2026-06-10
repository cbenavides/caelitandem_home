<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');

if(isset($_POST['submit']))
  {
    $contactno=$_POST['contactno'];
    $email=$_POST['email'];

        $query=mysqli_query($con,"select ID from tbluser where  Email='$email' and MobileNo='$contactno' ");
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


<!DOCTYPE html>
<html lang="en">
<head>
<title>WSMS-Forgot Password</title>

<link rel="stylesheet" type="text/css" href="styles/bootstrap-4.1.2/bootstrap.min.css">
<link href="plugins/font-awesome-4.7.0/css/font-awesome.min.css" rel="stylesheet" type="text/css">
<link rel="stylesheet" type="text/css" href="styles/contact.css">
<link rel="stylesheet" type="text/css" href="styles/contact_responsive.css">
</head>
<body>

<div class="super_container">
	<div class="super_overlay"></div>
	
	<?php include_once('includes/header.php');?>
	<!-- Home -->

	<div class="home">
		<div class="parallax_background parallax-window" data-parallax="scroll" data-image-src="images/wsmscontact.jpg" data-speed="0.8"></div>
		<div class="container">
			<div class="row">
				<div class="col">
					<div class="home_content text-center">
						<div class="home_title">Forgot Password</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Contact -->

	<div class="contact">
		<div class="container">
			<div class="row">
				<div class="col">
					<div class="section_title_container text-center">
						<div class="section_subtitle">the best deals of water</div>
						<div class="section_title"><h1>Forgot Password</h1></div>
					</div>
				</div>
			</div>
			<div class="row contact_row">

				<!-- Contact - About -->
				

				<!-- Contact - Image -->
			

			</div>
			<div class="row contact_form_row">
				<div class="col">
					<div class="contact_form_container">
						<form action="#" class="contact_form text-center" id="contact_form" method="post" name="signup">
							<p style="font-size:16px; color:red" align="center"> <?php if($msg){
    echo $msg;
  }  ?> </p>
							<div class="row">
								<div class="col-lg-12">
									<input type="text" class="form-control" placeholder="Registered Email" name="email" id="email" required="true">
								</div>

							</div>
							<div class="row" style="margin-top:2%">
								<div class="col-lg-12">
									<input type="text" class="form-control" placeholder="Mobile Number" maxlength="10" pattern="[0-9]+" id="contactno" name="contactno" required="true">
								</div>
			<a href="signin.php" style="margin-left:2%; margin-top:1%">Already Have Account</a><br>
							</div>
							
							

							
							<button class="contact_button" type="submit" name="submit">Submit</button>
							<div class="row m-t-50">
                                <div class="col-sm-12 text-center">
                                    <p class="text-muted">Don't have an account?  <a href="signup.php" class="text-dark m-l-5"><b>Sign Up</b></a></p>
                                </div>
                            </div>
						</form>
					</div>
				</div>
			</div>
		</div>
	</div>

	
	<?php include_once('includes/footer.php');?>
</div>

<script src="js/jquery-3.3.1.min.js"></script>
<script src="styles/bootstrap-4.1.2/popper.js"></script>
<script src="styles/bootstrap-4.1.2/bootstrap.min.js"></script>
<script src="plugins/greensock/TweenMax.min.js"></script>
<script src="plugins/greensock/TimelineMax.min.js"></script>
<script src="plugins/scrollmagic/ScrollMagic.min.js"></script>
<script src="plugins/greensock/animation.gsap.min.js"></script>
<script src="plugins/greensock/ScrollToPlugin.min.js"></script>
<script src="plugins/easing/easing.js"></script>
<script src="plugins/progressbar/progressbar.min.js"></script>
<script src="plugins/parallax-js-master/parallax.min.js"></script>
<script src="https://maps.googleapis.com/maps/api/js?v=3.exp&key=AIzaSyCIwF204lFZg1y4kPSIhKaHEXMLYxxuMhA"></script>
<script src="js/contact.js"></script>
</body>
</html>