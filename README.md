# Kantox

API for managing products, offers and processing shopping baskets with automatic discount application.

## Quick Start

### Local Development

* Run `mix setup` to install and configure dependencies
* Start Phoenix server with `mix phx.server` or inside IEx with `iex -S mix phx.server`
* Visit [`localhost:4000`](http://localhost:4000) in your browser

### Docker

* Run `docker-compose up --build` to build and start the application
* Visit [`localhost:4000`](http://localhost:4000) in your browser
* For more information, see [docs/DOCKER.md](docs/DOCKER.md)

## API Documentation

The API has complete documentation via Swagger UI:

* **Swagger UI**: http://localhost:4000/api/swagger
* **OpenAPI JSON**: http://localhost:4000/api/openapi

## Main Endpoints

* `GET /api/health` - Health check
* `GET /api/products` - List products
* `POST /api/products` - Create product
* `GET /api/offers` - List offers
* `POST /api/offers` - Create offer
* `POST /api/baskets` - Process basket with discounts

## Additional Documentation

* [Docker Deployment](docs/DOCKER.md) - Docker deployment guide
* [Database Indexes](docs/DATABASE_INDEXES.md) - Database indexes documentation

## Tests and Code Quality

* `mix test` - Run tests
* `mix precommit` - Compile, format and test (recommended before commits)
* `mix coveralls.html` - Generate test coverage report

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix
