#!/bin/bash

FRONTEND_URL="http://frontend.online-boutique.svc.cluster.local"
PUSHGATEWAY_URL="http://pushgateway-prometheus-pushgateway.default.svc.cluster.local:9091"

# Step 1: Add a product to cart
ADD_TO_CART=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$FRONTEND_URL/cart" \
  -d "product_id=OLJCESPC7Z&quantity=1")

# Step 2: Submit checkout with test shipping/payment info
CHECKOUT=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$FRONTEND_URL/cart/checkout" \
  -d "email=test@example.com&street_address=123+Test+St&zip_code=94043&city=Mountain+View&state=CA&country=USA&credit_card_number=4432801561520454&credit_card_expiration_month=1&credit_card_expiration_year=2030&credit_card_cvv=672")

# Step 3: Determine success (both steps should return 200 or 302)
if [[ "$ADD_TO_CART" =~ ^(200|302)$ ]] && [[ "$CHECKOUT" =~ ^(200|302)$ ]]; then
  RESULT=1
  echo "Checkout test: SUCCESS"
else
  RESULT=0
  echo "Checkout test: FAILED (add_to_cart=$ADD_TO_CART, checkout=$CHECKOUT)"
fi

# Step 4: Push result to Pushgateway
cat <<EOF | curl -s --data-binary @- "$PUSHGATEWAY_URL/metrics/job/checkout_test"
checkout_success $RESULT
EOF