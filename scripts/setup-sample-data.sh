#!/bin/bash

# Exit on error, but we'll handle variation creation separately
set -e

echo ""
echo "=========================================="
echo "WooCommerce Sample Data Setup"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}→${NC} $1"
}

# Check if WooCommerce is active
if ! wp plugin is-active woocommerce --allow-root 2>/dev/null; then
    echo "❌ Error: WooCommerce is not active!"
    echo "Please activate WooCommerce first."
    exit 1
fi

print_success "WooCommerce is active"
echo ""

# Configure WooCommerce Store Settings
print_info "Configuring WooCommerce store settings..."

wp option update woocommerce_store_address "123 Main Street" --allow-root
wp option update woocommerce_store_address_2 "Suite 100" --allow-root
wp option update woocommerce_store_city "San Francisco" --allow-root
wp option update woocommerce_default_country "US:CA" --allow-root
wp option update woocommerce_store_postcode "94102" --allow-root
wp option update woocommerce_currency "USD" --allow-root
wp option update woocommerce_product_type "both" --allow-root
wp option update woocommerce_allow_tracking "no" --allow-root
wp option update woocommerce_onboarding_opt_in "no" --allow-root
wp option update woocommerce_calc_taxes "no" --allow-root

print_success "Store settings configured"
echo ""

# Create Product Categories
print_info "Creating product categories..."

CATEGORY_CLOTHING=$(wp wc product_cat create --name="Clothing" --slug="clothing" --user=1 --porcelain --allow-root)
CATEGORY_ACCESSORIES=$(wp wc product_cat create --name="Accessories" --slug="accessories" --user=1 --porcelain --allow-root)
CATEGORY_FOOTWEAR=$(wp wc product_cat create --name="Footwear" --slug="footwear" --user=1 --porcelain --allow-root)
CATEGORY_DIGITAL=$(wp wc product_cat create --name="Digital Products" --slug="digital" --user=1 --porcelain --allow-root)
CATEGORY_COURSES=$(wp wc product_cat create --name="Courses" --slug="courses" --user=1 --porcelain --allow-root)
CATEGORY_BUNDLES=$(wp wc product_cat create --name="Bundles" --slug="bundles" --user=1 --porcelain --allow-root)

print_success "Product categories created"
echo ""

# 1. Create Simple Product
print_info "[1/6] Creating Simple Product..."

SIMPLE_PRODUCT=$(wp wc product create \
  --name="Classic Cotton T-Shirt" \
  --type="simple" \
  --regular_price="24.99" \
  --description="A comfortable, classic cotton t-shirt perfect for everyday wear. Made from 100% premium cotton." \
  --short_description="Comfortable cotton t-shirt" \
  --sku="TSHIRT-SIMPLE-001" \
  --manage_stock=true \
  --stock_quantity=100 \
  --categories="[{\"id\":${CATEGORY_CLOTHING}}]" \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "Simple Product created (ID: $SIMPLE_PRODUCT)"
echo ""

# 2. Create Variable Product
print_info "[2/6] Creating Variable Product with variations..."

VARIABLE_PRODUCT=$(wp wc product create \
  --name="Premium T-Shirt" \
  --type="variable" \
  --description="Premium quality t-shirt available in multiple sizes and colors. Soft, durable, and stylish." \
  --short_description="Premium t-shirt with size and color options" \
  --sku="TSHIRT-VAR-001" \
  --categories="[{\"id\":${CATEGORY_CLOTHING}}]" \
  --user=1 \
  --porcelain \
  --allow-root)

# Create attributes for the variable product
wp wc product_attribute create \
  --name="Size" \
  --slug="size" \
  --type="select" \
  --order_by="menu_order" \
  --has_archives=false \
  --user=1 \
  --allow-root 2>/dev/null || true

wp wc product_attribute create \
  --name="Color" \
  --slug="color" \
  --type="select" \
  --order_by="menu_order" \
  --has_archives=false \
  --user=1 \
  --allow-root 2>/dev/null || true

# Add attributes to the variable product
wp wc product update $VARIABLE_PRODUCT \
  --attributes='[
    {"name":"Size","position":0,"visible":true,"variation":true,"options":["Small","Medium","Large","XL"]},
    {"name":"Color","position":1,"visible":true,"variation":true,"options":["Red","Blue","Green","Black"]}
  ]' \
  --user=1 \
  --allow-root

