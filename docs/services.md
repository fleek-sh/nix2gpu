# // services & runtime //

managing long-running processes inside `nix2gpu` containers.

______________________________________________________________________

## // overview //

`nix2gpu` uses [process-compose](https://github.com/F1bonacc1/process-compose) and [services-flake](https://github.com/juspay/services-flake) to manage services inside containers.

**Why not systemd?**

- Containers don't need full init systems
- Better Docker integration and log handling
- Simpler dependency management
- JSON/YAML configuration instead of unit files

______________________________________________________________________

## // enabling services generation //

To enable generation and spawning of services from inside your `nix2gpu` container,
add the following to your `flake.nix`:

```nix
inputs.services-flake.url = "github:juspay/services-flake";
inputs.process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
```

______________________________________________________________________

## // basic service configuration //

### **web server example**

```nix
{
  perSystem.nix2gpu."web-app" = {
    exposedPorts = {
      "22/tcp" = {};
      "8080/tcp" = {};
    };
    
    services.nginx."web-server" = {
      enable = true;
      virtualHosts."default" = {
        listen = [{
          addr = "0.0.0.0";
          port = 8080;
        }];
        locations."/" = {
          root = "/workspace/public";
        };
      };
    };
  };
}
```

### **database example**

```nix
{
  perSystem.nix2gpu."app-with-db" = {
    exposedPorts = {
      "22/tcp" = {};
      "8080/tcp" = {};
    };
    
    services = {
      postgresql."main-db" = {
        enable = true;
        listen_addresses = "*";
        port = 5432;
        authentication = pkgs.lib.mkOverride 10 ''
          local all all trust
          host all all 0.0.0.0/0 trust
        '';
      };
      
      nginx."api-server" = {
        enable = true;
        virtualHosts."api" = {
          listen = [{ addr = "0.0.0.0"; port = 8080; }];
          locations."/" = {
            proxyPass = "http://127.0.0.1:3000";
          };
        };
      };
    };
  };
}
```

______________________________________________________________________

## // available services //

`nix2gpu` supports all [services-flake](https://juspay.github.io/services-flake/) services:

### **databases**

```nix
services = {
  postgresql."db" = {
    enable = true;
    port = 5432;
  };
  
  redis."cache" = {
    enable = true;
    port = 6379;
  };
  
  mysql."db" = {
    enable = true;
    port = 3306;
  };
  
  clickhouse."analytics" = {
    enable = true;
    port = 9000;
  };
};
```

### **web servers**

```nix
services = {
  nginx."web" = {
    enable = true;
    # full nginx configuration available
  };
  
  apache-httpd."web" = {
    enable = true;
    # apache configuration
  };
  
  caddy."web" = {
    enable = true;
    # automatic HTTPS, reverse proxy
  };
};
```

### **monitoring & observability**

```nix
services = {
  prometheus."metrics" = {
    enable = true;
    port = 9090;
  };
  
  grafana."dashboard" = {
    enable = true;
    port = 3000;
  };
  
  jaeger."tracing" = {
    enable = true;
    port = 16686;
  };
};
```

### **message queues**

```nix
services = {
  rabbitmq."queue" = {
    enable = true;
    port = 5672;
  };
  
  apache-kafka."streaming" = {
    enable = true;
    port = 9092;
  };
};
```

______________________________________________________________________

## // custom services //

### **simple custom service**

```nix
{
  perSystem.nix2gpu."custom-app" = {
    services.custom."my-api" = {
      enable = true;
      
      # the command to run
      command = "${pkgs.python3}/bin/python /workspace/server.py";
      
      # working directory
      working_dir = "/workspace";
      
      # environment variables
      environment = {
        PORT = "8080";
        DATABASE_URL = "postgresql://localhost:5432/mydb";
      };
      
      # service dependencies
      depends_on = {
        postgresql = "ready";  # wait for postgres to be ready
      };
      
      # restart policy
      restart = "always";
      restart_delay = "5s";
      max_restarts = 10;
      
      # health check
      readiness_probe = {
        http_get = {
          path = "/health";
          port = 8080;
        };
        initial_delay_seconds = 10;
        period_seconds = 30;
      };
    };
  };
}
```

### **GPU-accelerated service**

```nix
{
  perSystem.nix2gpu."ml-inference" = {
    cudaPackages = pkgs.cudaPackages_12_8;
    
    services.custom."inference-api" = {
      enable = true;
      command = ''
        cd /workspace && \
        ${pkgs.python3}/bin/python -m uvicorn main:app \
          --host 0.0.0.0 \
          --port 8080
      '';
      
      environment = {
        CUDA_VISIBLE_DEVICES = "0";
        TORCH_CUDA_ARCH_LIST = "8.6;8.9;9.0";
        MODEL_PATH = "/workspace/models";
      };
      
      # ensure GPU is available before starting
      depends_on = {
        gpu-check = "completed";
      };
    };
    
    # GPU availability check service
    services.custom."gpu-check" = {
      enable = true;
      command = "nvidia-smi";
      restart = "no";  # run once then exit
    };
  };
}
```

______________________________________________________________________

## // service composition patterns //

### **microservices stack**

```nix
{
  perSystem.nix2gpu."microservices" = {
    exposedPorts = {
      "22/tcp" = {};
      "8080/tcp" = {};   # API gateway
      "5432/tcp" = {};   # PostgreSQL
      "6379/tcp" = {};   # Redis
    };
    
    services = {
      # database tier
      postgresql."userdb" = {
        enable = true;
        port = 5432;
        databases = ["users" "orders" "inventory"];
      };
      
      redis."session-store" = {
        enable = true;
        port = 6379;
      };
      
      # application tier  
      custom."user-service" = {
        enable = true;
        command = "user-service --port 3001";
        environment.DATABASE_URL = "postgresql://localhost:5432/users";
        depends_on.postgresql = "ready";
      };
      
      custom."order-service" = {
        enable = true;
        command = "order-service --port 3002";  
        environment.DATABASE_URL = "postgresql://localhost:5432/orders";
        depends_on.postgresql = "ready";
      };
      
      custom."inventory-service" = {
        enable = true;
        command = "inventory-service --port 3003";
        environment.DATABASE_URL = "postgresql://localhost:5432/inventory";  
        depends_on.postgresql = "ready";
      };
      
      # API gateway
      nginx."gateway" = {
        enable = true;
        virtualHosts."api" = {
          listen = [{ addr = "0.0.0.0"; port = 8080; }];
          locations = {
            "/users/" = {
              proxyPass = "http://127.0.0.1:3001/";
            };
            "/orders/" = {
              proxyPass = "http://127.0.0.1:3002/";
            };
            "/inventory/" = {
              proxyPass = "http://127.0.0.1:3003/";
            };
          };
        };
      };
    };
  };
}
```

### **ML training pipeline**

```nix
{
  perSystem.nix2gpu."ml-training" = {
    cudaPackages = pkgs.cudaPackages_12_8;
    
    services = {
      # experiment tracking
      custom."mlflow-server" = {
        enable = true;
        command = "mlflow server --host 0.0.0.0 --port 5000";
        environment.MLFLOW_BACKEND_STORE_URI = "postgresql://localhost:5432/mlflow";
      };
      
      # data processing
      custom."data-processor" = {
        enable = true;
        command = "python -m data_pipeline.processor";
        environment = {
          INPUT_DIR = "/workspace/raw_data";
          OUTPUT_DIR = "/workspace/processed_data";
        };
        restart = "no";  # run once then exit
      };
      
      # training job
      custom."model-trainer" = {
        enable = true;
        command = "python -m training.train --config /workspace/config.yaml";
        environment = {
          CUDA_VISIBLE_DEVICES = "0,1";
          DATA_DIR = "/workspace/processed_data";
          MODEL_DIR = "/workspace/models";
          MLFLOW_TRACKING_URI = "http://localhost:5000";
        };
        depends_on = {
          data-processor = "completed";
          mlflow-server = "ready";
        };
        restart = "no";
      };
      
      # model serving
      custom."model-server" = {
        enable = true;
        command = "python -m serving.server --port 8080";
        environment = {
          MODEL_PATH = "/workspace/models/best_model.pt";
          CUDA_VISIBLE_DEVICES = "0";
        };
        depends_on = {
          model-trainer = "completed";
        };
        readiness_probe = {
          http_get = {
            path = "/health";
            port = 8080;
          };
          initial_delay_seconds = 30;
          period_seconds = 10;
        };
      };
      
      # supporting services
      postgresql."mlflow-db" = {
        enable = true;
        port = 5432;
        databases = ["mlflow"];
      };
    };
  };
}
```

______________________________________________________________________

## // startup behavior //

### **no services defined**

If `services = {}`, the container starts an interactive bash session:

```bash
$ docker run -it my-container:latest
[nix2gpu] container initialization starting...
[nix2gpu] no services defined, starting interactive shell
root@container:/workspace# 
```

### **services defined**

With services configured, process-compose manages the service lifecycle:

```bash
$ docker run -d my-container:latest
[nix2gpu] container initialization starting...  
[nix2gpu] starting process-compose with 3 services
[nix2gpu] postgresql: starting
[nix2gpu] redis: starting  
[nix2gpu] nginx: waiting for dependencies
[nix2gpu] postgresql: ready
[nix2gpu] nginx: starting
[nix2gpu] all services healthy
```

### **mixed mode: services + shell**

For debugging, you can override the entrypoint:

```bash
$ docker run -it --entrypoint bash my-container:latest
root@container:/workspace# process-compose up &
root@container:/workspace# # services running in background
```

______________________________________________________________________

## // process management //

### **dependency ordering**

Services start in dependency order:

```nix
services = {
  postgresql."db" = {
    enable = true;
    # starts first (no dependencies)
  };
  
  custom."migrator" = {
    enable = true;
    command = "run-migrations";
    depends_on.postgresql = "ready";  # waits for postgres
    restart = "no";  # run once
  };
  
  custom."api" = {
    enable = true;
    command = "start-api-server";
    depends_on.migrator = "completed";  # waits for migrations
  };
};
```

### **restart policies**

```nix
services.custom."resilient-service" = {
  enable = true;
  command = "my-service";
  
  # restart configuration
  restart = "always";           # always restart on exit
  restart_delay = "10s";        # wait between restarts  
  max_restarts = 5;             # give up after 5 failures
  restart_delay_backoff = 2;    # exponential backoff multiplier
};
```

### **health monitoring**

```nix
services.custom."monitored-service" = {
  enable = true;
  command = "web-server --port 8080";
  
  # readiness check (when is service ready?)
  readiness_probe = {
    http_get = {
      path = "/ready";
      port = 8080;
    };
    initial_delay_seconds = 5;
    period_seconds = 10;
    timeout_seconds = 3;
    failure_threshold = 3;
  };
  
  # liveness check (is service still alive?)  
  liveness_probe = {
    http_get = {
      path = "/health";
      port = 8080;
    };
    initial_delay_seconds = 30;
    period_seconds = 30;
    timeout_seconds = 5;
    failure_threshold = 2;
  };
};
```

______________________________________________________________________

## // logging & debugging //

### **log aggregation**

All service logs go to stdout for `docker logs`:

```bash
$ docker logs my-container
[postgresql] 2024-11-30 10:00:01 UTC LOG:  database system is ready
[redis] 2024-11-30 10:00:02 UTC Ready to accept connections
[nginx] 2024-11-30 10:00:03 UTC nginx: configuration ok
[my-api] 2024-11-30 10:00:04 UTC Starting server on port 8080
```

### **individual service logs**

```bash
$ docker exec my-container process-compose logs postgresql
$ docker exec my-container process-compose logs --follow my-api
```

### **debugging failed services**

```bash
# check service status
$ docker exec my-container process-compose status

# restart specific service
$ docker exec my-container process-compose restart my-api

# check process-compose configuration
$ docker exec my-container cat /tmp/process-compose.yaml
```

### **interactive debugging**

```bash
# start container with bash instead of process-compose
$ docker run -it --entrypoint bash my-container:latest

# manually start services for debugging
root@container:/workspace# process-compose up --dry-run  # show config
root@container:/workspace# process-compose up postgresql  # start only postgres
root@container:/workspace# process-compose up  # start all services
```

______________________________________________________________________

## // service scaling patterns //

### **horizontal scaling**

Run multiple instances of the same service:

```nix
services = {
  custom."worker-1" = {
    enable = true;
    command = "worker --instance 1 --port 8001";
  };
  
  custom."worker-2" = {
    enable = true; 
    command = "worker --instance 2 --port 8002";
  };
  
  nginx."load-balancer" = {
    enable = true;
    httpConfig = ''
      upstream workers {
        server 127.0.0.1:8001;
        server 127.0.0.1:8002;
      }
      
      server {
        listen 8080;
        location / {
          proxy_pass http://workers;
        }
      }
    '';
  };
};
```

### **resource management**

```nix
services.custom."memory-intensive" = {
  enable = true;
  command = "big-ml-model --memory-limit 8G";
  
  environment = {
    # limit CPU cores
    GOMAXPROCS = "4";
    
    # limit memory
    GOMEMLIMIT = "8GiB";
    
    # GPU allocation
    CUDA_VISIBLE_DEVICES = "0";
  };
};
```

______________________________________________________________________

## // integration with external systems //

### **connecting to external databases**

```nix
services.custom."app" = {
  enable = true;
  command = "my-app";
  environment = {
    # external postgres via tailscale
    DATABASE_URL = "postgresql://db.tailnet.local:5432/myapp";
    
    # external redis via public endpoint
    REDIS_URL = "rediss://my-redis.aws.com:6380";
  };
};
```

### **service discovery via tailscale**

```nix
{
  perSystem.nix2gpu."api-server" = {
    tailscale = {
      enable = true;
      hostname = "api-server";
      tags = ["tag:api"];
    };
    
    services.custom."api" = {
      enable = true;
      command = "api-server --advertise api-server.tailnet.local";
    };
  };
}
```

Other containers can connect to `api-server.tailnet.local` directly.

______________________________________________________________________

## // best practices //

### **service design**

1. **Stateless services**: Store state in databases or mounted volumes
1. **Health checks**: Always implement `/health` endpoints
1. **Graceful shutdown**: Handle SIGTERM properly
1. **Environment configuration**: Use env vars for configuration
1. **Dependency injection**: Use `depends_on` for service ordering

### **resource optimization**

1. **Shared databases**: Multiple services can share one postgres instance
1. **Connection pooling**: Use pgbouncer for database connections
1. **Caching layers**: Redis for session storage and caching
1. **Load balancing**: Nginx for request distribution

### **security**

1. **Least privilege**: Services run as non-root when possible
1. **Network isolation**: Services communicate via localhost only
1. **Secret management**: Use mounted secrets, not env vars
1. **Input validation**: Sanitize all external inputs

### **monitoring**

1. **Structured logging**: JSON logs for machine parsing
1. **Metrics exposure**: Prometheus-compatible endpoints
1. **Distributed tracing**: Use correlation IDs across services
1. **Error tracking**: Centralized error reporting
