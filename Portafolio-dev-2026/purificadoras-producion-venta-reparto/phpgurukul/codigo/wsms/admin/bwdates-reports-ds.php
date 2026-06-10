<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');
if (strlen($_SESSION['wsmsaid']==0)) {
  header('location:logout.php');
  } else{

  

  ?>

<!DOCTYPE HTML>
<html>
<head>
<title>Water Supply Management System | Reports</title>

<script type="application/x-javascript"> addEventListener("load", function() { setTimeout(hideURLbar, 0); }, false); function hideURLbar(){ window.scrollTo(0,1); } </script>
<!-- Bootstrap Core CSS -->
<link href="css/bootstrap.min.css" rel='stylesheet' type='text/css' />
<!-- Custom CSS -->
<link href="css/style.css" rel='stylesheet' type='text/css' />
<link rel="stylesheet" href="css/morris.css" type="text/css"/>
<!-- Graph CSS -->
<link href="css/font-awesome.css" rel="stylesheet"> 
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
   <div class="page-container">
   <!--/content-inner-->
<div class="left-content">
	   <div class="mother-grid-inner">
              <!--header start here-->
				<?php include_once('includes/header.php');?>
<!--heder end here-->
	<ol class="breadcrumb">
                <li class="breadcrumb-item"><a href="dashboard.php">Home</a><i class="fa fa-angle-right"></i>Between dates reports
            </ol>
		<!--grid-->
 	<div class="grid-form">
 


  <div class="grid-form1">
  	       <h3>Between dates reports</h3>
  	         <div class="tab-content">
						<div class="tab-pane active" id="horizontal-form">
							<form class="form-horizontal" method="post" name="bwdatesreport"  action="bwdates-reports-details.php" enctype="multipart/form-data">
								 <p style="font-size:16px; color:red" align="left"> <?php if($msg){
    echo $msg;
  }  ?> </p>			
					<div class="form-group">
									<label for="mediuminput" class="col-sm-2 control-label">From Date</label>
									<div class="col-sm-8">
										<input type="date" class="form-control1" name="fromdate" id="fromdate" value="" required='true'>
									</div>
								</div>
								<div class="form-group">
									<label for="mediuminput" class="col-sm-2 control-label">To Date</label>
									<div class="col-sm-8">
										<input type="date" class="form-control1" name="todate" id="todate" value="" required='true'>
									</div>
								</div>
								<div class="form-group">
									<label for="mediuminput" class="col-sm-2 control-label">Request Type</label>
									<div class="col-sm-8">
										
										<input type="radio" name="requesttype" value="all" checked="true">All
										 <input type="radio" name="requesttype" value="Order Accept">Order Accept
                  <input type="radio" name="requesttype" value="Order On its Way">Order On its Way
                  <input type="radio" name="requesttype" value="Bottle Delivered">Bottle Delivered
                   <input type="radio" name="requesttype" value="Order Cancelled">Order Cancelled
									</div>
								</div>			


							
								
						
						</div>
					</div>

      <div class="panel-footer">
		<div class="row">
			<div class="col-sm-8 col-sm-offset-2">
				<button class="btn-primary btn" type="submit" name="submit">Submit</button>
				
			</div>
		</div>
	 </div>
    </form>
  </div>
 	</div>
 	<!--//grid-->

<!-- script-for sticky-nav -->
		<script>
		$(document).ready(function() {
			 var navoffeset=$(".header-main").offset().top;
			 $(window).scroll(function(){
				var scrollpos=$(window).scrollTop(); 
				if(scrollpos >=navoffeset){
					$(".header-main").addClass("fixed");
				}else{
					$(".header-main").removeClass("fixed");
				}
			 });
			 
		});
		</script>
		<!-- /script-for sticky-nav -->
<!--inner block start here-->
<div class="inner-block">

</div>
<!--inner block end here-->
<?php include_once('includes/footer.php');?>
</div>
</div>
 <?php include_once('includes/sidebar.php');?>
							  <div class="clearfix"></div>		
							</div>
							<script>
							var toggle = true;
										
							$(".sidebar-icon").click(function() {                
							  if (toggle)
							  {
								$(".page-container").addClass("sidebar-collapsed").removeClass("sidebar-collapsed-back");
								$("#menu span").css({"position":"absolute"});
							  }
							  else
							  {
								$(".page-container").removeClass("sidebar-collapsed").addClass("sidebar-collapsed-back");
								setTimeout(function() {
								  $("#menu span").css({"position":"relative"});
								}, 400);
							  }
											
											toggle = !toggle;
										});
							</script>
<!--js -->
<script src="js/jquery.nicescroll.js"></script>
<script src="js/scripts.js"></script>
<!-- Bootstrap Core JavaScript -->
   <script src="js/bootstrap.min.js"></script>
   <!-- /Bootstrap Core JavaScript -->	   

</body>
</html>
<?php } ?>