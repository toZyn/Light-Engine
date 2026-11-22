# Cleanup before main

1. Delete wip/ before integrating into main.
2. Retain maintained compatibility documentation outside wip/ and review it for stale claims.
3. Keep engine tests, synthetic fixtures, the reference harness and required upstream licenses/attribution.
4. Recheck that no mod payloads, archives, screenshots or secrets are tracked.
5. Run the relevant regression and compiled-reference checks, recording unverified targets.
6. Integrate the reviewed engine changes by squash merge so temporary WIP history is not added to main.
7. Do not force-push main or the PR #22 branch. This backup is independent of those refs.
