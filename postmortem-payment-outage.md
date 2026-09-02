# Postmortem: Payment Service Outage (Extended)

## What happened
Used Chaos Mesh's `pod-failure` action to make the `paymentservice` pod unavailable in the `online-boutique` namespace for 180 seconds, simulating an extended backend service outage. This followed an earlier, shorter test (`pod-kill`, 60s) that failed to produce any observable impact, because Kubernetes restarted the pod within a few seconds — faster than any test could catch it.

## Impact
During the 180-second outage window, attempting to complete checkout resulted in an HTTP 500 error at the checkout step. The basic frontend health check (`probe_success`) remained at 100% throughout, since it only checks if the homepage loads — it does not detect checkout failures specifically.

## How we detected it
The basic Blackbox `frontend-probe` health check stayed at 100% throughout the outage, since it only checks whether the homepage loads. The custom `checkout_success` synthetic test — which performs a real add-to-cart-and-checkout flow via a scripted Kubernetes CronJob — correctly dropped to 0 during the outage, confirming it detects failures the basic check misses.

## Recovery
After the 180-second outage window ended, the `checkout_success` test was re-run manually and returned `SUCCESS`, confirming the payment service had recovered and checkout was functioning normally again. The CronJob continued running automatically every 2 minutes afterward, providing ongoing confirmation of recovery.

## Takeaway
The first attempt using `pod-kill` (60s) did not catch any impact, because Kubernetes restarted the pod within a few seconds — faster than the test could observe it. Switching to `pod-failure` (180s) kept the service genuinely unavailable long enough to observe real impact. This showed that basic uptime checks aren't enough on their own — synthetic testing of the actual user flow (checkout) is needed to catch failures that a simple health check misses. It also confirmed that the choice of chaos action (`pod-kill` vs `pod-failure`) and duration matters significantly when designing failure experiments — a test that's too short or too "recoverable" can give a false sense of resilience.