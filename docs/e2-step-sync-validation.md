# Momentum E2 Step Sync Validation

Use this checklist when recording the E2 demo on a real device.

## Android with Health Connect

1. Open `Health sync`.
2. Tap `Validate device again`.
3. Show:
   - `Health Connect / Ready`
   - permission state
   - connected step habit count
4. Tap `Connect and sync steps`.
5. Approve:
   - Activity Recognition
   - Health Connect step permission
6. Return to Momentum and show:
   - `Last steps`
   - `Last sync`
   - `Synced from Health Connect` on the Daily Steps card

## iPhone with Apple Health

1. Open `Health sync`.
2. Tap `Validate device again`.
3. Tap `Connect and sync steps`.
4. Approve Apple Health step access.
5. Return to Momentum and show:
   - `Synced from Apple Health` on the Daily Steps card
   - updated step count on the habit card

## Evidence to capture

- Screenshot of the validation screen before permission
- Screenshot of the permission dialog
- Screenshot of the validation screen after sync
- Screenshot of the Daily Steps card after sync
- Short video of sync updating the card

## Local verification already completed

- `flutter analyze`
- `flutter test`
