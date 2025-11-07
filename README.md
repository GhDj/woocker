# WordPress + WooCommerce Development Environment

A complete Dockerized development environment for WordPress and WooCommerce plugin development, ready for testing and debugging.

## Features

- ✅ WordPress with WooCommerce pre-installed
- ✅ Storefront theme (WooCommerce's official theme)
- ✅ Sample products of all WooCommerce product types
- ✅ Xdebug configured for step-by-step debugging
- ✅ PHPUnit ready for unit and integration testing
- ✅ MySQL database with PHPMyAdmin
- ✅ Fully configurable via `.env` file
- ✅ Local plugin development with live sync

## Prerequisites

- Docker Desktop installed and running
- Docker Compose v2.0+
- Git
- 4GB+ RAM available for Docker

## Quick Start

```bash
# Run the automated setup
./setup.sh
```

That's it! The setup script will:
- Create environment configuration
- Build Docker containers with your chosen PHP version
- Install WordPress
- Install and configure WooCommerce
- Install Storefront theme
- Create sample products (all product types)
- Create sample customers
- Configure Xdebug for debugging

## Access Your Site

After setup completes:

- **Frontend**: https://wooco.localhost:8443 (or your configured hostname)
- **Admin**: https://wooco.localhost:8443/wp-admin
- **PHPMyAdmin**: http://localhost:8080

**Default Login:**
- Username: `admin`
- Password: `admin123`

**Note:**
- `*.localhost` domains work without editing `/etc/hosts` on most systems
- HTTPS is enabled by default with auto-generated SSL certificates
- If using mkcert, you won't see any browser warnings
- If using self-signed certs, click "Advanced" and "Proceed" on the browser warning

## Project Structure

```
woocker/
├── setup.sh                  # Automated setup script
├── docker-compose.yml        # Docker services configuration
├── Dockerfile                # WordPress container with Xdebug
├── .env                      # Environment variables (create from .env.example)
├── .env.example              # Environment template
├── .gitignore                # Git ignore rules
├── wordpress/                # Full WordPress installation (mounted)
│   ├── wp-admin/            # WordPress admin
│   ├── wp-includes/         # WordPress core
│   ├── wp-content/
│   │   ├── plugins/        # Your custom plugins go here
│   │   │   └── your-plugin/
│   │   │       ├── your-plugin.php
│   │   │       ├── tests/   # Plugin-specific tests
│   │   │       └── phpunit.xml
│   │   ├── themes/         # WordPress themes
│   │   └── uploads/        # Media uploads
│   └── wp-config.php       # WordPress configuration
└── scripts/
    └── setup-sample-data.sh
```

## Plugin Development

### Adding Your Plugin

The entire WordPress installation is in the `./wordpress/` directory and is synchronized with the Docker container in real-time.

1. Create your plugin directory:
   ```bash
   mkdir -p wordpress/wp-content/plugins/my-plugin
   ```

2. Create your main plugin file:
   ```bash
   cat > wordpress/wp-content/plugins/my-plugin/my-plugin.php <<EOF
   <?php
   /**
    * Plugin Name: My Plugin
    * Description: My awesome WooCommerce plugin
    * Version: 1.0.0
    */

   add_action('init', function() {
       // Your code here
   });
   EOF
   ```

3. The plugin is immediately available in WordPress admin → Plugins!

### File Synchronization

The entire `./wordpress/` directory is mounted to `/var/www/html` in the container.

**This means:**
- Edit files locally with your favorite IDE
- Changes are instantly reflected in WordPress
- No need to rebuild Docker containers
- Full access to all WordPress files

### Tracking Your Plugin in Git

By default, the entire `wordpress/` directory is gitignored. To track your custom plugin:

Add this to `.gitignore`:
```gitignore
!wordpress/wp-content/plugins/my-plugin/
```

This allows you to version control your plugin while ignoring WordPress core and other plugins.

## Configuration

### Environment Variables (.env)

Customize your environment by editing `.env`:

```env
# PHP version (7.4, 8.0, 8.1, 8.2, 8.3)
PHP_VERSION=8.1

# WordPress version
WORDPRESS_VERSION=6.4

# WooCommerce version
WOOCOMMERCE_VERSION=8.5.2

# Database credentials
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=wordpress
MYSQL_USER=wordpress
MYSQL_PASSWORD=wordpress

# Custom hostname (*.localhost works without /etc/hosts changes)
WORDPRESS_HOSTNAME=wooco.localhost
WORDPRESS_PORT=8000
WP_SITE_URL=http://wooco.localhost:8000

# Admin credentials
WP_ADMIN_USER=admin
WP_ADMIN_PASSWORD=admin123
WP_ADMIN_EMAIL=admin@example.local

# Xdebug settings
XDEBUG_MODE=debug
XDEBUG_CLIENT_HOST=host.docker.internal
XDEBUG_CLIENT_PORT=9003
XDEBUG_IDE_KEY=PHPSTORM
```

### Changing PHP Version

1. Edit `.env` and change `PHP_VERSION` (e.g., `PHP_VERSION=8.2`)
2. Rebuild and restart:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose up -d
   ```

### Custom Hostname

Use any hostname you want:
- `wooco.localhost` (recommended - works without /etc/hosts)
- `myshop.local` (requires /etc/hosts entry: `127.0.0.1 myshop.local`)
- `dev.example.com` (requires DNS or /etc/hosts)

After changing hostname:
```bash
docker-compose down
docker-compose up -d
wp search-replace 'old-url.com' 'new-url.com' --allow-root
```

### SSL/HTTPS Configuration

HTTPS is enabled by default for secure local development. The setup script automatically generates SSL certificates.

**Using mkcert (Recommended - No Browser Warnings):**

```bash
# Install mkcert (one-time setup)
# macOS
brew install mkcert
brew install nss # for Firefox

# Linux
apt install mkcert # or your package manager

# Windows
choco install mkcert

# The setup.sh script will automatically use mkcert if available
```

**Using Self-Signed Certificates (Fallback):**

If mkcert is not installed, the setup script automatically generates self-signed certificates. You'll see a browser security warning - this is normal. Click "Advanced" and "Proceed" to continue.

**Manual Certificate Regeneration:**

```bash
# Regenerate SSL certificates for a specific hostname
./scripts/generate-ssl-certs.sh your-hostname.localhost

# Restart containers to apply changes
docker-compose restart wordpress
```

**Ports:**
- HTTPS (SSL): `8443` (configurable via `WORDPRESS_SSL_PORT` in `.env`)
- HTTP: `8000` (auto-redirects to HTTPS)

## Development Tools

### WP-CLI

Run WordPress commands directly:

```bash
# List all plugins
docker-compose exec wordpress wp plugin list

# List all users
docker-compose exec wordpress wp user list

# Create a new post
docker-compose exec wordpress wp post create --post_title="Hello" --post_status=publish

# Export database
docker-compose exec wordpress wp db export backup.sql

# Clear cache
docker-compose exec wordpress wp cache flush
```

### Xdebug Setup

#### VS Code

1. Install the "PHP Debug" extension
2. A `.vscode/launch.json` file is created automatically
3. Press `F5` to start listening for Xdebug
4. Add breakpoints in your plugin code
5. Visit your site with `?XDEBUG_TRIGGER=1` in the URL

Example: `https://wooco.localhost:8443/?XDEBUG_TRIGGER=1` (or your configured hostname)

#### PhpStorm

1. Go to Settings → PHP → Debug
2. Set Xdebug port to `9003`
3. Configure path mappings:
   - `./wordpress` → `/var/www/html`
4. Click "Start Listening for PHP Debug Connections"
5. Visit your site with `?XDEBUG_TRIGGER=1` in the URL

## Testing

The environment is ready for testing, but tests should be within each plugin.

### Setting Up Plugin Tests

1. **Install test dependencies in your plugin:**
   ```bash
   cd wordpress/wp-content/plugins/your-plugin
   composer require --dev phpunit/phpunit wp-phpunit/wp-phpunit
   ```

2. **Create `phpunit.xml` in your plugin directory:**
   ```xml
   <?xml version="1.0"?>
   <phpunit bootstrap="tests/bootstrap.php">
       <testsuites>
           <testsuite name="Plugin Tests">
               <directory>./tests</directory>
           </testsuite>
       </testsuites>
   </phpunit>
   ```

3. **Create `tests/bootstrap.php`:**
   ```php
   <?php
   // Load WordPress test environment
   require_once '/tmp/wordpress-tests-lib/includes/bootstrap.php';

   // Load your plugin
   require_once dirname(__DIR__) . '/your-plugin.php';
   ```

4. **Run tests:**
   ```bash
   # From host
   docker-compose exec wordpress bash -c "cd /var/www/html/wp-content/plugins/your-plugin && vendor/bin/phpunit"

   # Or from inside container
   docker-compose exec wordpress bash
   cd /var/www/html/wp-content/plugins/your-plugin
   vendor/bin/phpunit
   ```

## Sample Data

The environment includes these WooCommerce product types:

- **Simple Product**: Classic cotton t-shirt
- **Variable Product**: Premium t-shirt with size and color variations
- **Grouped Product**: Complete outfit bundle
- **External/Affiliate Product**: Designer jacket (external link)
- **Virtual Product**: Online coding course
- **Downloadable Product**: WordPress development eBook
- **Additional Products**: Jeans, wallet, shoes, sunglasses

**Sample Customers:**
- John Doe (john.doe@example.com / customer123)
- Jane Smith (jane.smith@example.com / customer123)

View products: https://wooco.localhost:8443/wp-admin/edit.php?post_type=product
View customers: https://wooco.localhost:8443/wp-admin/admin.php?page=wc-admin&path=/customers

### Adding More Sample Data

```bash
# Import WooCommerce sample data
docker-compose exec wordpress wp plugin install wordpress-importer --activate
docker-compose exec wordpress wp import wp-content/plugins/woocommerce/sample-data/sample_products.xml --authors=create
```

## Common Commands

```bash
# Start environment
docker-compose up -d

# Stop environment
docker-compose down

# Stop and remove all data (fresh start)
docker-compose down -v

# View logs
docker-compose logs -f wordpress

# Access WordPress container shell
docker-compose exec wordpress bash

# Rebuild containers
docker-compose up -d --build

# Check container status
docker-compose ps
```

## Troubleshooting

### Port 8000 already in use

Edit `.env` and change `WORDPRESS_PORT` to another port (e.g., 8001):
```env
WORDPRESS_PORT=8001
```

Then restart:
```bash
docker-compose down
docker-compose up -d
```

### Can't access the site

```bash
# Check if containers are running
docker-compose ps

# View WordPress logs
docker-compose logs wordpress

# Restart containers
docker-compose restart
```

### Database connection error

```bash
# Restart database
docker-compose restart db

# Check database health
docker-compose exec db mysqladmin ping -h localhost -u root -p
```

### Xdebug not working

1. Verify Xdebug is installed:
   ```bash
   docker-compose exec wordpress php -v
   ```
   You should see "with Xdebug" in the output.

2. Check Xdebug configuration:
   ```bash
   docker-compose exec wordpress php -i | grep xdebug
   ```

3. For Linux users, change `XDEBUG_CLIENT_HOST` in `.env`:
   ```env
   XDEBUG_CLIENT_HOST=172.17.0.1
   ```

### Permission issues

```bash
# Fix file permissions
docker-compose exec wordpress chown -R www-data:www-data /var/www/html/wp-content
```

### Start fresh

```bash
# Remove everything and start over
docker-compose down -v
rm .env
./setup.sh
```

## Docker Services

### WordPress Container
- **Configurable PHP version** (7.4, 8.0, 8.1, 8.2, 8.3)
- Apache web server
- Xdebug 3.2 pre-installed
- WP-CLI pre-installed
- Composer pre-installed
- Port 8000 (configurable)

### MySQL Container
- MySQL 8.0
- Port 3306 (internal)
- Persistent data volume
- Automatic health checks

### PHPMyAdmin Container
- Web-based database management
- Port 8080
- Access: http://localhost:8080

## Best Practices

1. **Version Control**: Commit your plugin code, not WordPress core
2. **Environment Variables**: Never commit `.env` file
3. **Database Backups**: Export database regularly during development
   ```bash
   docker-compose exec wordpress wp db export backup-$(date +%Y%m%d).sql
   ```
4. **Keep Updated**: Update WordPress, WooCommerce, and PHP versions regularly
5. **Use WP-CLI**: Automate repetitive tasks with WP-CLI scripts
6. **Write Tests**: Maintain good test coverage for your plugins

## Additional Resources

- [WordPress Developer Resources](https://developer.wordpress.org/)
- [WooCommerce Developer Documentation](https://woocommerce.com/documentation/plugins/woocommerce/)
- [WP-CLI Documentation](https://wp-cli.org/)
- [PHPUnit Documentation](https://phpunit.de/documentation.html)
- [Xdebug Documentation](https://xdebug.org/docs/)

## License

MIT License - Feel free to use this for your projects!

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
