# Reference apps: what we learned and what Hisab borrows

Seven apps were studied in October 2026: FinArt, axio (formerly Walnut), Splitwise,
Money Manager (RealByte), Monefy, Cashew and PennyWise AI. Six were installed on the
Pixel_API36 emulator and driven screen by screen; FinArt was studied from its site and store
listing because no APK source was reachable. Permissions for each are tabulated in
[PERMISSIONS.md](PERMISSIONS.md). Hisab reuses no code or assets from any of them.

## Per app

| App | What it does well | What we avoid |
|---|---|---|
| FinArt | Dashboard leads with "spent this month" and balances; review inbox with Add / Edit / Ignore per SMS; custom financial-month start; private mode (data on device, backup to the user's own Drive) | 5-day trial then subscription; SMS auto-tracking is paid |
| axio / Walnut | Proved SMS-based tracking is viable in India; bills and balance checks from SMS | Phone + OTP wall; root and emulator detection modal; bundled lending |
| Splitwise | Group ledger model: groups, "you owe / you are owed", settle up, simplify debts; six split methods (equal, exact, percent, shares, adjustment, itemised) | Account required before anything works; free tier capped at a few expenses per day with ads |
| Money Manager | Explain-then-ask permission dialog with SMS marked "not required"; morphing bottom panel (keypad, category grid, account grid); "Save" and "Save & add another"; day-grouped list with per-day totals and an income / expense / total strip | Dated dense visuals; too many tabs and settings |
| Monefy | Fastest entry (amount, then tapping a category commits); calculator keypad; donut with category icons on the ring; first-run coachmarks | Two paywall screens before first use; icon-only categories; back button discards a half-filled form |
| Cashew (Flutter) | Title autocomplete that fills the category from history; chained bottom sheets; bill splitter with item x quantity assigned to people; "Continue without sign in" | Icon buttons without semantic labels; splitter buried under "More"; splits can reach a 0% state |
| PennyWise AI | Best SMS consent copy ("Enable automatic detection" plus privacy bullets, Skip always visible), explicit scan step with a result screen; hidden-amount eye toggle; budget cycle start day; smart rules; UPI handle to contact name | Long single form with the OS keyboard for amounts; dropdown category picker; 1.6 GB on-device model for chat |

## Patterns Hisab adopts
- Local-first, no login, no paywall. The first screen is the dashboard.
- Multi-item entries with quantity, unit and price per line, remembered per category. No reference app does this.
- SMS is opt-in with the PennyWise-style disclosure, a visible "not now", and a review inbox before anything is written.
- Entry list grouped by day with totals, month stepper, kind filter and search.
- Category picker as a searchable grid of coloured icon tiles, with the same icon and colour reused in charts and rows.
- Groups live in the bottom navigation, with Splitwise's six split methods and settle-up suggestions, plus Cashew's by-item assignment.
- Salary-month cycle, lakh grouping and Indian default categories.
- Every control carries a semantic label so screen readers and UI tests can find it.

## Backlog taken from the study
- Calculator keypad for the amount field, where "+" starts a new line item.
- "Save & add another" on the entry form.
- Merchant autocomplete that fills the category from history, and user-defined rules (amount or merchant pattern to category).
- UPI handle to contact name mapping (needs the contacts permission, so it stays opt-in).
- Hidden-amount eye toggle and this-month-vs-last-month comparison on the dashboard.
- "Exclude from analytics" and provenance ("from SMS" vs manual) on the entry detail.
- Notification-listener fallback for bank-app alerts if the Play SMS declaration is refused.
- Confirm before discarding a half-filled form.