# Create variations
SIZES=("Small" "Medium" "Large" "XL")
COLORS=("Red" "Blue")

VARIATION_COUNT=0
VARIATION_SUCCESS=0
PRICES=("29.99" "31.99" "33.99" "35.99" "37.99" "39.99" "41.99" "43.99")

# Temporarily disable exit on error for variation creation
set +e

for SIZE in "${SIZES[@]}"; do
  for COLOR in "${COLORS[@]}"; do
    echo "  Creating variation: $SIZE / $COLOR (${PRICES[$VARIATION_COUNT]})..."
    RESULT=$(wp wc product_variation create $VARIABLE_PRODUCT \
      --regular_price="${PRICES[$VARIATION_COUNT]}" \
      --sku="VAR-${SIZE:0:1}-${COLOR:0:1}-001" \
      --manage_stock=true \
      --stock_quantity=50 \
      --attributes="[{\"name\":\"Size\",\"option\":\"$SIZE\"},{\"name\":\"Color\",\"option\":\"$COLOR\"}]" \
      --user=1 \
      --allow-root --porcelain 2>&1)

    if [[ $? -eq 0 ]]; then
      echo "    ✓ Created (ID: $RESULT)"
      ((VARIATION_SUCCESS++))
    else
      echo "    ✗ Failed: $RESULT"
    fi
    ((VARIATION_COUNT++))
  done
done

# Re-enable exit on error
set -e

print_success "Variable Product created with $VARIATION_SUCCESS/$VARIATION_COUNT variations (ID: $VARIABLE_PRODUCT)"
echo ""

# 3. Create Grouped Product
print_info "[3/6] Creating Grouped Product..."

