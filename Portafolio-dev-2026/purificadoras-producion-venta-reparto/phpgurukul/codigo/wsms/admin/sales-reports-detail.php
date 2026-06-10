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
<!-- tables -->
<link rel="stylesheet" type="text/css" href="css/table-style.css" />
<link rel="stylesheet" type="text/css" href="css/basictable.css" />
<script type="text/javascript" src="js/jquery.basictable.min.js"></script>
<script type="text/javascript">
    $(document).ready(function() {
      $('#table').basictable();

      $('#table-breakpoint').basictable({
        breakpoint: 768
      });

      $('#table-swap-axis').basictable({
        swapAxis: true
      });

      $('#table-force-off').basictable({
        forceResponsive: false
      });

      $('#table-no-resize').basictable({
        noResize: true
      });

      $('#table-two-axis').basictable();

      $('#table-max-height').basictable({
        tableWrapper: true
      });
    });
</script>
<!-- //tables -->
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
                <li class="breadcrumb-item"><a href="dashboard.php">Home</a><i class="fa fa-angle-right"></i>Sales reports</li>
            </ol>
<div class="agile-grids">	
				<!-- tables -->
				
				<div class="agile-tables">
					<div class="w3l-table-info">
					 
					   
		
				  <h3>Sales reports</h3>
				  <hr />
				  <?php
$fdate=$_POST['fromdate'];
$tdate=$_POST['todate'];
$rtype=$_POST['requesttype'];
?>
<?php if($rtype=='mtwise'){
$month1=strtotime($fdate);
$month2=strtotime($tdate);
$m1=date("F",$month1);
$m2=date("F",$month2);
$y1=date("Y",$month1);
$y2=date("Y",$month2);
    ?>
<h4 class="header-title m-t-0 m-b-30">Sales Report Month Wise</h4>
<hr />
<h4 align="center" style="color:blue">Sales Report  from <?php echo $m1."-".$y1;?> to <?php echo $m2."-".$y2;?></h4>
<hr />

				  <table id="table-breakpoint">
				 <thead>
<tr>
<th>S.NO</th>
<th>Month / Year </th>
<th>Sales</th>
</tr>
</thead>
					
					<?php
$ret=mysqli_query($con,"select month(OrderTime) as lmonth,year(OrderTime) as lyear,sum(Price) as totalprice from  tblcart join tblorderaddresses on tblorderaddresses.Ordernumber= tblcart.OrderNumber join tblwaterbottle on tblwaterbottle.ID=tblcart.BottleId where (date(tblorderaddresses.OrderTime) between '$fdate' and '$tdate') and (OrderFinalStatus='Bottle Delivered' || OrderFinalStatus='Order On its Way') group by lmonth,lyear");
$cnt=1;
while ($row=mysqli_fetch_array($ret)) {

?>
              
                <tr>
                    <td><?php echo $cnt;?></td>
                  <td><?php  echo $row['lmonth']."/".$row['lyear'];?></td>
              <td><?php  echo $total=$row['totalprice'];?></td>
             
                    </tr>
                <?php
$ftotal+=$total;
$cnt++;
}?>
<tr>
                  <td colspan="2" align="center">Total </td>
              <td><?php  echo $ftotal;?></td>
   
                 
                 
                </tr>
				  </table>
				 <?php } else {
$year1=strtotime($fdate);
$year2=strtotime($tdate);
$y1=date("Y",$year1);
$y2=date("Y",$year2);
 ?>
 <h4 class="header-title m-t-0 m-b-30">Sales Report Year Wise</h4>
 <hr />
    <h4 align="center" style="color:blue">Sales Report  from <?php echo $y1;?> to <?php echo $y2;?></h4>
    <hr />
				  <table id="table-breakpoint">
					<thead>
<tr>
<th>S.NO</th>
<th> Year </th>
<th>Sales</th>
</tr>
</thead>
					
					<?php
$ret=mysqli_query($con,"select year(OrderTime) as lyear,sum(Price) as totalprice from  tblcart join tblorderaddresses on tblorderaddresses.Ordernumber= tblcart.OrderNumber join tblwaterbottle on tblwaterbottle.ID=tblcart.BottleId where date(tblorderaddresses.OrderTime) between '$fdate' and '$tdate' and (OrderFinalStatus='Bottle Delivered' || OrderFinalStatus='Order On its Way') group by lyear");
$cnt=1;
while ($row=mysqli_fetch_array($ret)) {

?>
              
                <tr>
                    <td><?php echo $cnt;?></td>
                  <td><?php  echo $row['lyear'];?></td>
              <td><?php  echo $total=$row['totalprice'];?></td>
             
                    </tr>
                 </tr>
                <?php
$ftotal+=$total;
$cnt++;
}?>
   
   <tr>
                  <td colspan="2" align="center">Total </td>
              <td><?php  echo $ftotal;?></td>
   
                 
                 
                </tr>  
				  </table>
				
			<?php } ?>	
				</div>
				<!-- //tables -->
			</div>
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
<?php }  ?>