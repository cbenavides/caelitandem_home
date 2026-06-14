<?php 
session_start();
error_reporting(0);
include('includes/dbconnection.php');
if (strlen($_SESSION['wsmsuid']==0)) {
  header('location:logout.php');
  } else{
if(isset($_POST['submit']))
  {
    $uid=$_SESSION['wsmsuid'];
    $fullname=$_POST['fullname'];
    $mobilenumber=$_POST['mobilenumber'];
    $email=$_POST['email'];
    
   

    $query=mysqli_query($con, "update tbluser set FullName='$fullname', MobileNo='$mobilenumber' where ID='$uid'");


    if ($query) {
    $msg="Your profile has been updated";
  }
  else
    {
      $msg="Something Went Wrong. Please try again";
    }

}

 ?>




<!DOCTYPE html>
<html lang="en">
<head>
<title>WSMS-Profile</title>

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
						<div class="home_title">Profile</div>
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
						
						<div class="section_title"><h1>Welcome!!!!</h1></div>
					</div>
				</div>
			</div>
			<div class="row contact_row">

				<!-- Contact - About -->
				

				<!-- Contact - Image -->
				<div class="col-lg-4 contact_col">
					<div class="contact_image d-flex flex-column align-items-center justify-content-center">
						<h3 style="text-align: center;color: red">Update Your Profile</h3>
					</div>
				</div>

			</div>
			<div class="row contact_form_row">
				<div class="col">
					<div class="contact_form_container">
						<form action="#" class="contact_form text-center" id="contact_form" method="post" name="signup">
							<p style="font-size:16px; color:red" align="center"> <?php if($msg){
    echo $msg;
  }  ?> </p>
   <?php
 $uid=$_SESSION['wsmsuid'];
$ret=mysqli_query($con,"select * from tbluser where ID='$uid'");
$cnt=1;
while ($row=mysqli_fetch_array($ret)) {

?>  
							<div class="row" style="margin-top:2%">
								<div class="col-lg-12">
									<input class="form-control" type="text" value="<?php  echo $row['FullName'];?>" id="fullname" name="fullname" required="true">
								</div>
					
							</div>
							<div class="row" style="margin-top:2%">
								<div class="col-lg-12">
									<input class="form-control" type="text" value="<?php  echo $row['MobileNo'];?>" id="mobilenumber" name="mobilenumber" required="true" readonly="true">
								</div>
					
							</div>
							<div class="row" style="margin-top:2%">
								<div class="col-lg-12">
									<input class="form-control" type="email" value="<?php  echo $row['Email'];?>" id="email" name="email" readonly="true">
								</div>
							</div>

<div class="row" style="margin-top:2%" align="left">
								<div class="col-lg-12" >
						<b>Profile Reg. Date : </b>  <?php  echo $row['RegDate'];?>
								</div>
							</div>

							<button class="contact_button" type="submit" name="submit">Update</button>
							<?php } ?> 
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
<?php  } ?>