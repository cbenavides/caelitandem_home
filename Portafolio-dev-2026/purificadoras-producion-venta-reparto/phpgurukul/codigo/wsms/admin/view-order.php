<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');
if (strlen($_SESSION['wsmsaid']==0)) {
   header('location:logout.php');
  } else{

if(isset($_POST['submit']))
  {
    
    $oid=$_GET['orderid'];
    $bcsta=$_POST['status'];
    $remark=$_POST['remark'];
 
    
    $query=mysqli_query($con,"insert into tbltracking(OrderId,remark,status) value('$oid','$remark','$bcsta')"); 
   $query=mysqli_query($con, "update   tblorderaddresses set OrderFinalStatus='$bcsta' where Ordernumber='$oid'");
    if ($query) {
    $msg="Order Has been updated";
  }
  else
    {
      $msg="Something Went Wrong. Please try again";
    }

  
}
  

  ?>

<!DOCTYPE HTML>
<html>
<head>
<title>Water Supply Management System | View Order Detail</title>

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
                <li class="breadcrumb-item"><a href="dashboard.php">Home</a><i class="fa fa-angle-right"></i> View Order
            </ol>
		<!--grid-->
 	<div class="grid-form">
 


  <div class="grid-form1">
  	      <h2>Order Details #<?php echo $_GET['orderid'];?></h2>
  	         <div class="tab-content">
						<div class="tab-pane active" id="horizontal-form">
							                           <?php
 $oid=$_GET['orderid'];
$ret=mysqli_query($con,"select * from tblorderaddresses join tbluser on tbluser.ID=tblorderaddresses.UserId where tblorderaddresses.Ordernumber='$oid'");
$cnt=1;
while ($row=mysqli_fetch_array($ret)) {

?>
<div class="row">
  <div class="col-12">
     <p style="font-size:16px; color:red; text-align: center"><?php if($msg){
    echo $msg;
  }  ?> </p>
<table border="1" class="table mb-0">
 <tr align="center">
<td colspan="2" style="font-size:20px;color:blue">
 User Details</td></tr>

    <tr>
    <th>Order Number</th>
    <td><?php  echo $row['Ordernumber'];?></td>
  </tr>
  <tr>
    <th>Full Name</th>
    <td><?php  echo $row['FullName'];?></td>
  </tr>
 
  <tr>
    <th>Email</th>
    <td><?php  echo $row['Email'];?></td>
  </tr>
  <tr>
    <th>Mobile Number</th>
    <td><?php  echo $row['MobileNo'];?></td>
  </tr>
  <tr>
    <th>Flat no./buldng no.</th>
    <td><?php  echo $row['Flatnobuldngno'];?></td>
  </tr>
  <tr>
    <th>StreetName</th>
    <td><?php  echo $row['StreetName'];?></td>
  </tr>
  <tr>
    <th>Area</th>
    <td><?php  echo $row['Area'];?></td>
  </tr>
  <tr>
    <th>Land Mark</th>
    <td><?php  echo $row['Landmark'];?></td>
  </tr>
  <tr>
    <th>City</th>
    <td><?php  echo $row['City'];?></td>
  </tr>
  <tr>
    <th>Order Date</th>
    <td><?php  echo $row['OrderTime'];?></td>
  </tr>
  <tr>
    <th>Order Final Status</th>
    <td> <?php  
    $orserstatus=$row['OrderFinalStatus'];
if($row['OrderFinalStatus']=="Order Accept")
{
  echo "Order Accept";
}

if($row['OrderFinalStatus']=="Order On its Way")
{
  echo "Order On its Way";
}

if($row['OrderFinalStatus']=="Bottle Delivered")
{
  echo "Bottle Delivered";
}
if($row['OrderFinalStatus']=="")
{
  echo "Wait for approval";
}
if($row['OrderFinalStatus']=="Order Cancelled")
{
  echo "Order Cancelled";
}


     ;?></td>
  </tr>
</table>
									</div>
									<div class="col-12" style="margin-top:2%">
  <?php  
$query=mysqli_query($con,"select  tblwaterbottle.Image,tblwaterbottle.CompanyName,tblwaterbottle.BottleSize,tblwaterbottle.Price, tblcart.BottleId from tblcart join tblwaterbottle on tblwaterbottle.ID=tblcart.BottleId where tblcart.IsOrderPlaced=1 and tblcart.OrderNumber='$oid'");
$num=mysqli_num_rows($query);
$cnt=1;?>
<table border="1" class="table table-bordered mg-b-0">
 <tr align="center">
<td colspan="4" style="font-size:20px;color:blue">
 Order  Details</td></tr> 

 <tr>
    <th>#</th>
<th>Image </th>
<th>Company Name</th>
<th>Price</th>
</tr>
<?php  
while ($row1=mysqli_fetch_array($query)) {
  ?>
<tr>
  <td><?php echo $cnt;?></td>
 <td><img src="images/<?php echo $row1['Image']?>" width="60" height="40" alt=""></td> 
  <td><?php  echo $row1['CompanyName'];?></td> 
   <td><?php  echo $total=$row1['Price'];?></td> 
</tr>
<?php 
$grandtotal+=$total;
$cnt=$cnt+1;} ?>
<tr>
  <th colspan="3" style="text-align:center">Grand Total </th>
<th><?php  echo number_format($grandtotal,2);?></th>
</tr> 


</table>  
								</div>
								
						
						</div>
<table class="table mb-0">

<?php

  if($orserstatus=="Order Accept" || $orserstatus=="Order On its Way" ||  $orserstatus=="" ){ ?>


<form name="submit" method="post"> 
<tr>
    <th>Remark :</th>
    <td>
    <textarea name="remark" placeholder="" rows="6" cols="14" class="form-control wd-450" required="true"></textarea></td>
  </tr>

  <tr>
    <th>Status :</th>
    <td>
   <select name="status" class="form-control wd-450" required="true" >
    <?php if($orserstatus==""):?>
     <option value="Order Accept" selected="true">Order Accept</option> 
     <option value="Order Cancelled">Order Cancelled</option>
      <?php elseif($orserstatus=="Order Accept"):?>
     <option value="Order On its Way">Order On its Way</option>
     <option value="Bottle Delivered">Bottle Delivered</option>
      <?php elseif($orserstatus=="Order On its Way"):?>
        <option value="Bottle Delivered">Bottle Delivered</option>
      <?php endif;?>
     
   </select></td>
  </tr>
    <tr align="center">
    <td colspan="2"><button type="submit" name="submit" class="btn btn-primary">Update order</button></td>
  </tr>
</form>
  <?php } ?>
 


</table>
<?php } ?>
<?php  if($orserstatus!=""){
$ret=mysqli_query($con,"select tbltracking.OrderCanclledByUser,tbltracking.remark,tbltracking.status as fstatus,tbltracking.StatusDate from tbltracking where tbltracking.OrderId ='$oid'");
$cnt=1;

 echo $cancelledby=$row['OrderCanclledByUser'];
 ?>
<table id="datatable" class="table table-bordered dt-responsive nowrap" style="border-collapse: collapse; border-spacing: 0; width: 100%;">
  <tr align="center">
   <th colspan="4" >Tracking History</th> 
  </tr>
  <tr>
    <th>#</th>
<th>Remark</th>
<th>Status</th>
<th>Time</th>
</tr>
<?php  
while ($row=mysqli_fetch_array($ret)) { 
  ?>
<tr>
  <td><?php echo $cnt;?></td>
 <td><?php  echo $row['remark'];?></td> 
  <td><?php  echo $row['fstatus'];
if($cancelledby=='1' &&  $row['fstatus']=='Order Cancelled')
{
echo "("."by user".")";
} 
if($cancelledby=="" and  $row['fstatus']=='Order Cancelled')
{

echo "("."by Company".")";
}

  ?></td> 
   <td><?php  echo $row['StatusDate'];?></td> 
</tr>
<?php $cnt=$cnt+1;} ?>
</table>
<?php  }  
?>

					</div>

      <div class="panel-footer">
		
	 </div>
    
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