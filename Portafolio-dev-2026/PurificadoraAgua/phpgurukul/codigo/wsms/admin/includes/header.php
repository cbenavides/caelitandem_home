<?php
session_start();
error_reporting(0);
include('includes/dbconnection.php');
if (strlen($_SESSION['wsmsaid']==0)) {
  header('location:logout.php');
  } 
     ?>
<div class="header-main">
          <div class="logo-w3-agile">
                <h1><a href="dashboard.php">WSMS</a></h1>
              </div>
         
             <div class="w3layouts-right">
              <div class="profile_details_left">
                <?php
$ret1=mysqli_query($con,"select tbluser.FullName,tblorderaddresses.ID,tblorderaddresses.Ordernumber from tblorderaddresses join tbluser on tbluser.ID=tblorderaddresses.UserId where tblorderaddresses.OrderFinalStatus is null");
$num=mysqli_num_rows($ret1);

?><!--notifications of menu start -->
                <ul class="nofitications-dropdown">
                  
                  <li class="dropdown head-dpdn">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown" aria-expanded="false"><i class="fa fa-bell"></i><span class="badge blue"><?php echo $num;?></span></a>
                    <ul class="dropdown-menu">
                      <li>
                        <div class="notification_header">
                          <h3>You have <?php echo $num;?> new notification</h3>
                        </div>
                      </li>
                      <li><a href="#">
                      
                         
                        <?php if($num>0){
while($result=mysqli_fetch_array($ret1))
{
            ?>
            <a class="dropdown-item" href="view-order.php?orderid=<?php echo $result['Ordernumber'];?>"><i  class="fa fa-bell"  style="color: red;"></i>  #<?php echo $result['Ordernumber'];?> Order Received from <?php echo $result['FullName'];?></a>
<?php }} else {?>
    <a class="dropdown-item" href="view-allorderfood.php">No New Order Received</a>
        <?php } ?>
                        
                        
                      
                    </ul>
                  </li> 
                
                  <div class="clearfix"> </div>
                </ul>
                <div class="clearfix"> </div>
              </div>
              <!--notification menu end -->
              
              <div class="clearfix"> </div>       
            </div>
            <div class="profile_details w3l">   
                <ul>
                  <li class="dropdown profile_details_drop">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown" aria-expanded="false">
                      <div class="profile_img"> 
                        <span class="prfil-img"><img src="images/images.png" height="150" width="100" alt=""> </span> 
                        <div class="user-name">
                           <?php
$aid=$_SESSION['wsmsaid'];
$ret=mysqli_query($con,"select AdminName from tbladmin where ID='$aid'");
$row=mysqli_fetch_array($ret);
$name=$row['AdminName'];

?>
                          <p><?php echo $name; ?></p>
                          <span>Administrator</span>
                        </div>
                        <i class="fa fa-angle-down"></i>
                        <i class="fa fa-angle-up"></i>
                        <div class="clearfix"></div>  
                      </div>  
                    </a>
                    <ul class="dropdown-menu drp-mnu">
                      <li> <a href="change-password.php"><i class="fa fa-cog"></i> Settings</a> </li> 
                      <li> <a href="admin-profile.php"><i class="fa fa-user"></i> Profile</a> </li> 
                      <li> <a href="index.php"><i class="fa fa-sign-out"></i> Logout</a> </li>
                    </ul>
                  </li>
                </ul>
              </div>
              
             <div class="clearfix"> </div>  
        </div>
