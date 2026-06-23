# Marketplace - Campus Platform

A Spring Boot 3.x backend for a campus marketplace application with PostgreSQL. This platform enables students to buy/sell products and services within the university campus.

## Tech Stack

- **Java 17+** (compiled with Java 21)
- **Spring Boot 3.2.x**
- **Spring Data JPA** (Hibernate)
- **PostgreSQL** (Database)
- **Lombok** (Boilerplate reduction)
- **Springdoc OpenAPI** (Swagger UI)
- **Maven** (Build tool)

## Prerequisites

- JDK 17 or later (recommended: JDK 21)
- Maven 3.8+
- PostgreSQL 14+
- IDE (IntelliJ IDEA recommended, or VS Code with Java extensions)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/your-org/market-place-app.git
cd market-place-app/marketplace
```

### 2. Setup PostgreSQL Database

Create a database in PostgreSQL:

```sql
CREATE DATABASE "market-place-app";
```

Then run the SQL schema from `Câu lệnh Database.md` (located in the project root) to create tables and seed data.

### 3. Configure Environment Variables (Optional)

The application uses sensible defaults for local development. You can override them via environment variables:

| Variable | Default Value | Description |
|---|---|---|
| `DATABASE_URL` | `jdbc:postgresql://localhost:5432/market-place-app` | PostgreSQL JDBC URL |
| `DATABASE_USERNAME` | `postgres` | Database username |
| `DATABASE_PASSWORD` | `12345` | Database password |
| `SERVER_PORT` | `8080` | Application server port |

**Windows (CMD):**
```cmd
set DATABASE_URL=jdbc:postgresql://localhost:5432/market-place-app
set DATABASE_USERNAME=postgres
set DATABASE_PASSWORD=your_password
```

**Windows (PowerShell):**
```powershell
$env:DATABASE_URL="jdbc:postgresql://localhost:5432/market-place-app"
$env:DATABASE_USERNAME="postgres"
$env:DATABASE_PASSWORD="your_password"
```

**macOS / Linux:**
```bash
export DATABASE_URL=jdbc:postgresql://localhost:5432/market-place-app
export DATABASE_USERNAME=postgres
export DATABASE_PASSWORD=your_password
```

If no environment variables are set, the application will use the default values from `application.properties`.

### 4. Build & Run

```bash
# Clean & build
mvn clean install -DskipTests

# Run the application
mvn spring-boot:run
```

The application will start at `http://localhost:8080`.

### 5. Verify

- **Health Check:** `http://localhost:8080/actuator/health`
- **Swagger UI:** `http://localhost:8080/swagger-ui.html`
- **API Docs (JSON):** `http://localhost:8080/v3/api-docs`

## Project Structure

```
marketplace/
├── src/
│   ├── main/
│   │   ├── java/market/campus/com/
│   │   │   ├── MarketplaceApplication.java
│   │   │   ├── controller/
│   │   │   │   ├── CartController.java
│   │   │   │   ├── NotificationController.java
│   │   │   │   ├── OrderController.java
│   │   │   │   └── ProductController.java
│   │   │   ├── dto/
│   │   │   │   ├── request/
│   │   │   │   └── response/
│   │   │   ├── exception/
│   │   │   ├── model/
│   │   │   │   ├── enums/
│   │   │   │   └── ...
│   │   │   ├── repository/
│   │   │   └── service/
│   │   └── resources/
│   │       └── application.properties
│   └── test/
└── pom.xml
```

## API Endpoints

### Orders

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/orders/create` | Create a new order from cart |
| `GET` | `/api/orders` | Get all orders for current user |
| `GET` | `/api/orders/{orderId}` | Get order detail |
| `PUT` | `/api/orders/{orderId}/accept` | **Seller accepts/approves an order** |
| `PUT` | `/api/orders/{orderId}/complete` | **Seller marks order as completed** |

### Notifications

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/notifications` | Get all notifications for current user |
| `GET` | `/api/notifications/unread` | Get unread notifications |
| `GET` | `/api/notifications/unread/count` | Count unread notifications |
| `PUT` | `/api/notifications/{id}/read` | Mark a notification as read |
| `PUT` | `/api/notifications/read-all` | Mark all notifications as read |

All endpoints require `X-User-Id` header (temporary authentication until Firebase Auth is integrated).

## Transactional Guarantee

- **`acceptOrder`** and **`completeOrder`** are annotated with `@Transactional`.
- If notification creation fails (e.g., database write error), the order status update is automatically **rolled back**, ensuring data consistency.
- This prevents the scenario where an order is approved/completed but the buyer never receives a notification.

## Contributing

1. Create a feature branch from `main`
2. Make your changes
3. Run `mvn clean install` to verify the build
4. Submit a Pull Request

## License

MIT