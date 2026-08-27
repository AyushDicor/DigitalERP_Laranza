# Employee Profile — API contract for the backend team

The app's Profile module has been rebuilt to show the full **ERP Employee Master**
(the same form as `Views/Home/EmployeeMaster.cshtml`), split into 9 mobile sections
with a View / Edit toggle per section.

**The app side is done.** It needs three endpoints. Until they exist the screen
still runs: General Details is seeded from the login payload and saved through the
existing `UserProfile/userProfile` endpoint, the other sections render empty, and a
notice tells the user the data isn't connected yet.

Base URL is the app's existing one: `http://supportapi.digitalerp.biz/api/`.
All three are `POST`, `Content-Type: application/json`, and should use the usual
`{success, data, message, status}` envelope with **HTTP 200 always** (status carries
the real result, as with every other endpoint).

---

## 1. `EmployeeProfile/employeeProfileDetail`

Returns the whole Employee Master record for the logged-in user.

**Request**

```json
{ "userid": "6", "compid": "2" }
```

**Response**

```json
{
  "success": true,
  "status": 200,
  "message": "",
  "data": {
    "id": 145,
    "employeeid": "EMP001",
    "firstname": "Ekansh",
    "lastname": "Kunchal",
    "employeephoto": "http://supportapi.digitalerp.biz/assets/EmployeeImages/145.jpg",
    "...": "every key from the section tables below",
    "items": [ { "childname": "...", "childage": "6" } ],
    "experienceitems": [ { "organizationname": "...", "fromdate": "2020-04-01" } ]
  }
}
```

Notes:

- `data` may also be a **single-row array** — the app accepts both.
- Key matching is **case-insensitive**, so `PermanentPincode` and `permanentpincode`
  both work. Use whatever the proc already returns.
- The link from the app user to the employee row is yours to decide
  (`tb_login.userid` → employee). The app only sends `userid` + `compid`.
- Dates: ISO (`2024-04-01` or `2024-04-01T00:00:00`) or `dd-MM-yyyy`. The app parses
  all three and always sends back `yyyy-MM-dd`.
- Checkboxes: `1`/`0`, `true`/`false`, `Y`/`N` all read as booleans.
- **File/image fields must be returned as a full URL starting with `http`** — the app
  only renders a View link for values that do. A bare filename shows as plain text.

---

## 2. `EmployeeProfile/saveEmployeeProfileSection`

Saves **one** section. The app never posts the whole record.

**Request**

```json
{
  "userid": "6",
  "compid": "2",
  "section": "general",
  "data": {
    "id": "145",
    "employeeid": "EMP001",
    "firstname": "Ekansh",
    "lastname": "Kunchal",
    "gender": "Male",
    "genderid": "1",
    "signaturepath": "sign.png",
    "signaturepathbase64": "iVBORw0KGgoAAAANSUhEUg...",
    "signaturepathfilename": "sign.png"
  }
}
```

`section` is one of:
`general` · `family` · `references` · `children` · `employeetype` · `salary` ·
`documents` · `bank` · `address`

These map onto the web ERP's existing per-section actions
(`EmployeeMasterGeneral`, `EmployeeFamilyDetails`, `EmployeeReferenceDetails`,
`EmployeeChildrenDetails`, `EmployeeType`, `SalaryDetails`, `DocumentDetails`,
`EmployeeBankDetails`, `EmployeadddressDetails`) and their procs
(`proc_EmployeeGeneralDetailsnew`, `UpdateFamilyDetails`, …).

**Conventions inside `data`**

| Pattern | Meaning |
|---|---|
| `<field>` | the value; for dropdowns this is the **display name** |
| `<field>id` | the selected lookup id, when the ERP stores one (`departmentname` → `department`, `permanentstate` → `permanentstateid`) |
| `<field>base64` | base64 of a newly picked file — **empty means unchanged** |
| `<field>filename` | original filename of that upload |

**Response** — same envelope. If `data` is present the app replaces its local copy
with it, so returning the saved record (with stored file URLs) is the cleanest option.
Returning just `{success, status: 200, message}` also works.

---

## 3. `EmployeeProfile/employeeProfileLookups`

Dropdown lists. Optional — every dropdown falls back to a free-text input when its
list is missing, so nothing breaks without this.

**Request** — `{ "userid": "6", "compid": "2" }`

**Response**

