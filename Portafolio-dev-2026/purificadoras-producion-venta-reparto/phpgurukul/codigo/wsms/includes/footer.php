<footer class="footer">
		<div class="footer_content">
			<div class="container">
				<div class="row">
					
					<!-- Footer Column -->
					<div class="col-xl-3 col-lg-6 footer_col">
						<div class="footer_about">
							<div class="footer_logo"><a href="index.php"><span>WSMS</span></a></div>
							<div class="footer_text">
								<?php 
 $query=mysqli_query($con,"select * from  tblpage where PageType='aboutus'");
 while ($row=mysqli_fetch_array($query)) {


 ?>
						<p style="color: white"><?php  echo $row['PageDescription'];?></p>
						<?php } ?>
							</div>
							
							
						</div>
					</div>

					<!-- Footer Column -->
					<div class="col-xl-3 col-lg-6 footer_col">
						<div class="footer_column">
							<div class="footer_title">Information</div>
							<div class="footer_info">
								<?php 
 $query=mysqli_query($con,"select * from  tblpage where PageType='contactus'");
 while ($row=mysqli_fetch_array($query)) {


 ?>
								<ul>
									<!-- Phone -->
									<li class="d-flex flex-row align-items-center justify-content-start">
										<div><img src="images/phone-call.svg" alt=""></div>
										<span>+<?php  echo $row['MobileNumber'];?></span>
									</li>
									
									
									<!-- Email -->
									<li class="d-flex flex-row align-items-center justify-content-start">
										<div><img src="images/envelope.svg" alt=""></div>
										<span><?php  echo $row['Email'];?></span>
									</li>
								</ul>
								<?php } ?>
							</div>
							<div class="footer_links usefull_links">
								<div class="footer_title">Usefull Links</div>
								<ul>
									<li><a href="about.php">About Us</a></li>
									<li><a href="contact.php">Contact Us</a></li>
									<li><a href="detailed-page.php">Water Bottle Detailed</a></li>
									
								</ul>
							</div>
						</div>
					</div>


					<!-- Footer Column -->
					<div class="col-xl-3 col-lg-6 footer_col">
						<div class="footer_title">Bottle Info</div>
						<div class="listing_small"><?php 
 $query=mysqli_query($con,"select * from tblwaterbottle order by rand() limit 1");
 while ($row=mysqli_fetch_array($query)) {


 ?>
							<div class="listing_small_image">
								<div>
									<img class="b-goods-f__img img-scale" src="admin/images/<?php echo $row['Image'];?>" alt="<?php echo $row['Image'];?>" width='300' height='250'/>
								</div>
								
								<div class="tag_price listing_price"><?php echo $row['CompanyName'];?> <?php echo $row['BottleSize'];?></div>
							</div>
							
						</div>
					</div>
<?php } ?>
				</div>
			</div>
		</div>
		
	</footer>