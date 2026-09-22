# Laranza App — Order Type / PI: Backend Status (21 Sep 2026)

Base URL: `http://supportapi.digitalerp.biz/api/` · compid 59 · test user 510708 (PRAVEEN JAIN)

The three new endpoints are live and the app now uses them. Verified end-to-end from the app:
order **Laranza/02242/22-22** (PI, 2 × Thali @ 25 % + packaging ₹500) placed for ₹1,696.

---

## DONE — app is wired to these

| Endpoint | What the app sends / reads | Notes |
|---|---|---|
| `POST addtocartwithnetrate` | + `discountamount`, `ordertype` (`Estimate` / `PI`) | Contract observed: `netrate` is the stored rate (0 → use `itemrate`); **`discountpercent` is recorded only, no longer applied** — the app now sends the already-reduced rate for a % discount; `discountamount` IS applied by the server. Please keep it this way (or tell us if you change it). |
| `POST cartdetailnew` | reads `ordertype, gstpercent, gstamount, discountpercent, discountamount` per row | The app no longer calls `itemdetail` per item. |
| `POST placeorderlarnza` | + `ordertype, taxableamount, productgstamount, packagingcharge, packaginggstpercent, packaginggstamount, finaltotal` | Order amount is taken from `finaltotal` ✔. |

Packaging Charges are now entered on BOTH types. Estimate: packaging added to the total, NO packaging
GST. PI: packaging + 18 % GST. `packaginggstamount` is posted as 0 on an Estimate.

No changes are needed to the order list or order detail APIs — the breakdown only has to appear
on the printed bill.

---

## STILL NEEDED — the printed bill

### 1. Two formats — `orderpdf/getorderpdf`
Both order types still return the same file (`…Printoutformate.aspx?…&Type=msaleorder`).
Return the **Estimate** print URL when the order's saved `ordertype = Estimate` and the **PI**
print URL when `PI`. The app downloads whatever URL is returned, so no app change is needed.

### 2. PI bill — `Salesorder/Printoutformate.aspx`
- **Packaging rows are missing** (needed on BOTH formats — on the Estimate bill show only
  `Packaging Charges`, no GST row; e.g. order 33853: goods 800 + packaging 500 = 1,300). Order 33852: taxable 937.50 + IGST 168.75 = 1,106.25, but Grand
  Total prints 1,696.00 with only "Rounded Off −0.25" between — the ₹500 packaging and ₹90
  packaging GST are in the total but not shown. Add two rows: `Packaging Charges` and
  `Packaging GST @ 18 %`.
- **Net Rate column prints 0** for a line discounted by % (orders 33849 / 33852: MRP 625, Net
  Rate `0`, Dis 25 %, Amount 937.50). The app sends `netrate = 468.75` for that line. For an
  amount-discounted line the column is correct (3065 → 2865).

### 3. Small fixes
- `cartdetailnew` returns **one all-zero row** (`id 0`) for an empty cart instead of `[]`. The
  app filters it, but an empty array would be cleaner.
- `placeorderlarnza` answers **"Order Placed Successfully"** to an empty body (nothing is created).
  It should reject a request without `userid / compid / partyid`.