```json
{
  "success": true,
  "status": 200,
  "data": {
    "genders":       [{ "id": "1", "name": "Male" }],
    "departments":   [{ "id": "4", "name": "IT" }],
    "designations":  [{ "id": "9", "name": "Sr. Developer" }],
    "states":        [{ "id": "12", "name": "Delhi" }],
    "cities":        [{ "id": "88", "name": "Janakpuri", "parentid": "12" }],
    "accounttypes":  [{ "id": "1", "name": "Savings" }],
    "documentnames": [{ "id": "3", "name": "Degree Certificate" }],
    "maritalstatus": [{ "id": "1", "name": "Married" }],
    "esideduction":  [{ "id": "1", "name": "Yes" }],
    "employeenature":[{ "id": "1", "name": "SALARIED" }]
  }
}
```

- List names are matched case-insensitively.
- `cities` uses `parentid` = the state id, so the city list filters by the chosen state.
  Without `parentid` the full list is shown — still usable.
- A plain string array (`["Male","Female"]`) is accepted too.

---

## Field keys by section

Keys are taken from `Models/Master/EmployeeMaster.cs` so they map 1:1 to what the web
ERP already posts — including its existing typos (`desgination`, `emloyeedepartment`),
which were kept deliberately.

### general
`firstname` `lastname` `gender` (+`genderid`) `employeeid`* `departmentname` (+`department`)*
`desginationname` (+`desgination`)* `pfno`* `esino`* `biometricid`* `companyemailid`
`personalemailid` `personalphone` `alternativenumber` `dob` `dateofjoining`*
`placeofjoining`* `reqby`* (Reporting Person) `assestsissued`* `signaturepath` (file) `remarks`

### family
For each of `spouse` / `father` / `mother`:
`<p>firstname` `<p>lastname` `<p>phone` `<p>profession` `<p>adhaar` `<p>pan` `<p>imagepath` (file)
plus `status` and `statusdate`.

### references
`reference1name` `reference1phone` `reference1address` `reference1idproofpath` (file)
and the same with `reference2`.

### children
Repeatable list under **`items`** — each row:
`childname` `childgender` (+`childgenderid`) `childage` `childeducation` `childaadharno`
`childpanno` `childimagepath` (file)

### employeetype
`experienced` `freshers` `employeenature` `esideduction` (+`esideductionid`) `lastwithdrawalsalary`
Repeatable list under **`experienceitems`** (shown only when `experienced` is ticked) — each row:
`organizationname` `organizationwebsite` `fromdate` `todate` `contactnumber`
`emloyeedepartment` `emloyeedesignation` `workexperience` `reasontoleaveprevious` `yourcomment`

### salary — all read-only in the app
`basicsalary` `effectform` `grade` `incrementmonth` `incrementpercent` `latitude` `longitude` `distance`

### documents
`aadharcardnumber` `aadharcardpath` (file) `pancardnumber` `pancardpath` (file)
`drivinglicencenumber` `drivinglicencepath` (file) `voteridcardnumber` `voteridcardpath` (file)
`documentname` (+`documentnameid`) `documentpath` (file)

### bank
`createbyorganization` `havealready` `bankname` `ifsccode` `accountnumber` `holdername`
`branchname` `accounttype` (+`accounttypeid`)

### address
Permanent: `permanentfulladdress` `permanentstate` (+`permanentstateid`) `permanentcity`
(+`permanentcityid`) `permanentpincode` `permanentaddressproofpath` (file) `permanentcontactnumber`
Present: `presentfulladdress` `presentstate` (+`presentstateid`) `presentcity` (+`presentcityid`)
`presentpincode` `presentaddressproofpath` (file) `ownername` `presentcontactnumber`

\* = shown read-only in the app (HR-controlled). They are still sent in the payload;
reject or ignore changes to them server-side as you see fit.

---

## Fields on the web form with no column in `EmployeeMaster.cs`

These are rendered by the app and will stay blank until columns exist:

`status` · `statusdate` · `employeenature` (SALARIED / IMPREST) · `incrementmonth` ·
`incrementpercent` · `latitude` · `longitude` · `distance`

The repeatable previous-employment list also needs a table — the current model holds
only one set of `organizationname` / `fromdate` / … fields, but the web form's **Add**
button implies many rows. The app posts them as the `experienceitems` array.

---

## What the app does today, before any of this ships

- General Details: seeded from the login response (`name` → first/last name,
  `email` → company email, `address` → permanent address, `mobile` → personal phone,
  `photo`, `usertype`).
- Saving General falls back to `UserProfile/userProfile` and persists name + email,
  telling the user the rest needs the new API.
- The profile photo still goes through `UserProfile/userProfile` exactly as before.
- Every other section renders its fields empty with an "not connected yet" notice.

Nothing else in the app was touched, and no database or API change was made from this side.