GROUPED_PRODUCT=$(wp wc product create \
  --name="Complete Outfit Bundle" \
  --type="grouped" \
  --description="A complete outfit bundle including t-shirt, jeans, and accessories. Perfect for a complete look!" \
  --short_description="Complete outfit set" \
  --sku="BUNDLE-001" \
  --categories="[{\"id\":${CATEGORY_BUNDLES}}]" \
  --grouped_products="[${SIMPLE_PRODUCT}]" \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "Grouped Product created (ID: $GROUPED_PRODUCT)"
echo ""

# 4. Create External/Affiliate Product
print_info "[4/6] Creating External/Affiliate Product..."

EXTERNAL_PRODUCT=$(wp wc product create \
  --name="Designer Jacket (External)" \
  --type="external" \
  --regular_price="149.99" \
  --description="Premium designer jacket available from our partner store. High-quality materials and craftsmanship." \
  --short_description="Designer jacket from partner store" \
  --sku="EXT-JACKET-001" \
  --button_text="Buy from Partner Store" \
  --external_url="https://example.com/designer-jacket" \
  --categories="[{\"id\":${CATEGORY_CLOTHING}}]" \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "External/Affiliate Product created (ID: $EXTERNAL_PRODUCT)"
echo ""

# 5. Create Virtual Product
print_info "[5/6] Creating Virtual Product..."

VIRTUAL_PRODUCT=$(wp wc product create \
  --name="Online Coding Course" \
  --type="simple" \
  --regular_price="99.99" \
  --description="Comprehensive online coding course with lifetime access. Learn web development from scratch!" \
  --short_description="Learn coding from scratch" \
  --sku="COURSE-VIRTUAL-001" \
  --virtual=true \
  --categories="[{\"id\":${CATEGORY_COURSES}}]" \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "Virtual Product created (ID: $VIRTUAL_PRODUCT)"
echo ""

# 6. Create Downloadable Product
print_info "[6/6] Creating Downloadable Product..."

DOWNLOADABLE_PRODUCT=$(wp wc product create \
  --name="WordPress Development eBook" \
  --type="simple" \
  --regular_price="29.99" \
  --description="Complete guide to WordPress plugin development. Everything you need to know!" \
  --short_description="WordPress development guide" \
  --sku="EBOOK-DOWNLOAD-001" \
  --virtual=true \
  --downloadable=true \
  --download_limit=-1 \
  --download_expiry=-1 \
  --categories="[{\"id\":${CATEGORY_DIGITAL}}]" \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "Downloadable Product created (ID: $DOWNLOADABLE_PRODUCT)"
echo ""

# Create additional simple products
print_info "Creating additional simple products..."

echo "  Creating Denim Jeans..."
wp wc product create \
  --name="Denim Jeans" \
  --type="simple" \
  --regular_price="59.99" \
  --description="High quality denim jeans for your needs. Classic fit and durable." \
  --short_description="Premium denim jeans" \
  --sku="DENIM-JEANS-001" \
  --manage_stock=true \
  --stock_quantity=75 \
  --categories="[{\"id\":${CATEGORY_CLOTHING}}]" \
  --user=1 \
  --allow-root --porcelain > /dev/null && echo "    ✓ Created"

echo "  Creating Leather Wallet..."
wp wc product create \
  --name="Leather Wallet" \
  --type="simple" \
  --regular_price="24.99" \
  --description="High quality leather wallet for your needs. Genuine leather." \
  --short_description="Premium leather wallet" \
  --sku="LEATHER-WALLET-001" \
  --manage_stock=true \
  --stock_quantity=120 \
  --categories="[{\"id\":${CATEGORY_ACCESSORIES}}]" \
  --user=1 \
  --allow-root --porcelain > /dev/null && echo "    ✓ Created"

echo "  Creating Running Shoes..."
wp wc product create \
  --name="Running Shoes" \
  --type="simple" \
  --regular_price="89.99" \
  --description="High quality running shoes for your needs. Comfortable and durable." \
  --short_description="Premium running shoes" \
  --sku="RUNNING-SHOES-001" \
  --manage_stock=true \
  --stock_quantity=60 \
  --categories="[{\"id\":${CATEGORY_FOOTWEAR}}]" \
  --user=1 \
  --allow-root --porcelain > /dev/null && echo "    ✓ Created"

echo "  Creating Sunglasses..."
wp wc product create \
  --name="Sunglasses" \
  --type="simple" \
  --regular_price="39.99" \
  --description="High quality sunglasses for your needs. UV protection." \
  --short_description="Premium sunglasses" \
  --sku="SUNGLASSES-001" \
  --manage_stock=true \
  --stock_quantity=90 \
  --categories="[{\"id\":${CATEGORY_ACCESSORIES}}]" \
  --user=1 \
  --allow-root --porcelain > /dev/null && echo "    ✓ Created"

print_success "4 additional products created"
echo ""

# Create Customers
print_info "Creating sample customers..."

CUSTOMER1=$(wp wc customer create \
  --email="john.doe@example.com" \
  --first_name="John" \
  --last_name="Doe" \
  --username="johndoe" \
  --password="customer123" \
  --billing='{"first_name":"John","last_name":"Doe","company":"","address_1":"123 Main St","address_2":"Apt 4B","city":"New York","state":"NY","postcode":"10001","country":"US","email":"john.doe@example.com","phone":"555-1234"}' \
  --shipping='{"first_name":"John","last_name":"Doe","company":"","address_1":"123 Main St","address_2":"Apt 4B","city":"New York","state":"NY","postcode":"10001","country":"US"}' \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "Customer created: John Doe (ID: $CUSTOMER1)"

CUSTOMER2=$(wp wc customer create \
  --email="jane.smith@example.com" \
  --first_name="Jane" \
  --last_name="Smith" \
  --username="janesmith" \
  --password="customer123" \
  --billing='{"first_name":"Jane","last_name":"Smith","company":"Tech Corp","address_1":"456 Oak Avenue","address_2":"","city":"Los Angeles","state":"CA","postcode":"90001","country":"US","email":"jane.smith@example.com","phone":"555-5678"}' \
  --shipping='{"first_name":"Jane","last_name":"Smith","company":"Tech Corp","address_1":"456 Oak Avenue","address_2":"","city":"Los Angeles","state":"CA","postcode":"90001","country":"US"}' \
  --user=1 \
  --porcelain \
  --allow-root)

print_success "Customer created: Jane Smith (ID: $CUSTOMER2)"
echo ""

echo "=========================================="
echo "✅ Sample Data Setup Complete!"
echo "=========================================="
echo ""
echo "Summary:"
echo "  • 6 Core Product Types Created"
echo "  • 4 Additional Simple Products"
echo "  • $VARIATION_COUNT Product Variations"
echo "  • 6 Product Categories"
echo "  • 2 Sample Customers"
echo ""
echo "Customer Credentials:"
echo "  • john.doe@example.com / customer123"
echo "  • jane.smith@example.com / customer123"
echo ""
echo "View products: /wp-admin/edit.php?post_type=product"
echo "View customers: /wp-admin/admin.php?page=wc-admin&path=/customers"
echo ""
