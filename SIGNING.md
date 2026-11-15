# Removing the OS warnings later (optional, paid)

Mayak ships free without OS code signing. Your friends see a one-time warning (see the download page).
If you ever want that warning gone:

## macOS: Apple Developer ID + notarization ($99/year)
1. Join the Apple Developer Program and create a "Developer ID Application" certificate.
2. Add these GitHub repository secrets: `APPLE_CERTIFICATE` (base64 .p12), `APPLE_CERTIFICATE_PASSWORD`,
   `APPLE_SIGNING_IDENTITY`, `APPLE_ID`, `APPLE_PASSWORD` (app-specific password), `APPLE_TEAM_ID`.
3. Uncomment the `APPLE_*` lines in `.github/workflows/release.yml`, and in `desktop/src-tauri/tauri.conf.json`
   change `bundle.macOS.signingIdentity` from `"-"` (free ad-hoc signature) to `null` so the certificate is used.
   tauri-action signs and notarizes automatically.

## Windows: code-signing certificate (~$100–400/year, or Azure Trusted Signing)
1. Get an OV/EV certificate (or set up Azure Trusted Signing).
2. Configure `bundle.windows.certificateThumbprint` / `signCommand` in `tauri.conf.json` per the Tauri docs,
   and add the certificate as GitHub secrets.

Nothing else in the pipeline changes. Update signing (Tauri's own key) works with or without OS signing.
