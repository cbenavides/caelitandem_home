<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');
if (strlen($_SESSION['wsmsaid']==0)) {
  header('location:logout.php');
  } 
     ?>

<!DOCTYPE HTML>
<html>
<head>
<title>Water Supply Management System | Admin Dashboard</title>

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
                <li class="breadcrumb-item"><a href="dashboard.php">Home</a> <i class="fa fa-angle-right"></i></li>
            </ol>
<!--four-grids here-->
		<div class="four-grids">
					<div class="col-md-3 four-grid">
						<?php $query=mysqli_query($con,"Select * from tblorderaddresses");
$totalorder=mysqli_num_rows($query);
?>

						<div class="four-agileinfo">

							<div class="icon">
								<i class="glyphicon glyphicon-list-alt" aria-hidden="true"></i>
							</div>
							<div class="four-text">
								<h3><a class="text-muted text-uppercase m-b-20" href="all-orders.php" style="font-size: 20px"><strong style="color: white">Total Order</strong></a></h3>
								<h4> <?php echo $totalorder;?>  </h4>
								
							</div>
							
						</div>
					</div>
					<div class="col-md-3 four-grid">
						<?php $query1=mysqli_query($con,"Select * from tblorderaddresses where OrderFinalStatus is null");
$neworder=mysqli_num_rows($query1);
?>
						<div class="four-agileinfo">
							<div class="icon">
								
								<i class="glyphicon glyphicon-list-alt" aria-hidden="true"></i>
							</div>
							<div class="four-text">
								<h3><a class="text-muted text-uppercase m-b-20" href="new-order.php" style="font-size: 20px"><strong style="color: white">New Order</strong></a></h3>
								<h4><?php echo $neworder;?></h4>

							</div>
							
						</div>
					</div>
					<div class="col-md-3 four-grid">
						<?php $query2=mysqli_query($con,"Select * from tblorderaddresses where OrderFinalStatus='Order Accept'");
$acceptorder=mysqli_num_rows($query2);
?>
						<div class="four-w3ls">
							<div class="icon">
								<i class="glyphicon glyphicon-list-alt" aria-hidden="true"></i>
							</div>
							<div class="four-text">
							<h3><a class="text-muted text-uppercase m-b-20" href="accept-order.php" style="font-size: 20px"><strong style="color: white">Accept Order</strong></a></h3>
								<h4><?php echo $acceptorder;?></h4>
								
							</div>
							
						</div>
					</div>
					<div class="col-md-3 four-grid">
						<?php $query3=mysqli_query($con,"Select * from tblorderaddresses where OrderFinalStatus='Order On its Way'");
$onthewayorder=mysqli_num_rows($query3);
?>
						<div class="four-wthree">
							<div class="icon">
								<i class="glyphicon glyphicon-list-alt" aria-hidden="true"></i>
							</div>
							<div class="four-text">
							<h3><a class="text-muted text-uppercase m-b-20" href="order-onthway.php" style="font-size: 20px"><strong style="color: white">Order On its Way</strong></a></h3>
								<h4><?php echo $onthewayorder;?></h4>
								
							</div>
							
						</div>
					</div>
					<div class="clearfix"></div>
				</div>

              	<div class="four-grids">
					<div class="col-md-3 four-grid">
						<?php $query4=mysqli_query($con,"Select * from tblorderaddresses where OrderFinalStatus='Bottle Delivered'");
$orderdel=mysqli_num_rows($query4);
?>

						<div class="four-w3ls">

							<div class="icon">
								<i class="glyphicon glyphicon-list-alt" aria-hidden="true"></i>
							</div>
							<div class="four-text">
								<h3><a class="text-muted text-uppercase m-b-20" href="order-delivered.php" style="font-size: 20px"><strong style="color: white">Order Delivered </strong></a></h3>
								<h4> <?php echo $orderdel;?>  </h4>
								
							</div>
							
						</div>
					</div>
					<div class="col-md-3 four-grid">
						<?php $query5=mysqli_query($con,"Select * from tblorderaddresses where OrderFinalStatus='Order Cancelled'");
