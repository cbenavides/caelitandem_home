<?php
session_start();
error_reporting(0);
include_once('includes/dbconnection.php');
if (strlen($_SESSION['wsmsuid']==0)) {
  header('location:logout.php');
  } else{ 

  	// Code for deleting product from cart
if(isset($_GET['delid']))
{
$rid=intval($_GET['delid']);
$query=mysqli_query($con,"delete from tblcart where ID='$rid'");
 echo "<script>alert('Data deleted');</script>"; 
  echo "<script>window.location.href = 'cart.php'</script>";     


}
//placing order

if(isset($_POST['submit'])){
//getting address
	
	$cnumber=$_POST['cnumber'];
	
$fnaobno=$_POST['flatbldgnumber'];
$street=$_POST['streename'];
$area=$_POST['area'];
$lndmark=$_POST['landmark'];
$city=$_POST['city'];
$userid=$_SESSION['wsmsuid'];
//genrating order number
$orderno= mt_rand(100000000, 999999999);
$query="update tblcart set OrderNumber='$orderno',IsOrderPlaced='1' where UserId='$userid' and IsOrderPlaced is null;";
$query.="insert into tblorderaddresses(UserId,MobileNumber,Ordernumber,Flatnobuldngno,StreetName,Area,Landmark,City) values('$userid','$cnumber','$orderno','$fnaobno','$street','$area','$lndmark','$city');";

$result = mysqli_multi_query($con, $query);
if ($result) {

echo '<script>alert("Your order placed successfully. Order number is "+"'.$orderno.'")</script>';
echo "<script>window.location.href='my-order.php'</script>";

}
}    

    ?>

<!DOCTYPE html>
<html lang="en">
<head>
<title>WSMS-Cart Page</title>

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
						<div class="home_title">Cart</div>
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
						<div class="section_title"><h3>Your Cart Detail</h3></div>
					</div>
				</div>
			</div>
			<div class="row">

				<!-- Contact - About -->
				

				<!-- Contact - Image -->
			
			

 <div class="col-lg-12">

		<?php 
					$userid= $_SESSION['wsmsuid'];
 $query=mysqli_query($con,"select tblcart.ID,tblwaterbottle.Image,tblwaterbottle.CompanyName,tblwaterbottle.BottleSize,tblwaterbottle.Price,tblcart.BottleId from tblcart join tblwaterbottle on tblwaterbottle.ID=tblcart.BottleId where tblcart.UserId='$userid' and tblcart.IsOrderPlaced is null");
$num=mysqli_num_rows($query);
if($num>0){
	$cnt=1;

?>
<table border="1" class="table">
	<tr>
<th>#</th>
<th>Product Image</th>	
<th>Company</th>	
<th>Size</th>	
<th>Price</th>	
<th>Action</th>
</tr>
<?php	
while ($row=mysqli_fetch_array($query)) {
	?>

<tr>
	<td><?php echo $cnt;?></td>
<td><img class="b-goods-f__img img-scale" src="admin/images/<?php echo $row['Image'];?>" alt="<?php echo $row['Image'];?>" width='300' height='250'></td>
<td><?php echo $row['CompanyName'];?></td>	
<td><?php echo $row['BottleSize'];?>  </td>	
<td>Rs. <?php echo $total=$row['Price'];?></td>
<td><a href="cart.php?delid=<?php echo $row['ID'];?>" onclick="return confirm('Do you really want to Delete ?');"><i class="fa fa-trash fa-delete" aria-hidden="true"></i></a></td>		
</tr>
<?php $cnt++; 
$gtotal+=$total;

} ?>

<tr>
<th colspan="4" style="text-align:center;">Grand Total</th>
<th colspan="2"><?php echo number_format($gtotal,2);?></th>
</tr>
</table>


<div class="row contact_form_row">
				<div class="col">
					<div class="contact_form_container">
						<form action="#" class="contact_form text-center" id="contact_form" method="post" name="">
							
							<div class="row">
								<div class="col-lg-12" style="margin-top: 15px">
									<input type="text" class="form-control form-control-alternative" placeholder="Contact Number" name="cnumber" id="cnumber" required="true" style="border:1px #000 solid;" maxlength="10" pattern="[0-9]+">
								</div>
					
							</div>
							
						
			<div class="row">
								<div class="col-lg-12" style="margin-top: 15px">
									<input type="text" class="form-control form-control-alternative" placeholder="Flat or Building Number" name="flatbldgnumber" id="flatbldgnumber" required="true" style="border:1px #000 solid;">
								</div>
					
							</div>
							<div class="row">
								<div class="col-lg-12" style="margin-top: 15px">
									<input type="text" class="form-control form-control-alternative" placeholder="Street Name" name="streename" id="streename" required="true" style="border:1px #000 solid;">
								</div>
					
							</div>
							<div class="row">
								<div class="col-lg-12" style="margin-top: 15px">
									<input type="text" class="form-control form-control-alternative" placeholder="Area" name="area" id="area" required="true" style="border:1px #000 solid;">
								</div>
					
							</div>
							<div class="row">
								<div class="col-lg-12" style="margin-top: 15px">
									<input type="text" class="form-control form-control-alternative" placeholder="Landmark" name="landmark" id="landmark" required="true" style="border:1px #000 solid;">
								</div>
					
							</div>
							
							<div class="row">
								<div class="col-lg-12" style="margin-top: 15px">
									<input type="text" class="form-control form-control-alternative" placeholder="City" name="city" id="city" required="true" style="border:1px #000 solid;">
								</div>
					
							</div>

							
							<button class="contact_button" type="submit" name="submit">submit</button>
							
						</form>
					</div>
				</div>
			</div>
				</div>
		<?php } else {?>
<hr/>
<h3 align="center">You cart is empty.</h3>
<?php } ?>	</div>
			
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
<?php } ?>