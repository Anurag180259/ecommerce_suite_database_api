# E-Commerce Integration Suite — Database API

## Overview

The **Database API** is the System API responsible for all persistence operations in the E-Commerce Integration Suite. It provides the Process API with direct access to the MySQL database and handles all database operations for users, stores, products, carts, orders, and order items.

**Key responsibilities:**
- Persistence of application data in MySQL
- SQL query execution and stored procedure calls via the MuleSoft Database Connector
- Product filtering and inventory updates
- Cart persistence and filtering
- Transactional order creation with stock decrement and cart clearance

---

## Architecture

The Database API is one of two System APIs in the API-led connectivity model, sitting directly above the MySQL database layer.

```
    AI Agent (via MCP Server)
              ↓
    Experience API Layer
              ↓
         Process API
              ↓
      System API Layer
    ┌──────────────────┐
    │                  │
    ▼                  ▼
Database API     Mock Payment API
(This Layer)
    │
    ▼
MySQL Database
```

**Role of Database API:**
- Acts as the database-focused System API
- Executes SQL queries and stored procedures against MySQL
- Returns raw database results to the Process API with minimal transformation
- Never called directly by the Experience API or external consumers

For the complete system architecture, deployment topology, and AI integration details, refer to the [main project repository](https://github.com/Anurag180259/ecommerce_suite).

---

## Prerequisites

- **Mule Runtime**: 4.4.0 or later
- **Java**: JDK 11 or higher
- **MuleSoft Connector Packs**:
  - HTTP Connector
  - APIKit
  - Database Connector
- **MySQL**: Accessible from the Database API at the configured host and port
- **Database Schema**: `ecommerce_suite` must be created before deployment

---

## Setup & Installation

### 1. Clone the Repository

```bash
git clone https://github.com/Anurag180259/ecommerce_suite_database_api.git
cd ecommerce_suite_database_api
```

### 2. Configure Properties

Create a `configuration.properties` file in `src/main/resources/`:

1. Right-click on `src/main/resources/` folder
2. Select **New** → **File**
3. Name it `configuration.properties`
4. Copy the content from [`configuration.example.properties`](./src/main/resources/configuration.example.properties)
5. Update the values according to your environment

The following properties must be configured:

```properties
# Database API Listener
http.port=DATABASE_API_HTTP_PORT_NUMBER

# MySQL Connection
db.host=DATABASE_HOST_NAME
db.port=DATABASE_PORT_NUMBER
db.username=DATABASE_USERNAME
db.password=DATABASE_PASSWORD
db.database=DATABASE_NAME
```

> **Important:** Do not commit real database credentials to the repository.

### 3. Configure the Database

Create the `ecommerce_suite` schema along with the required tables and stored procedures in MySQL before deploying the API. Use [Schema.sql](./Schema.sql) for database schema.

**Tables:**
- `users`
- `storeData`
- `products`
- `carts`
- `orders`
- `orderItems`

**Stored Procedures:**
- `updateStoreData`
- `filterProducts`
- `updateProducts`
- `filterCartItems`
- `deleteCartByFilters`

### 4. Build the Project

In Anypoint Studio:

1. Right-click on the project in **Package Explorer**
2. Select **Run As** → **Mule Application**

The project will automatically build and deploy to the embedded Mule Runtime.

### 5. Verify Deployment

Once deployed, access the API Console:

```
http://localhost:<port>/console/
```

Replace `<port>` with your configured `http.port` value.

---

## API Endpoints

### Quick Reference

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/database/users` | Create a user |
| `GET` | `/database/users` | Get user by email |
| `GET` | `/database/users/getByRole` | Get users by role |
| `POST` | `/database/stores` | Create a store |
| `GET` | `/database/stores` | Get stores by user ID |
| `GET` | `/database/stores/{storeId}` | Get a store by ID |
| `PATCH` | `/database/stores/{storeId}` | Update store information |
| `GET` | `/database/stores/verificationStatus` | Get stores by verification status |
| `POST` | `/database/products` | Create a product |
| `GET` | `/database/products` | Get products by filters |
| `GET` | `/database/products/{productId}` | Get a product by ID |
| `PATCH` | `/database/products/{productId}` | Update product information |
| `POST` | `/database/carts` | Add a cart item |
| `GET` | `/database/carts` | Get cart items by filters |
| `GET` | `/database/carts/{cartItemId}` | Get a cart item by ID |
| `PATCH` | `/database/carts/{cartItemId}` | Update cart item quantity |
| `DELETE` | `/database/carts` | Delete cart items by filters |
| `POST` | `/database/orders` | Create an order |
| `GET` | `/database/orders` | Get orders by user ID |
| `GET` | `/database/orders/{orderId}` | Get an order by ID |
| `GET` | `/database/orders/buyer` | Get orders with items for a buyer |
| `GET` | `/database/orders/seller` | Get orders with items for a seller |
| `GET` | `/database/orders/paymentStatus` | Get orders by payment status |
| `PATCH` | `/database/orders/{orderId}/cancellation` | Cancel an order |
| `PATCH` | `/database/orders/{orderId}/paymentStatus` | Update order payment status |
| `GET` | `/database/orderItems/orderId` | Get order items by order ID |
| `GET` | `/database/orderItems/storeId` | Get order items by store ID |

> This API is a System API intended to be consumed only by the Process API.

---

### User Management

#### Create User
```
POST /database/users
Content-Type: application/json
```

**Request Body:**
```json
{
  "userId": "B-a7d2c1",
  "firstName": "John",
  "lastName": "Doe",
  "email": "newuser@example.com",
  "password": "hashedPassword",
  "phoneNo": "9876543210",
  "city": "Pune",
  "role": "buyer"
}
```

> Password is always pre-hashed by the Process API using BCrypt before being sent to this endpoint.

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

**Error Responses:**
- `409 Conflict` — Email already exists

---

#### Get User by Email
```
GET /database/users?email=user@example.com
```

**Query Parameters:**
- `email` (required) — Email address to look up

**Response (200 OK):**
```json
[
  {
    "userId": "B-a7d2c1",
    "firstName": "John",
    "lastName": "Doe",
    "email": "user@example.com",
    "pass": "hashedPassword",
    "phoneNo": "9876543210",
    "city": "pune",
    "roles": "buyer",
    "memType": "free",
    "memExpiryDate": null
  }
]
```

> Returns an array. An empty array means no user was found with that email.

---

#### Get Users by Role
```
GET /database/users/getByRole?role=admin
```

**Query Parameters:**
- `role` (required): `admin`, `buyer`, or `seller`

**Response (200 OK):**
```json
[
  {
    "userId": "A-1c3d2f",
    "firstName": "Admin",
    "lastName": "User",
    "email": "admin@example.com",
    "pass": "hashedPassword",
    "phoneNo": "9876543210",
    "city": "pune",
    "roles": "admin",
    "memType": "free",
    "memExpiryDate": null
  }
]
```

> Used by the Process API to check if an admin already exists before the admin setup flow.

---

### Store Management

#### Create Store
```
POST /database/stores
Content-Type: application/json
```

**Request Body:**
```json
{
  "storeName": "Electronics Plus",
  "storeId": "ST-4f2a1c",
  "accountHolderName": "John Doe",
  "gstin": "18AABCR5055K1Z0",
  "accountNumber": "1234567890123456",
  "userId": "S-78a3c4"
}
```

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

**Error Responses:**
- `409 Conflict` — Store name already exists

---

#### Get Stores by User ID
```
GET /database/stores?userId=S-78a3c4
```

**Query Parameters:**
- `userId` (required) — The seller's user ID

**Response (200 OK):**
```json
[
  {
    "storeName": "Electronics Plus",
    "storeId": "ST-4f2a1c",
    "accountNumber": "1234567890123456",
    "verificationStatus": "unverified",
    "gstin": "18AABCR5055K1Z0",
    "accountHolderName": "John Doe",
    "userId": "S-78a3c4"
  }
]
```

---

#### Get Store by ID
```
GET /database/stores/{storeId}
```

**Response (200 OK):**
```json
[
  {
    "storeName": "Electronics Plus",
    "storeId": "ST-4f2a1c",
    "accountNumber": "1234567890123456",
    "verificationStatus": "unverified",
    "gstin": "18AABCR5055K1Z0",
    "accountHolderName": "John Doe",
    "userId": "S-78a3c4"
  }
]
```

> Returns an array. Raises `APP:NOT_FOUND` if no store is found.

---

#### Update Store
```
PATCH /database/stores/{storeId}
Content-Type: application/json
```

**Request Body:**
```json
{
  "storeName": "Electronics Plus",
  "accountNumber": "1234567890123456",
  "verificationStatus": "verified",
  "gstin": "18AABCR5055K1Z0",
  "accountHolderName": "John Doe"
}
```

> All fields are optional. The `updateStoreData` stored procedure uses `COALESCE` so fields not supplied remain unchanged.

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

#### Get Stores by Verification Status
```
GET /database/stores/verificationStatus?verificationStatus=verified
```

**Query Parameters:**
- `verificationStatus` (required): `verified`, `unverified`, or `rejected`

**Response (200 OK):**
```json
[
  {
    "storeName": "Electronics Plus",
    "storeId": "ST-4f2a1c",
    "accountNumber": "1234567890123456",
    "verificationStatus": "verified",
    "gstin": "18AABCR5055K1Z0",
    "accountHolderName": "John Doe",
    "userId": "S-78a3c4"
  }
]
```

---

### Product Management

#### Create Product
```
POST /database/products
Content-Type: application/json
```

**Request Body:**
```json
{
  "productName": "Wireless Headphones",
  "productId": "P-a4b231",
  "storeId": "ST-4f2a1c",
  "brand": "AudioTech",
  "stock": 50,
  "price": 5299,
  "category": "Electronics",
  "subCategory": "Audio",
  "details": "High-quality wireless headphones with noise cancellation"
}
```

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

#### Get Products by Filters
```
GET /database/products
```

**Query Parameters (all optional):**
- `storeId`
- `brand`
- `category`
- `subCategory`
- `maxPrice`
- `minPrice`
- `inStock` — `true` or `false`
- `minRatings`
- `storeName`

**Response (200 OK):**
```json
[
  {
    "storeName": "Electronics Plus",
    "productName": "Wireless Headphones",
    "brand": "AudioTech",
    "productId": "P-a4b231",
    "storeId": "ST-4f2a1c",
    "stock": 50,
    "price": 5299,
    "category": "Electronics",
    "subCategory": "Audio",
    "rating": 0.0,
    "noOfReviews": 0,
    "details": "High-quality wireless headphones with noise cancellation"
  }
]
```

> Uses the `filterProducts` stored procedure which joins `storeData` with `products`.

---

#### Get Product by ID
```
GET /database/products/{productId}
```

**Response (200 OK):**
```json
[
  {
    "productName": "Wireless Headphones",
    "productId": "P-a4b231",
    "storeId": "ST-4f2a1c",
    "brand": "AudioTech",
    "stock": 50,
    "price": 5299,
    "category": "Electronics",
    "subCategory": "Audio",
    "rating": 0.0,
    "noOfReviews": 0,
    "details": "High-quality wireless headphones with noise cancellation"
  }
]
```

> Returns an array. Raises `APP:NOT_FOUND` if no product is found.

---

#### Update Product
```
PATCH /database/products/{productId}
Content-Type: application/json
```

**Request Body:**
```json
{
  "productName": "Premium Wireless Headphones",
  "brand": "AudioTech",
  "price": 5999,
  "category": "Electronics",
  "subCategory": "Audio",
  "details": "Updated product description",
  "quantity": 10
}
```

> All fields are optional. The `updateProducts` stored procedure uses `COALESCE` for product fields. The `quantity` field is added to the existing stock (`stock = stock + quantity`). For restocking, pass only `quantity`. For product detail updates, omit `quantity`.

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

### Cart Management

#### Add Cart Item
```
POST /database/carts
Content-Type: application/json
```

**Request Body:**
```json
{
  "cartItemId": "CT-a3f9b2",
  "userId": "B-a7d2c1",
  "productId": "P-a4b231",
  "quantity": 2
}
```

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

#### Get Cart Items by Filters
```
GET /database/carts?userId=B-a7d2c1
```

**Query Parameters:**
- `userId` (required) — The buyer's user ID
- `productId` (optional) — Filter by product ID

**Response (200 OK):**
```json
[
  {
    "cartItemId": "CT-a3f9b2",
    "userId": "B-a7d2c1",
    "productId": "P-a4b231",
    "quantity": 2
  }
]
```

> Uses the `filterCartItems` stored procedure.

---

#### Get Cart Item by ID
```
GET /database/carts/{cartItemId}
```

**Response (200 OK):**
```json
[
  {
    "cartItemId": "CT-a3f9b2",
    "userId": "B-a7d2c1",
    "productId": "P-a4b231",
    "quantity": 2
  }
]
```

> Returns an array. Raises `APP:NOT_FOUND` if no cart item is found.

---

#### Update Cart Item Quantity
```
PATCH /database/carts/{cartItemId}
Content-Type: application/json
```

**Request Body:**
```json
{
  "quantity": 5
}
```

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

#### Delete Cart Items
```
DELETE /database/carts
```

**Query Parameters:**
- `userId` — Delete all items for a user (used when clearing the cart)
- `cartItemId` — Delete a specific cart item (used when removing a single item)

> Uses the `deleteCartByFilters` stored procedure. Either `userId` or `cartItemId` can be passed depending on the operation.

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

### Order Management

#### Create Order
```
POST /database/orders
Content-Type: application/json
```

**Request Body:**
```json
{
  "orderId": "OD-7c4e1a",
  "orderStatus": "confirmed",
  "totalOrderValue": 5299,
  "userId": "B-a7d2c1",
  "deliveryPincode": "100001",
  "transactionId": "PAY-3f1a2b4c",
  "paymentStatus": "success",
  "deliveryTime": "P4D",
  "isCart": false,
  "listOfItems": [
    {
      "orderItemId": "OI-3a1b2c",
      "productId": "P-a4b231",
      "quantity": 1,
      "orderId": "OD-7c4e1a",
      "priceAtPurchase": 5299,
      "storeId": "ST-4f2a1c"
    }
  ]
}
```

**Business Logic:**

This endpoint executes all of the following inside a single Mule `Try` scope with `transactionalAction="ALWAYS_BEGIN"`:

1. Inserts the order into the `orders` table — `expDeliveryDate` is computed as `now() + deliveryTime`
2. For each item in `listOfItems`:
   - Inserts the order item into the `orderItems` table
   - Decrements product stock (`stock = stock - quantity`)
3. If `isCart` is `true`, deletes all cart items for the user

**Response (200 OK):**

Returns the result of the last database operation in the transaction.

---

#### Get Orders by User ID
```
GET /database/orders?userId=B-a7d2c1
```

**Query Parameters:**
- `userId` (required) — The buyer's user ID

**Response (200 OK):**
```json
[
  {
    "orderId": "OD-7c4e1a",
    "orderDate": "2026-09-07",
    "orderStatus": "confirmed",
    "totalOrderValue": 5299,
    "userId": "B-a7d2c1",
    "deliveryPincode": "100001",
    "expDeliveryDate": "2026-09-11",
    "transactionId": "PAY-3f1a2b4c",
    "paymentStatus": "success"
  }
]
```

---

#### Get Order by ID
```
GET /database/orders/{orderId}
```

**Response (200 OK):**
```json
[
  {
    "orderId": "OD-7c4e1a",
    "orderDate": "2026-09-07",
    "orderStatus": "confirmed",
    "totalOrderValue": 5299,
    "userId": "B-a7d2c1",
    "deliveryPincode": "100001",
    "expDeliveryDate": "2026-09-11",
    "transactionId": "PAY-3f1a2b4c",
    "paymentStatus": "success"
  }
]
```

> Returns an array. Raises `APP:NOT_FOUND` if no order is found.

---

#### Get Buyer Orders
```
GET /database/orders/buyer?userId=B-a7d2c1
```

**Query Parameters:**
- `userId` (required) — The buyer's user ID

**Response (200 OK):**
```json
[
  {
    "orderId": "OD-7c4e1a",
    "orderDate": "2026-09-07",
    "orderStatus": "confirmed",
    "totalOrderValue": 5299,
    "userId": "B-a7d2c1",
    "deliveryPincode": "100001",
    "expDeliveryDate": "2026-09-11",
    "transactionId": "PAY-3f1a2b4c",
    "paymentStatus": "success",
    "orderItems": [
      {
        "orderItemId": "OI-3a1b2c",
        "orderId": "OD-7c4e1a",
        "productId": "P-a4b231",
        "storeId": "ST-4f2a1c",
        "priceAtPurchase": 5299,
        "quantity": 1,
        "productName": "Wireless Headphones"
      }
    ]
  }
]
```

> Enriches each order with its order items and product names by performing nested database lookups.

---

#### Get Seller Orders
```
GET /database/orders/seller?userId=S-78a3c4
```

**Query Parameters:**
- `userId` (required) — The seller's user ID

**Response (200 OK):**
```json
[
  {
    "storeName": "Electronics Plus",
    "storeId": "ST-4f2a1c",
    "accountNumber": "1234567890123456",
    "verificationStatus": "verified",
    "gstin": "18AABCR5055K1Z0",
    "accountHolderName": "John Doe",
    "userId": "S-78a3c4",
    "orderItems": [
      {
        "orderItemId": "OI-3a1b2c",
        "orderId": "OD-7c4e1a",
        "productId": "P-a4b231",
        "storeId": "ST-4f2a1c",
        "priceAtPurchase": 5299,
        "quantity": 1,
        "productName": "Wireless Headphones"
      }
    ]
  }
]
```

> Fetches all stores for the seller, then for each store fetches its order items and enriches them with product names.

---

#### Cancel Order
```
PATCH /database/orders/{orderId}/cancellation
```

Sets `orderStatus` to `cancelled` and `paymentStatus` to `reversed` for the specified order.

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

#### Update Payment Status
```
PATCH /database/orders/{orderId}/paymentStatus
Content-Type: application/json
```

**Request Body:**
```json
{
  "paymentStatus": "success"
}
```

> Supported values: `pending`, `success`, `reversed`. When `paymentStatus` is `success`, `orderStatus` is set to `confirmed`. Otherwise `orderStatus` remains `pending`.

**Response (200 OK):**
```json
{
  "affectedRows": 1
}
```

---

#### Get Orders by Payment Status
```
GET /database/orders/paymentStatus?paymentStatus=pending
```

**Query Parameters:**
- `paymentStatus` (required): `pending`, `success`, or `reversed`

**Response (200 OK):**
```json
[
  {
    "orderId": "OD-7c4e1a",
    "orderDate": "2026-09-07",
    "orderStatus": "pending",
    "totalOrderValue": 5299,
    "userId": "B-a7d2c1",
    "deliveryPincode": "100001",
    "expDeliveryDate": "2026-09-11",
    "transactionId": "PAY-3f1a2b4c",
    "paymentStatus": "pending"
  }
]
```

> Used by the Process API background scheduler to resolve pending payments.

---

### Order Item Management

#### Get Order Items by Order ID
```
GET /database/orderItems/orderId?orderId=OD-7c4e1a
```

**Query Parameters:**
- `orderId` (required)

**Response (200 OK):**
```json
[
  {
    "orderItemId": "OI-3a1b2c",
    "orderId": "OD-7c4e1a",
    "productId": "P-a4b231",
    "storeId": "ST-4f2a1c",
    "priceAtPurchase": 5299,
    "quantity": 1
  }
]
```

---

#### Get Order Items by Store ID
```
GET /database/orderItems/storeId?storeId=ST-4f2a1c
```

**Query Parameters:**
- `storeId` (required)

**Response (200 OK):**
```json
[
  {
    "orderItemId": "OI-3a1b2c",
    "orderId": "OD-7c4e1a",
    "productId": "P-a4b231",
    "storeId": "ST-4f2a1c",
    "priceAtPurchase": 5299,
    "quantity": 1
  }
]
```

---

## Database Schema (Foreign Key Relationship)

```
ecommerce_suite
│
├── users
│
├── storeData
│     └── userId → users.userId
│
├── products
│     └── storeId → storeData.storeId
│
├── carts
│     ├── userId → users.userId
│     └── productId → products.productId
│
├── orders
│     └── userId → users.userId
│
└── orderItems
      ├── orderId → orders.orderId
      ├── productId → products.productId
      └── storeId → storeData.storeId
```

---

## Stored Procedures

### `updateStoreData`
Updates store fields for a given `storeId`. Uses `COALESCE` so only supplied fields are updated — unspecified fields remain unchanged.

### `filterProducts`
Filters products by joining `storeData` with `products`. Supports filtering by `storeId`, `brand`, `category`, `subCategory`, `maxPrice`, `minPrice`, `inStock`, `minRatings`, and `storeName`. All parameters are optional.

### `updateProducts`
Updates product fields and applies the supplied `quantity` to existing stock (`stock = stock + quantity`). Uses `COALESCE` for all product fields so only supplied fields are updated.

### `filterCartItems`
Retrieves cart items for a given `userId` with an optional `productId` filter.

### `deleteCartByFilters`
Deletes cart items matching the supplied `userId` and/or `cartItemId`. Used for both single-item removal and full cart clearance.

---

## Error Handling

| Status Code | Description |
|---|---|
| `200 OK` | Successful request |
| `400 Bad Request` | Invalid request format or missing required fields |
| `404 Not Found` | Resource not found |
| `405 Method Not Allowed` | HTTP method not supported |
| `406 Not Acceptable` | Content type not acceptable |
| `409 Conflict` | Duplicate resource (email or store name) |
| `415 Unsupported Media Type` | Request body media type not supported |
| `501 Not Implemented` | Feature not yet implemented |

**Error Response Format:**
```json
{
  "message": "Descriptive error message"
}
```

---

## Logging

The Database API logs key events at `INFO` level:

- Incoming requests (endpoint, operation)
- Database operation details
- Errors and exceptions

Logs are output to the Mule Runtime console and can be redirected to a file via Mule configuration.

---

## Deployment

1. Right-click on the project in **Package Explorer**
2. Select **Run As** → **Mule Application**
3. The embedded Mule Runtime will start and deploy the application
4. Access the API Console at `http://localhost:<http.port>/console/`

> Ensure the MySQL instance is running and accessible before deploying.

---

## Troubleshooting

### Database Connection Failed
- **Error:** Connection refused or database host unreachable
- **Solution:** Ensure MySQL is running and `db.host`, `db.port`, `db.username`, `db.password`, and `db.database` are correctly configured

### Database Authentication Failed
- **Error:** Authentication failure when connecting to MySQL
- **Solution:** Verify the configured database username and password

### Schema Not Found
- **Error:** Table or schema does not exist
- **Solution:** Ensure the `ecommerce_suite` schema and all required tables and stored procedures have been created before deployment

### Duplicate Email
- **Error:** `409 Conflict`
- **Solution:** Use an email address that does not already exist in the `users` table

### Duplicate Store Name
- **Error:** `409 Conflict`
- **Solution:** Use a store name that does not already exist in the `storeData` table

### Foreign Key Constraint Violation
- **Error:** Foreign key constraint failure on insert
- **Solution:** Ensure referenced users, stores, products, and orders exist before creating dependent records

---

## Related Documentation

- **RAML Specification:** [`ecommercesuitedatabasesystemapi2.raml`](./src/main/resources/api)
- **API Console:** Available at `/console/` path after deployment
- **Main Project Repository:** [ecommerce_suite](https://github.com/Anurag180259/ecommerce_suite) — Contains overall architecture, deployment guide, and project scope

---

## Support

For issues, questions, or contributions, please refer to the main project repository.

---

**Last Updated:** September 2026
**Version:** 1.0
**Maintained by:** Anurag Ninave