$cancelorder=mysqli_num_rows($query5);
?>
						<div class="four-agileits">
							<div class="icon">
								
								<i class="glyphicon glyphicon-list-alt" aria-hidden="true"></i>
							</div>
							<div class="four-text">
								<h3><a class="text-muted text-uppercase m-b-20" href="order-cancelled.php" style="font-size: 20px"><strong style="color: white">Cancel Orders</strong></a></h3>
								<h4><?php echo $cancelorder;?></h4>

							</div>
							
						</div>
					</div>
					<div class="col-md-3 four-grid">
						<?php $query6=mysqli_query($con,"Select * from tbluser");
$usercount=mysqli_num_rows($query6);
?>

						<div class="four-w3ls">
							<div class="icon">
								<i class="glyphicon glyphicon-user" aria-hidden="true"></i>
							</div>
							<div class="four-text">
							<h3><a class="text-muted text-uppercase m-b-20" href="manage-users.php" style="font-size: 20px"><strong style="color: white">Total Reg Users</strong></a></h3>
								<h4><?php echo $usercount;?></h4>
								
							</div>
							
						</div>
					</div>
					<div class="col-md-3 four-grid">
						<?php $query7=mysqli_query($con,"Select * from tblcompany");
$compcount=mysqli_num_rows($query7);
?>
						<div class="four-wthree">
							<div class="icon">
								<i class="glyphicon glyphicon-briefcase" aria-hidden="true"></i>
							</div>
							<div class="four-text">
							<h3><a class="text-muted text-uppercase m-b-20" href="manage-company.php" style="font-size: 20px"><strong style="color: white">Total Company</strong></a></h3>
								<h4><?php echo $compcount;?></h4>
								
							</div>
							
						</div>
					</div>
					<div class="clearfix"></div>
				</div>
          
                  
						
						
   
	
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
<!-- morris JavaScript -->	
<script src="js/raphael-min.js"></script>
<script src="js/morris.js"></script>
<script>
	$(document).ready(function() {
		//BOX BUTTON SHOW AND CLOSE
	   jQuery('.small-graph-box').hover(function() {
		  jQuery(this).find('.box-button').fadeIn('fast');
	   }, function() {
		  jQuery(this).find('.box-button').fadeOut('fast');
	   });
	   jQuery('.small-graph-box .box-close').click(function() {
		  jQuery(this).closest('.small-graph-box').fadeOut(200);
		  return false;
	   });
	   
	    //CHARTS
	    function gd(year, day, month) {
			return new Date(year, month - 1, day).getTime();
		}
		
		graphArea2 = Morris.Area({
			element: 'hero-area',
			padding: 10,
        behaveLikeLine: true,
        gridEnabled: false,
        gridLineColor: '#dddddd',
        axes: true,
        resize: true,
        smooth:true,
        pointSize: 0,
        lineWidth: 0,
        fillOpacity:0.85,
			data: [
				{period: '2014 Q1', iphone: 2668, ipad: null, itouch: 2649},
				{period: '2014 Q2', iphone: 15780, ipad: 13799, itouch: 12051},
				{period: '2014 Q3', iphone: 12920, ipad: 10975, itouch: 9910},
				{period: '2014 Q4', iphone: 8770, ipad: 6600, itouch: 6695},
				{period: '2015 Q1', iphone: 10820, ipad: 10924, itouch: 12300},
				{period: '2015 Q2', iphone: 9680, ipad: 9010, itouch: 7891},
				{period: '2015 Q3', iphone: 4830, ipad: 3805, itouch: 1598},
				{period: '2015 Q4', iphone: 15083, ipad: 8977, itouch: 5185},
				{period: '2016 Q1', iphone: 10697, ipad: 4470, itouch: 2038},
				{period: '2016 Q2', iphone: 8442, ipad: 5723, itouch: 1801}
			],
			lineColors:['#ff4a43','#a2d200','#22beef'],
			xkey: 'period',
            redraw: true,
            ykeys: ['iphone', 'ipad', 'itouch'],
            labels: ['All Visitors', 'Returning Visitors', 'Unique Visitors'],
			pointSize: 2,
			hideHover: 'auto',
			resize: true
		});
		
	   
	});
	</script>
</body>
</html>