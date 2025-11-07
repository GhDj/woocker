# Quick Start Guide

Get your WordPress + WooCommerce development environment running in 5 minutes!

## One-Command Setup

```bash
./setup.sh
```

The script automatically:
- ✅ Creates `.env` configuration file
- ✅ Generates SSL certificates (HTTPS support)
- ✅ Builds Docker containers with your chosen PHP version
- ✅ Installs WordPress
- ✅ Installs WooCommerce
- ✅ Activates Storefront theme
- ✅ Creates all product types (Simple, Variable, Grouped, External, Virtual, Downloadable)
- ✅ Creates 2 sample customers
- ✅ Configures VS Code for debugging

## Access Your Site

- **Frontend**: https://wooco.localhost:8443
- **Admin**: https://wooco.localhost:8443/wp-admin
- **PHPMyAdmin**: http://localhost:8080

**Login**: admin / admin123

**Note:**
- HTTPS is enabled by default with auto-generated SSL certificates
- If you see a browser warning (self-signed cert), click "Advanced" → "Proceed"
- Install [mkcert](https://github.com/FiloSottile/mkcert) for trusted certificates (no warnings)
- You can change the hostname in `.env` file

## Add Your Plugin

```bash
# Create plugin directory
mkdir -p wordpress/wp-content/plugins/my-plugin

# Create main plugin file
cat > wordpress/wp-content/plugins/my-plugin/my-plugin.php <<EOF
<?php
/**
 * Plugin Name: My Plugin
 * Description: My awesome plugin
 * Version: 1.0.0
 */

add_action('init', function() {
    // Your code here
});
EOF
```

Your plugin is immediately available in WordPress! Go to Plugins → Installed Plugins to activate it.

## Start Developing

The entire `./wordpress/` directory is synced live with the container.

Edit locally → Save → Refresh browser → See changes!

**You have full access to:**
- WordPress core files
- All plugins (WooCommerce, your custom plugins)
- Themes
- Uploads
- Everything!

## Common Commands

```bash
# Stop containers
docker-compose down

# Start containers
docker-compose up -d

# View logs
docker-compose logs -f wordpress

# Run WP-CLI command
docker-compose exec wordpress wp plugin list

# Access container shell
docker-compose exec wordpress bash
```

## Debug with Xdebug

### VS Code
1. Install "PHP Debug" extension
2. Press `F5` to start debugging
3. Add breakpoints in your plugin code
4. Visit: `https://wooco.localhost:8443/?XDEBUG_TRIGGER=1` (or your configured hostname)

### PhpStorm
1. Settings → PHP → Debug → Port: `9003`
2. Click "Start Listening for PHP Debug Connections"
3. Visit: `https://wooco.localhost:8443/?XDEBUG_TRIGGER=1` (or your configured hostname)

## Sample Data

The environment includes all WooCommerce product types:

| Type | Example |
|------|---------|
| Simple | Classic T-Shirt |
| Variable | Premium T-Shirt (sizes/colors) |
| Grouped | Outfit Bundle |
| External | Designer Jacket |
| Virtual | Online Course |
| Downloadable | eBook |

**Sample Customers:**
- john.doe@example.com / customer123
- jane.smith@example.com / customer123

**Quick Links:**
- Products: https://wooco.localhost:8443/wp-admin/edit.php?post_type=product
- Customers: https://wooco.localhost:8443/wp-admin/admin.php?page=wc-admin&path=/customers

## Testing

Tests should be in your plugin directory:

```bash
# Add PHPUnit to your plugin
cd wordpress/wp-content/plugins/my-plugin
docker-compose exec wordpress composer require --dev phpunit/phpunit wp-phpunit/wp-phpunit

# Run your plugin tests
docker-compose exec wordpress bash -c "cd /var/www/html/wp-content/plugins/my-plugin && vendor/bin/phpunit"
```

See the full [README.md](README.md) for complete testing setup instructions.

## Troubleshooting

**Port 8000 in use?**
```bash
# Edit .env and change WORDPRESS_PORT=8001
nano .env
docker-compose down
docker-compose up -d
```

**Site not loading?**
```bash
# Check containers
docker-compose ps

# View logs
docker-compose logs wordpress
```

**Start fresh?**
```bash
docker-compose down -v
rm .env
./setup.sh
```

## Customization

Edit `.env` to change:
- **PHP version** (7.4, 8.0, 8.1, 8.2, 8.3)
- **WordPress version**
- **WooCommerce version**
- **Custom hostname** (e.g., myshop.localhost)
- **Port numbers**
- **Admin credentials**
- **Database credentials**

After editing `.env`:
```bash
docker-compose down
docker-compose build --no-cache  # Only if changing PHP version
docker-compose up -d
```

## What's Included

- **PHP** Configurable (7.4, 8.0, 8.1, 8.2, 8.3)
- **WordPress** 6.4 (configurable)
- **WooCommerce** 8.5.2 (configurable)
- **Storefront** theme
- **MySQL** 8.0
- **Xdebug** 3.2
- **WP-CLI** latest
- **Composer** latest
- **PHPMyAdmin** latest

## File Structure

```
wordpress/              → Full WordPress installation (synced with container)
  └── wp-content/
      └── plugins/     → Add your plugins here
scripts/               → Setup and utility scripts
tests/                 → Test files
.env                   → Environment configuration
docker-compose.yml     → Docker services
setup.sh               → Automated setup
```

## Next Steps

1. Create your plugin in `./wordpress/wp-content/plugins/my-plugin/`
2. Write your code
3. Test in WordPress
4. Debug with Xdebug
5. Write unit tests
6. Deploy!

**Pro tip:** Track your plugin in Git by adding this to `.gitignore`:
```gitignore
!wordpress/wp-content/plugins/my-plugin/
```

## Need Help?

Check the full [README.md](README.md) for detailed documentation.

Happy coding! 🚀
