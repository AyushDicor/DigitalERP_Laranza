# Laranza App — Order module: backend status (6 Oct 2026)

Base URL `http://supportapi.digitalerp.biz/api/` · compid 59 · test user 510708 (PRAVEEN JAIN)

## Done on the app side

- **GST selector removed.** As instructed, there is no longer a choice on the Place Order
  screen: every order posts `ordergsttype=Gstcalculation`, Estimate and PI alike.
- Product GST, Packaging Charges and Packaging GST @ 18 % now apply to both document types.
- `orderentrytype` still carries `Estimate` / `PI`, unchanged.

## Verified live today — same figures, both types

Input: goods 1,200 · packing 500 · product GST 216 · packing GST 90 · `finaltotal` 2,006.

| | Estimate (34158, Laranza/02270) | PI (34160, Laranza/02271) |
|---|---|---|
| Layout | ESTIMATE | Sales Order |
| PACKING CHARGE | 500 ✔ | 500 ✔ |
| Taxable Amount | 1,700 | 1,700 |
| Packing GST row | **missing** | `GST 18 % 90` ✔ |
| Product GST row | `IGST 18 % 216` | `IGST 18 % 216` ✔ |
| Grand Total | 2,006 ✔ | 2,006 ✔ |

**Thank you — packaging now prints** (`shippingamount` → PACKING CHARGE). That was the long-
standing gap and it is closed.

## One thing left

**The Estimate template is missing the packing-GST row.** On 34158 the page reads
Taxable 1,700 → IGST 216 → Grand 2,006, but 1,700 + 216 = 1,916. The ₹90 packing GST is inside
the total and nowhere on the page, so the bill does not add up for the customer.

The PI template already prints both rows (`GST 18 % 90` and `IGST 18 % 216`) and adds up
correctly. Please add the same packing-GST row to the Estimate layout — the app sends the value
as `packinggstamt` (with `packinggstpercent=18`) on both types.

Test orders to delete: 34158, 34160 (AAKANSHA KITCHEN, 6 Oct).
