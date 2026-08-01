create schema ecommerce_suite;
use ecommerce_suite;
create table users
	(userId varchar(10) primary key,
    firstName varchar(20),
    lastName varchar(20),
    email varchar(50) unique,
    pass varchar(50),
    phoneNo varchar(10) unique,
    city varchar(20),
    roles varchar(10),
    memType varchar(20) default "free",
    memExpiryDate date);

select * from ecommerce_suite.users;

create table storeData
	(storeName varchar(50) unique,
    storeId varchar(10) primary key,
    accountNumber varchar(20),
    verificationStatus varchar(20) default "unverified",
    gstin varchar(20),
    accountHolderName varchar(50),
    userId varchar(10),
    foreign key (userId) references users(userId));




delimiter //

create procedure updateStoreData(
IN p_storeId varchar(10),
IN p_storeName varchar(50),
IN p_accountNumber varchar(20),
IN p_verificationStatus varchar(50),
IN p_gstin varchar(20),
IN p_accountHolderName varchar(50)
)
BEGIN
	update storeData
    set storeName=coalesce(p_storeName, storeName),
		accountNumber=coalesce(p_accountNumber, accountNumber),
        verificationStatus=coalesce(p_verificationStatus, verificationStatus),
        gstin=coalesce(p_gstin, gstin),
        accountHolderName=coalesce(p_accountHolderName, accountHolderName)
	where storeId=p_storeId; 
    END//
    
delimiter ;


create table products
	(productName varchar(50) not null,
    productId varchar(10) primary key,
    storeId varchar(10) not null,
    brand varchar(50) not null,
    stock integer not null,
    price double not null,
    category varchar(50) not null,
    subCategory varchar(50),
    rating float default 0.0,
    noOfReviews int default 0,
    details varchar(255) not null,
    foreign key (storeId) references storeData(storeId));


delimiter //
create procedure filterProducts(
IN p_storeId varchar(10),
IN p_brand varchar(50),
IN p_category varchar(50),
IN p_subCategory varchar(50),
IN p_maxPrice double,
IN p_minPrice double,
IN p_inStock varchar(10),
IN p_notInStock varchar(10),
IN p_minRatings double,
IN p_storeName varchar(50))
BEGIN
select s.storeName, p.productName, p.brand, p.productId, p.storeId, p.stock, p.price, p.category, p.subCategory,
p.rating, p.noOfReviews, p.details
from storeData s
join products p 
on s.storeId = p.storeId
where (p_storeId is null or p.storeId = p_storeId)
and (p_brand is null or p.brand = p_brand)
and (p_category is null or p.category = p_category)
and (p_subCategory is null or p.subCategory = p_subCategory)
and (p_maxPrice is null or p.price<=p_maxPrice)
and (p_minPrice is null or p.price>=p_minPrice)
and (p_inStock is null or p.stock>0)
and (p_notInStock is null or p.stock=0)
and (p_minRatings is null or p.rating>=p_minRatings)
and (p_storeName is null or s.storeName=p_storeName);
END//
delimiter ;

delimiter //
create procedure updateProducts(
IN p_productId varchar(10),
IN p_productName varchar(50),
IN p_brand varchar(50),
IN p_price double,
IN p_category varchar(50),
IN p_subCategory varchar(50),
IN p_details varchar(255),
IN p_quantity integer)
BEGIN
update products
set 
	productName = coalesce(p_productName, productName),
    brand = coalesce(p_brand, brand),
    price = coalesce(p_price, price),
    category = coalesce(p_category, category),
    subCategory = coalesce(p_subCategory, subCategory),
    details = coalesce(p_details, details),
    stock = stock + coalesce(p_quantity, 0)
where productId = p_productId;
END//
delimiter ;

create table orders
(orderId varchar(10) primary key,
orderDate date not null,
orderStatus varchar(10) not null,
totalOrderValue double not null,
userId varchar(10) not null,
deliveryPincode varchar(6) not null,
expDeliveryDate date not null,
transactionId varchar(50) not null,
paymentStatus varchar(10) not null,
foreign key (userId) references users(userId));

create table orderItems
(orderItemId varchar(10) primary key,
orderId varchar(10) not null,
productId varchar(10) not null,
priceAtPurchase double not null,
quantity integer not null,
foreign key (orderId) references orders(orderId),
foreign key (productId) references products(productId));


