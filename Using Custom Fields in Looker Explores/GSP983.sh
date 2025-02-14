#!/bin/bash


# Authenticate and get an access token
echo "Authenticating with Looker..."
ACCESS_TOKEN=$(curl -s -X POST "$LOOKER_BASE_URL/api/4.0/login" \
  -d "client_id=$LOOKER_CLIENT_ID&client_secret=$LOOKER_CLIENT_SECRET" \
  -H "Content-Type: application/json" | jq -r '.access_token')

if [ -z "$ACCESS_TOKEN" ]; then
  echo "Authentication failed! Please check your credentials."
  exit 1
fi
echo "Authentication successful!"

# Create a Custom Measure (Average Cost)
echo "Creating custom measure (Average Cost)..."
curl -s -X POST "$LOOKER_BASE_URL/api/4.0/queries/run/json" \
  -H "Authorization: token $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ecommerce_training",
    "view": "order_items",
    "fields": ["inventory_items.cost"],
    "filters": {},
    "pivots": [],
    "sorts": ["inventory_items.cost desc"],
    "limit": "500"
  }' | jq

# Create a Custom Grouping (State Groups)
echo "Creating custom grouping (State Groups)..."
curl -s -X POST "$LOOKER_BASE_URL/api/4.0/queries/run/json" \
  -H "Authorization: token $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ecommerce_training",
    "view": "users",
    "fields": ["state"],
    "filters": {
      "state": "Oregon,Idaho,Washington"
    }
  }' | jq

# Adding Filter to Custom Measure (Cost > 200)
echo "Applying filter (Average Cost > $200)..."
curl -s -X POST "$LOOKER_BASE_URL/api/4.0/queries/run/json" \
  -H "Authorization: token $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ecommerce_training",
    "view": "order_items",
    "fields": ["product_name", "inventory_items.cost"],
    "filters": {
      "inventory_items.cost": ">200"
    }
  }' | jq

# Using Table Calculations (Order Count Percentage)
echo "Applying table calculations (Order Count %)..."
curl -s -X POST "$LOOKER_BASE_URL/api/4.0/queries/run/json" \
  -H "Authorization: token $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "ecommerce_training",
    "view": "order_items",
    "fields": ["order_count"],
    "table_calculations": [
      {
        "name": "percentage_of_orders",
        "expression": "(${order_count} / sum(${order_count})) * 100"
      }
    ]
  }' | jq

echo "Lab automation completed successfully!"
