# Laranza App — Order module: backend status (6 Oct 2026)

Base URL `http://supportapi.digitalerp.biz/api/` · compid 59 · test user 510708 (PRAVEEN JAIN)

## Done on the app side

- **GST selector removed.** Every order posts `ordergsttype=Gstcalculation`, Estimate and PI
  alike. Product GST, Packaging Charges and Packaging GST @ 18 % apply to both.
- **CD % added** on the Place Order screen, above Packaging. It comes off the goods **before**
  tax, so the GST is calculated on the reduced amount; packaging and its 18 % are added after
  and are not affected. Left empty it is 0 and nothing changes.
- `cdpercent` / `cdamount` are now posted with real values (they used to be hard-coded 0).

## Order of calculation the app uses

```
goods              = Σ line amounts            (after the per-line discounts)
cash discount      = goods × cdpercent / 100   -> cdamount
taxable            = goods − cdamount          -> taxableamount
product GST        = tax on the REDUCED goods  -> productgstamount
packing            = shippingamount,  packing GST = 18 % of it
final total        = taxable + product GST + packing + packing GST  -> finaltotal / grandtotal
```

## Verified live today

### 1. CD works — but it is not deducted on the printout

Order **34169 / Laranza/02272** (PI). Sent: `totalamount 1250, discountamount 50,
cdpercent 10, cdamount 120, taxableamount 1080, productgstamount 194.40,
shippingamount 500, packinggstamt 90, finaltotal 1864.40`.

The printout shows `CD Amount : 120.00` ✔ — thank you, the parameter is through. But the rows
below it ignore it:

| Row printed | Value | Should be |
|---|---|---|
| Total Amount | 1,250.00 | 1,250.00 ✔ |
| Discount Amount | 50.00 | 50.00 ✔ |
| CD Amount | 120.00 | 120.00 ✔ |
| PACKING CHARGE | 500.00 | 500.00 ✔ |
| **Taxable Amount** | **1,700.00** | **1,580.00** (1250 − 50 − **120** + 500) |
| **IGST 18 %** | **306.00** | **284.40** (18 % of 1,580) |
| Grand Total | 1,864.00 | 1,864.40 ✔ |

So the page does not add up: 1,700 + 306 = 2,006, but the Grand Total prints 1,864. The Grand
Total is right (it comes from `finaltotal`); the Taxable Amount and the tax are computed in the
proc as `totalamount − discountamount + packing` and never subtract `cdamount`.

**Please subtract CD Amount when working out Taxable Amount and the tax.** With that one change
the printout matches the app exactly: 1,580 + 284.40 = 1,864.40.

### 2. Estimate template is missing the packing-GST row

Order **34158 / Laranza/02270** (Estimate, no CD): Taxable 1,700 → IGST 216 → Grand 2,006, but
1,700 + 216 = 1,916 — the ₹90 packing GST is inside the total and nowhere on the page.
The PI template (34160) prints both `GST 18 % 90` and `IGST 18 % 216` and adds up correctly.
Please add the same packing-GST row to the Estimate layout.

Test orders to delete: 34158, 34160, 34169 (AAKANSHA KITCHEN, 6 Oct).
