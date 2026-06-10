<?php
session_start();
error_reporting(0);

include('includes/dbconnection.php');
?>
<!DOCTYPE html>
<html lang="en">
<head>
<title>WSMS-New Details</title>
<meta charset="utf-8">
<link rel="stylesheet" type="text/css" href="styles/bootstrap-4.1.2/bootstrap.min.css">
<link href="plugins/font-awesome-4.7.0/css/font-awesome.min.css" rel="stylesheet" type="text/css">
<link rel="stylesheet" type="text/css" href="plugins/OwlCarousel2-2.3.4/owl.carousel.css">
<link rel="stylesheet" type="text/css" href="plugins/OwlCarousel2-2.3.4/owl.theme.default.css">
<link rel="stylesheet" type="text/css" href="plugins/OwlCarousel2-2.3.4/animate.css">
<link rel="stylesheet" type="text/css" href="styles/about.css">
<link rel="stylesheet" type="text/css" href="styles/about_responsive.css">
</head>
<body>

<div class="super_container">
	<div class="super_overlay"></div>
	
	<?php include_once('includes/header.php');?>


	<div class="home">
		<div class="parallax_background parallax-window" data-parallax="scroll" data-image-src="images/wsmsabout1.jpg" data-speed="0.8"></div>
		<div class="container">
			<div class="row">
				<div class="col">
					<div class="home_content text-center">
						<div class="home_title">New Details</div>
					</div>
				</div>
			</div>
		</div>
	</div>

	<!-- Intro -->

	<div class="intro">
		<div class="container">
			<div class="row row-eq-height">
				
				<!-- Intro Content -->
				<div class="col-lg-6">
					<?php 
					$nid=intval($_GET['newsid']);
 $query=mysqli_query($con,"select * from tblnews where ID='$nid'");
 while ($row=mysqli_fetch_array($query)) {


 ?>
					<div class="intro_content">
						<div class="section_title_container">
							<div class="section_subtitle" style="color:#000; line-height:18px;">
								<?php echo $row['Title'];?>
								<hr />
									
								</div>

						</div>
						<div class="intro_text">
							<p style="color:#000"><?php  echo $row['Description'];?></p>
							<p style="color:#000">New Posting Date: <?php  echo $row['NewsDate'];?></p>
						</div>
						
					</div>
					<?php } ?>
				</div>

				<!-- Intro Image -->
				<div class="col-lg-6 intro_col">
					<div class="intro_image">
						<div class="background_image" style="background-image:url(images/news_mouse.jpg);"></div>
						<img src="images/news_mouse.jpg" >
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
<script src="plugins/OwlCarousel2-2.3.4/owl.carousel.js"></script>
<script src="plugins/easing/easing.js"></script>
<script src="plugins/progressbar/progressbar.min.js"></script>
<script src="plugins/parallax-js-master/parallax.min.js"></script>
<script src="js/about.js"></script>
</body>
</html>