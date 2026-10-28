# Hisab — UX & Colour Refresh

Ideas taken (not copied) from two community UI kits, Montra and mono, and adapted to what
Hisab already does. Anything Hisab has no use for — bank linking, card payments, PIN
onboarding — is left out. The goal is the same as the simplicity pass: fewer decisions per
screen, the important number first, and colour that tells you what you are looking at.

## Colour: vivid teal

Hisab keeps its teal identity, brighter and with clear meaning per kind of money.

| Role | Colour | Used for |
| --- | --- | --- |
| Primary | `#0D9488` → `#14B8A6` | Brand, buttons, the dashboard hero gradient |
| Expense | `#F43F5E` coral | Money out, overspent, overdue |
| Income | `#10B981` mint | Money in, saved, settled |
| Transfer | `#3B82F6` blue | Moves between your own accounts |
| Accent | `#F59E0B` amber | Near a limit, highlights |
| Surfaces | `#F8FAFC` light, `#0B1416` dark | Scaffold and splash background |

Category icons sit on a soft tile of their own colour (about 14% opacity) instead of a solid
badge, so long lists stay calm and colourful at once.

## UX ideas

1. **Coloured entry header.** The amount is the hero: a big "How much?" figure at the top
   whose header colour says the kind — coral expense, mint income, blue transfer. The
   fields sit below on a rounded sheet with one save button.
2. **The + button picks the kind.** Tapping + fans out Income, Expense and Transfer, so the
   kind is chosen before the form opens instead of inside it.
3. **Simpler dashboard hero.** The balance centred and large on a teal gradient card, with
   two tinted tiles below for Income and Expenses, then a Today / Week / Month / Year switch
   on the trend chart.
4. **Transaction rows.** Tinted category tile, title and note on the left, signed amount in
   its colour on the right with the time underneath, rows grouped under Today / Yesterday /
   date. One filter sheet (type, sort, category, Reset) instead of scattered controls.
5. **Budgets.** "Remaining ₹X" is the big number, a progress bar in the category's colour,
   and a coral "You've exceeded the limit" pill when over.
6. **Reports.** An Expense / Income switch, line or donut view, and the category list with
   thin progress bars under each row.
7. **Monthly recap (optional).** Full-screen story cards at the start of a month: "You spent
   ₹X, mostly on Food", "You earned ₹Y", "2 of 12 budgets went over".
8. **Transaction detail.** Big amount on a header tinted by kind, then plain label/value
   rows (account, category, date, time, note) and the actions at the bottom.

## Order of work

Each step ships as its own small PR.

1. Colour tokens: the palette above in `lib/core/theme.dart`, splash/launcher colours, and
   tinted category tiles.
2. Coloured entry header (idea 1).
3. Dashboard hero with gradient and Income/Expense tiles (idea 3).
4. Transaction rows and the single filter sheet (idea 4).
5. Budgets and reports (ideas 5 and 6).
6. + button fan-out (idea 2) and transaction detail (idea 8).
7. Monthly recap (idea 7), only if the rest lands well.
