# Synchronized Cache in Cluster

This document explains how the cache system works in a distributed environment with multiple nodes.

## 🏗️ Architecture

```
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│   Node 1    │         │   Node 2    │         │   Node 3    │
│             │         │             │         │             │
│  ┌───────┐  │         │  ┌───────┐  │         │  ┌───────┐  │
│  │  ETS  │  │◄───────►│  │  ETS  │  │◄───────►│  │  ETS  │  │
│  │ Cache │  │         │  │ Cache │  │         │  │ Cache │  │
│  └───────┘  │         │  └───────┘  │         │  └───────┘  │
│      ▲      │         │      ▲      │         │      ▲      │
│      │      │         │      │      │         │      │      │
│  ┌───┴────┐ │         │  ┌───┴────┐ │         │  ┌───┴────┐ │
│  │ PubSub │ │◄───────►│  │ PubSub │ │◄───────►│  │ PubSub │ │
│  └────────┘ │         │  └────────┘ │         │  └────────┘ │
└─────────────┘         └─────────────┘         └─────────────┘
       │                       │                       │
       └───────────────────────┴───────────────────────┘
                    Phoenix.PubSub
              (Automatic broadcast via Erlang)
```

## 🔄 How It Works

### 1. Local Cache (ETS)
Each node maintains its own local ETS table for ultra-fast access:
- **Read**: ~1µs (microsecond)
- **Write**: ~2µs
- **Zero network latency**

### 2. Synchronization via PubSub
When cache is invalidated, an event is broadcast to all nodes:

```elixir
# Node 1: Creates new product
Products.create(%{code: "NEW1", name: "New Product", price: 10.0})
# ↓
# Invalidates local cache
ProductsCache.invalidate("NEW1")
# ↓
# Broadcasts to all nodes
Phoenix.PubSub.broadcast(Kantox.PubSub, "cache:invalidate", {:cache_invalidate, :product_NEW1})
```

```elixir
# Node 2 and Node 3: Receive the broadcast
handle_info({:cache_invalidate, :product_NEW1}, state)
# ↓
# Remove entry from local cache
delete_local(:product_NEW1)
# ↓
# Next request reloads from database
```

## 🎯 Synchronization Events

### `:cache_invalidate` - Invalidates specific key
```elixir
{:cache_invalidate, key}
```

### `:cache_clear` - Clears all cache
```elixir
{:cache_clear}
```

## 📊 Guarantees and Trade-offs

### ✅ Guarantees

1. **Eventual Consistency**: All nodes will eventually have the same state
2. **No Stale Data**: Outdated cache is removed in <10ms (network latency)
3. **High Availability**: If one node fails, others continue working

### ⚠️ Trade-offs

1. **Not Strong Consistency**: There's a ~10ms window where nodes may have different data
2. **Network Dependency**: Requires functional network between nodes
3. **Cache Miss Storm**: If all nodes invalidate simultaneously, all will query the database

## 🚀 Cluster Deployment

### Network Configuration (libcluster)

Add to `mix.exs`:
```elixir
{:libcluster, "~> 3.3"}
```

Configure in `config/prod.exs`:
```elixir
config :libcluster,
  topologies: [
    k8s_example: [
      strategy: Cluster.Strategy.Kubernetes,
      config: [
        mode: :dns,
        kubernetes_node_basename: "kantox",
        kubernetes_selector: "app=kantox",
        polling_interval: 10_000
      ]
    ]
  ]
```

### Verify Cluster

```elixir
# In IEx on any node
Node.list()
# => [:"kantox@node2.example.com", :"kantox@node3.example.com"]

# Check if PubSub is working
Phoenix.PubSub.node_name(Kantox.PubSub)
# => :"kantox@node1.example.com"
```

## 🔍 Monitoring

### Synchronization Logs

```elixir
# When invalidation is received
[debug] Cache invalidation received for key: :product_GR1

# When broadcast is sent
[info] Created product GR1 and invalidated cache
```

### Recommended Metrics

1. **Cache Hit Rate** per node
2. **Invalidation Events** received/sent
3. **PubSub Latency** between nodes
4. **Cache Size** per node

## 🧪 Testing in Development

### Start multiple nodes locally

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
```

## 🔧 Troubleshooting

### Problem: Nodes don't connect
```bash
# Check firewall
sudo ufw allow 4369  # EPMD
sudo ufw allow 9000:9999/tcp  # Erlang distribution

# Check DNS
ping node2.example.com
```

### Problem: Cache doesn't synchronize
```elixir
# Check if PubSub is working
Phoenix.PubSub.subscribe(Kantox.PubSub, "cache:invalidate")
Phoenix.PubSub.broadcast(Kantox.PubSub, "cache:invalidate", {:test})
flush()  # Should show {:test}
```

### Problem: Cache miss storm
```elixir
# Implement cache warming
defmodule Kantox.Cache.Warmer do
  def warm_products do
    Task.start(fn ->
      Kantox.Cache.ProductsCache.refresh_all()
    end)
  end
end
```

## 📚 Additional Resources

- [Phoenix PubSub](https://hexdocs.pm/phoenix_pubsub/Phoenix.PubSub.html)
- [Erlang Distribution](https://www.erlang.org/doc/reference_manual/distributed)
- [libcluster](https://github.com/bitwalker/libcluster)
- [ETS Performance](https://www.erlang.org/doc/efficiency_guide/tables)
