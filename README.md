# Kantox

API for managing products, offers and processing shopping baskets with automatic discount application.

## Quick Start

### Local Development

* Run `mix setup` to install and configure dependencies
* Start Phoenix server with `mix phx.server` or inside IEx with `iex -S mix phx.server`
* Visit [`localhost:4000`](http://localhost:4000) in your browser

### Docker

* Run `docker-compose up --build` to build and start the application
* The database will be automatically migrated and seeded on startup
* Visit [`localhost:4000`](http://localhost:4000) in your browser
* To manually run seeds: `docker-compose exec app /app/bin/seed`
* For more information, see the Docker section below

## START HERE - API Documentation

The API has complete interactive documentation:

* **Swagger UI**: http://localhost:4000/api/swagger
* **OpenAPI JSON**: http://localhost:4000/api/openapi

## Endpoints

* `GET /api/health` - Health check
* `GET /api/products` - List products
* `POST /api/products` - Create product
* `GET /api/offers` - List offers
* `POST /api/offers` - Create offer
* `POST /api/baskets` - Process basket with discounts

## Docker

### Starting the Application

```bash
# Build and start all services
docker-compose up --build

# Or run in detached mode
docker-compose up -d --build
```

The application will automatically:
1. Wait for the database to be healthy
2. Run migrations (`Kantox.Release.migrate`)
3. Run seeds (`Kantox.Release.seed`)
4. Start the Phoenix server

### Manual Operations

```bash
# Run migrations manually
docker-compose exec app /app/bin/migrate

# Run seeds manually (idempotent - safe to run multiple times)
docker-compose exec app /app/bin/seed

# Access the running container
docker-compose exec app sh

# View logs
docker-compose logs -f app

# Stop services
docker-compose down

# Stop and remove volumes (deletes all data)
docker-compose down -v
```

### Environment Variables

Configure in `docker-compose.yml`:
- `DATABASE_URL` - PostgreSQL connection string
- `SECRET_KEY_BASE` - Secret key for encryption (generate with `mix phx.gen.secret`)
- `PHX_HOST` - Application hostname
- `PHX_SERVER` - Enable Phoenix server (`true`)
- `PORT` - Server port (default: 4000)

## Additional Documentation

* [Database Indexes](docs/DATABASE_INDEXES.md) - Database indexes documentation

## Tests and Code Quality

* `mix test` - Run tests
* `mix precommit` - Compile, format and test (recommended before commits)
* `mix coveralls.html` - Generate test coverage report

## Testing distributed cache system via ETS + PubSub

```bash
# Terminal 1 - Node 1
iex --name node1@127.0.0.1 --cookie secret -S mix phx.server

# Terminal 2 - Node 2
PORT=4001 iex --name node2@127.0.0.1 --cookie secret -S mix phx.server

# Terminal 3 - Node 3
PORT=4002 iex --name node3@127.0.0.1 --cookie secret -S mix phx.server
```

### Connect the nodes

```elixir
# On node1
Node.connect(:"node2@127.0.0.1")
Node.connect(:"node3@127.0.0.1")
Node.list()
# => [:"node2@127.0.0.1", :"node3@127.0.0.1"]
```

### Test synchronization

```elixir
# On node1
Kantox.Products.create(%{code: "TEST", name: "Test", price: 1.0})

# On node2 (after ~10ms)
Kantox.Cache.ProductsCache.get_by_code("TEST")
# => %Product{code: "TEST", ...}
`
