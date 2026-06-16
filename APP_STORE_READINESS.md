# Sales Sparring App Store Readiness

## Product Decision

- App Store price: `$29/month`
- Pro allowance: `150 practice minutes/month`
- Expected Apple commission: `15%` with the Small Business Program
- iOS bundle ID: `com.salessparring.app`
- Native shell: Capacitor iOS

## Current Status

- Capacitor iOS project exists in `ios/`.
- Web assets build into `dist/` with `npm run build`.
- iOS assets sync with `npm run ios:sync`.
- Xcode opens with `npm run ios:open`.
- App icon and launch screen use the Sales Sparring logo.
- iOS microphone/speech privacy strings are present.
- Stripe checkout remains available on web only.
- Native iOS upgrade flow is blocked until StoreKit is connected.

## Required Before TestFlight

1. Create/confirm Apple Developer account.
2. Enroll in Apple Small Business Program.
3. Create App Store Connect app for `com.salessparring.app`.
4. Create auto-renewable subscription:
   - Product ID: `pro_monthly_29`
   - Price: `$29/month`
   - Entitlement: `150 monthly practice minutes`
5. Add StoreKit purchase/restore flow in the iOS app.
6. Add backend receipt validation and minute-granting logic.
7. Add account deletion flow.
8. Publish privacy policy and terms URLs.
9. Fill App Privacy labels:
   - Account data
   - Audio/microphone use
   - Analytics/progress data
   - Purchase/subscription data
10. Test signup, mic permission, first call, scoring, subscription restore, and sign out in TestFlight.

## Commands

```sh
npm install
npm run build
npm run ios:sync
npm run ios:open
```
