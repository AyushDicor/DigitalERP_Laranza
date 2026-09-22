# Laranza App — Order Module: Backend API Changes Required

Base URL: `http://supportapi.digitalerp.biz/api/`
App: Laranza (`com.laranza.app`), compid 59. Test login: mobile 9588293167 (userid 510708, branchid 97).

The app now supports **Order Type = Estimate / PI**, an editable **MRP** (Estimate only),
**Discount % or Discount Amount** per line, **Product GST** on a PI, and **Packaging Charges + 18% GST**
on a PI. None of the existing endpoints can store this yet, so today the app keeps it on the
device and posts the same request it always did. The changes below let the server own the data.

Rules followed on the app side: no existing field is renamed or removed; every new field is
optional; Estimate orders send `0` / empty for the PI-only fields.

---

## 1. `POST placeorder/orderentry` — ADD header fields

**Currently sent (unchanged):**
`userid, compid, yearid, branchid, executiveid, partyid, totalamount, shippingamount,
discountpercent, discountamount, cdpercent, cdamount, grandtotal`

**Add (form fields, all optional):**

| Field | Type | Value |
|---|---|---|
| `ordertype` | string | `Estimate` or `PI` |
| `taxableamount` | decimal | goods total after all line discounts (= today's `totalamount`) |
| `productgstamount` | decimal | Σ line GST. `0` on Estimate |
| `packagingcharge` | decimal | base packaging amount typed by user. `0` on Estimate / none |
| `packaginggstpercent` | decimal | always `18` |
| `packaginggstamount` | decimal | `packagingcharge × 18 / 100` |
| `finaltotal` | decimal | `taxableamount + productgstamount + packagingcharge + packaginggstamount` |

Store all of them on the order header. Keep `grandtotal` behaving as it does today.

---

## 2. `POST addtocartwithnetrate` — ADD line fields

**Currently sent (JSON, unchanged):**
`userid, compid, itemid, itemrate, quantity, unitid, netrate, discountpercent`

Current server behaviour (verified): `netrate` drives the stored rate; `netrate = 0` → line is
priced at `itemrate`; `discountpercent` is applied on top server-side.

**Add (JSON, all optional):**

| Field | Type | Value |
|---|---|---|
| `mrp` | decimal | list price the line was raised at. On Estimate the user may retype it; on PI it is the item-master rate. (Today the app puts this in `itemrate`.) |
| `discounttype` | string | `Percent` or `Amount` |
| `discountamount` | decimal | ₹ off **per unit**, when `discounttype = Amount`. When `Amount` is used the app sends `discountpercent = 0` and `netrate = (net rate − discountamount)`; storing `discountamount` lets you show it on the order. |
| `gstpercent` | decimal | the item's GST % (you already have it — see §5) |
| `gstamount` | decimal | `finalrate × quantity × gstpercent / 100` |

Store per cart line, and carry them onto the order line when the order is placed.

---

## 3. `POST cartdetail/getcarddetail` — RETURN the line fields

**Currently returned per row:**
`id, productimage, productid, productname, unit, quantity, itemrate, total, subtotal, shippingamount, grandtotal`

**Add per row:** `mrp, netrate, discounttype, discountpercent, discountamount, gstpercent, gstamount`

---

## 4. `POST orderdetail/orderwithproduct` — RETURN order type + breakdown

**Currently returned:** header `orderid, orderno, orderdate, partyname, partyid, amount, executivename, orderstatus`;
`details[]` = `productname, quantity, unit, rate, amount, productid, productimage`

**Add to header:** `ordertype, taxableamount, productgstamount, packagingcharge, packaginggstpercent, packaginggstamount, finaltotal`
**Add to each `details[]` row:** `mrp, netrate, discounttype, discountpercent, discountamount, gstpercent, gstamount`

---

## 5. `POST Executiveorderlistwithbranch/orderlistexecutivewithbranch` — RETURN `ordertype`

**Currently returned per row:** `orderid, orderno, orderdate, partyname, partyid, amount, executivename, orderstatus`
**Add:** `ordertype` (`Estimate` / `PI`) so the list can badge each order.

---

## 6. `POST orderpdf/getorderpdf` — pick the print format by order type

**Currently:** takes `orderid, compid`; always returns
`https://www.digitalerp.biz/Salesorder/Printoutformate.aspx?id=…&compid=…&branchid=…&userid=…&yearid=…&Type=msaleorder`

**Change:** read the saved `ordertype` of that order and return the **Estimate** print URL for an
Estimate and the **PI** print URL for a PI (two formats you are preparing). The app downloads
whatever URL is returned — **no app change needed** if you do it this way.
(Alternative: accept an `ordertype` parameter — but then §5 must be done first so the app knows
which to ask for. Server-side selection is preferred.)

---

## 7. `POST itemwithbranch/itemlistwithbranch` — optional: include `gstpercent`

Today the app gets each item's GST from `POST itemdetail` (JSON `{compid, itemid}` →
`data[0].gstpercent`), one call per cart line. Adding `gstpercent` to every row of the item list
(and to `getcarddetail`, §3) removes those extra calls. Not blocking.

---

## Summary table

| Endpoint | Change |
|---|---|
| `placeorder/orderentry` | accept + store 7 new header fields |
| `addtocartwithnetrate` | accept + store 5 new line fields |
| `cartdetail/getcarddetail` | return 7 line fields |
| `orderdetail/orderwithproduct` | return order type + header breakdown + line breakdown |
| `Executiveorderlistwithbranch/orderlistexecutivewithbranch` | return `ordertype` |
| `orderpdf/getorderpdf` | choose Estimate vs PI print format from saved `ordertype` |
| `itemwithbranch/itemlistwithbranch` | optional: add `gstpercent` |

Field names above are proposals — if you prefer different names, send them back and the app will
match. Please confirm once deployed and the app will switch from device-side storage to the API.
