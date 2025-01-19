to: "config/deploy.yml"
skip_exists: true
message: "Deploy file generated successfully."
---

# Name of your application. Used to uniquely configure containers.
service: {{pkg_name}}

# Name of the container image.
image: docker_username/{{pkg_name}}

# Deploy to these servers.
servers:
  web:
    - server_ip_address
  # job:
  #   hosts:
  #     - 192.168.0.1
  #   cmd: bin/jobs

# Enable SSL auto certification via Let's Encrypt and allow for multiple apps on a single web server.
# Remove this section when using multiple web servers and ensure you terminate SSL at your load balancer.
#
# Note: If using Cloudflare, set encryption mode in SSL/TLS setting to "Full" to enable CF-to-app encryption.
proxy:
  ssl: true
  host: domain_name
  # Proxy connects to your container on port 80 by default.
  app_port: 5150
  healthcheck:
    interval: 3
    path: /_health
    timeout: 3

# Credentials for your image host.
registry:
  # Specify the registry server, if you're not using Docker Hub
  # server: registry.digitalocean.com / ghcr.io / ...
  username: docker_username

  # Always use an access token rather than real password (pulled from .kamal/secrets).
  password:
    - KAMAL_REGISTRY_PASSWORD

# Configure builder setup.
builder:
  arch: amd64
  # Pass in additional build args needed for your Dockerfile.
  # args:

# Inject ENV variables into containers (secrets come from .kamal/secrets).
#
# env:
#   clear:
#     DB_HOST: 192.168.0.2
#   secret:
#     - RAILS_MASTER_KEY
{% if postgres or background_queue -%}
env:
  clear:
{% endif -%}
  {% if postgres -%}
    POSTGRES_HOST: kamal-loco-db
    DATABASE_URL: "postgresql://loco:loco@kamal-loco-db:5432/kamal_loco_production"
  {%- endif %}
  {% if background_queue -%}
    REDIS_URL: "redis://kamal-loco-redis"
  {%- endif %}
  {% if postgres -%}
  secret:
    - POSTGRES_PASSWORD
  {%- endif %}
# Aliases are triggered with "bin/kamal <alias>". You can overwrite arguments on invocation:
# "bin/kamal logs -r job" will tail logs from the first server in the job section.
#
# aliases:
#   shell: app exec --interactive --reuse "bash"

# Use a different ssh user than root
#
# ssh:
#   user: app

# Use a persistent storage volume.
#
# volumes:
#   - "app_storage:/app/storage"
{% if sqlite -%}
# Use a persistent database volume.
volumes:
# /var/lib/docker/volumes/data/_data
  - "data:/usr/app"
{% endif -%}
# Bridge fingerprinted assets, like JS and CSS, between versions to avoid
# hitting 404 on in-flight requests. Combines all files from new and old
# version inside the asset_path.
#
# asset_path: /app/public/assets

# Configure rolling deploys by setting a wait time between batches of restarts.
#
# boot:
#   limit: 10 # Can also specify as a percentage of total hosts, such as "25%"
#   wait: 2

# Use accessory services (secrets come from .kamal/secrets).
#
# accessories:
#   db:
#     image: mysql:8.0
#     host: 192.168.0.2
#     port: 3306
#     env:
#       clear:
#         MYSQL_ROOT_HOST: '%'
#       secret:
#         - MYSQL_ROOT_PASSWORD
#     files:
#       - config/mysql/production.cnf:/etc/mysql/my.cnf
#       - db/production.sql:/docker-entrypoint-initdb.d/setup.sql
#     directories:
#       - data:/var/lib/mysql
#   redis:
#     image: valkey/valkey:8
#     host: 192.168.0.2
#     port: 6379
#     directories:
#       - data:/data
{% if postgres or background_queue -%}
accessories:
{% endif -%}
  {% if postgres -%}
  db:
    image: postgres:16
    host: server_ip_address
    port: "127.0.0.1:5432:5432"
    env:
      clear:
        POSTGRES_USER: loco
        POSTGRES_DB: kamal_loco_production
      secret:
        - POSTGRES_PASSWORD
    directories:
      - data:/var/lib/postgresql/data
  {% endif -%}
  {% if background_queue -%}
  redis:
    image: valkey/valkey:8
    host: server_ip_address
    port: "127.0.0.1:6379:6379"
    directories:
      - data:/data
  {% endif -%}