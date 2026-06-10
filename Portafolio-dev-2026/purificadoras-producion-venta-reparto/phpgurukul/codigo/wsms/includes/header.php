<header class="header">
    
    <!-- Header Bar -->
    <div class="header_bar d-flex flex-row align-items-center justify-content-start">
      <div class="header_list">
        <?php 
 $query=mysqli_query($con,"select * from  tblpage where PageType='contactus'");
 while ($row=mysqli_fetch_array($query)) {


 ?>
        <ul class="d-flex flex-row align-items-center justify-content-start">
          <!-- Phone -->
          <li class="d-flex flex-row align-items-center justify-content-start">
            <div><img src="images/phone-call.svg" alt=""></div>
            <span>+<?php  echo $row['MobileNumber'];?></span>
          </li>
          <!-- Address -->
          <li class="d-flex flex-row align-items-center justify-content-start">
            <div><img src="images/placeholder.svg" alt=""></div>
            <span><?php  echo $row['PageDescription'];?></span>
          </li>
          <!-- Email -->
          <li class="d-flex flex-row align-items-center justify-content-start">
            <div><img src="images/envelope.svg" alt=""></div>
            <span><?php  echo $row['Email'];?></span>
          </li>
        </ul>
        <?php } ?>

      </div>
      <div class="ml-auto d-flex flex-row align-items-center justify-content-start">
       <ul class="d-flex flex-row align-items-start justify-content-start">
            <?php if (strlen($_SESSION['wsmsuid']==0)) {?>
            <li ><a href="admin/index.php" style="color: white">Admin</a></li>
            <?php } ?>
        
          </ul>
        <div class="log_reg d-flex flex-row align-items-center justify-content-start">
           
          <ul class="d-flex flex-row align-items-start justify-content-start">
           <?php if (strlen($_SESSION['wsmsuid']==0)) {?>
            <li><a href="signin.php">Login</a></li>
            <li><a href="signup.php">Register</a></li>
           <?php } ?>
          </ul>
          
        </div>
      </div>
    </div>

    <!-- Header Content -->
    <div class="header_content d-flex flex-row align-items-center justify-content-start">
      <div class="logo"><a href="index.php"><span style="color: red">WSMS</span></a></div>
      <nav class="main_nav">
        <ul class="d-flex flex-row align-items-start justify-content-start">
          <li class="active"><a href="index.php">Home</a></li>
          <li><a href="about.php">About us</a></li>
          <li><a href="detailed-page.php">Water Bottle</a></li>
          
          
          <li><a href="cart.php">My Cart</a></li>
           <li><a href="my-order.php">My Order</a></li>
         
          <li><a href="contact.php">Contact</a></li>
        
          
        </ul>
      </nav>
      <div class="submit ml-auto btn btn-primary dropdown-toggle" type="button" data-toggle="dropdown"> My Account</div>
    <ul class="dropdown-menu" style="text-align: center;">
    <li><a href="profile.php">My Profile</a></li>
     
    <li><a href="cart.php">My Cart</a></li>
    <li><a href="my-order.php">My Order</a></li>
    
    <li><a href="change-password.php">Change Password</a></li>
    <li><a href="logout.php">Logout</a></li>
  </ul>
    </div>




  </header>
