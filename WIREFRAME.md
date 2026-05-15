# Jewelry App — Wireframe & Navigation Map

> Visual architecture diagram for Google Stitch UI generation.

---

## Navigation Flow Diagram

```mermaid
graph TD
    SPLASH["/splash<br/>Splash Screen"] --> AUTH_CHECK{Logged In?}
    AUTH_CHECK -->|No| WELCOME["/welcome<br/>Welcome Screen"]
    AUTH_CHECK -->|Yes| HOME

    WELCOME --> SIGNIN["/signin<br/>Sign In"]
    WELCOME --> SIGNUP["/signup<br/>Sign Up"]

    SIGNUP --> VERIFY["/verify-code<br/>Verify Code"]
    VERIFY --> COMPLETE["/profile<br/>Complete Profile"]
    COMPLETE --> HOME

    SIGNIN --> HOME["/home<br/>Home Screen"]
    SIGNIN --> FORGOT["/forgot-password<br/>Forgot Password"]
    FORGOT --> VERIFY
    VERIFY --> NEWPASS["/new-password<br/>New Password"]
    NEWPASS --> SIGNIN
```

---

## Main App Tab Structure

```mermaid
graph LR
    subgraph BottomNav["Bottom Navigation Bar"]
        TAB1["🏠 Home"]
        TAB2["🛒 Cart"]
        TAB3["📷 AI Scan"]
        TAB4["❤️ Wishlist"]
        TAB5["👤 Profile"]
    end
```

---

## Home Screen Wireframe

```
┌──────────────────────────────────┐
│  🔔  [Logo Area]           👤   │ ← HomeHeader
├──────────────────────────────────┤
│  🔍 Search catalog...        📷 │ ← SearchBarWidget (pill)
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │   🖼️ Promotional Banner     │ │ ← OfferBanner (carousel)
│ │   "Summer Collection"       │ │
│ │          [Shop Now]         │ │
│ └──────────────────────────────┘ │
│         ● ○ ○  (dots)           │
├──────────────────────────────────┤
│ Catalog Collections   Browse All│
│ [Rings] [Necklaces] [Bracelets] │ ← CategoryList (pills)
├──────────────────────────────────┤
│ Best Sellers          Browse All│
│ ┌──────────┐ ┌──────────┐      │
│ │  🖼️      │ │  🖼️      │      │ ← ProductGrid (2-col)
│ │          │ │          │      │
│ │ Name     │ │ Name     │      │
│ │ $XX  Buy │ │ $XX  Buy │      │
│ └──────────┘ └──────────┘      │
├──────────────────────────────────┤
│ Trending Items        Browse All│
│ ┌────────┐ ┌────────┐ ┌──      │
│ │  🖼️    │ │  🖼️    │ │ 🖼️    │ ← Horizontal scroll
│ │ Name   │ │ Name   │ │       │
│ │ $XX Buy│ │ $XX Buy│ │       │
│ └────────┘ └────────┘ └──      │
├──────────────────────────────────┤
│  🏠    🛒    📷    ❤️    👤    │ ← BottomNav
└──────────────────────────────────┘
```

---

## Product Detail Wireframe

```
┌──────────────────────────────────┐
│ ←  🔍 Search...        🔗  🛒  │ ← TopBarSearch
├──────────────────────────────────┤
│                                  │
│        🖼️ Product Image          │ ← PageView gallery
│        (swipe for more)          │
│            ● ○ ○ ○               │
├──────────────────────────────────┤
│ Gold Earring                     │
│ ⭐ 4.8 (124 reviews)            │
│ $1,200.00                        │
├──────────────────────────────────┤
│ Size:  [6] [7] [8] [9] [10]     │ ← Pill chips
│ Purity: [18K] [22K] [24K]       │ ← Pill chips
├──────────────────────────────────┤
│ 🎫 Vouchers ──────────────►     │
│ [20% OFF] [Free Ship] ...       │ ← Horizontal scroll
├──────────────────────────────────┤
│ ▼ Description                    │ ← CollapsibleSection
│ ▼ Specifications                 │ ← CollapsibleSection
├──────────────────────────────────┤
│ Complete Your Set                │
│ ┌────────┐ ┌────────┐ ┌──      │ ← RecommendationList
│ └────────┘ └────────┘ └──      │
├──────────────────────────────────┤
│ Similar Products                 │
│ ┌────────┐ ┌────────┐ ┌──      │ ← SimilarProductList
│ └────────┘ └────────┘ └──      │
├──────────────────────────────────┤
│ 👤Chat  [Add to Cart] [Buy Now] │ ← BottomBarCTA
└──────────────────────────────────┘
```

---

## Cart Screen Wireframe

```
┌──────────────────────────────────┐
│           My Cart                │
├──────────────────────────────────┤
│ ☑ Select All                     │
├──────────────────────────────────┤
│ ┌──────────────────────────────┐ │
│ │ ☑ 🖼️  Product Name     Edit │ │
│ │       Category               │ │
│ │       Size: 7 | Purity: 18K │ │
│ │       $1,200    [- 1 +]     │ │
│ │ ─────────────────────────── │ │
│ │ 🎫 SAVE20       10% OFF  ▸ │ │
│ └──────────────────────────────┘ │
│        (swipe ← to delete)       │
├──────────────────────────────────┤
│ [Promo Code         ] [Apply]    │
│ Sub-Total              $1,200.00 │
│ Delivery                 $20.00  │
│ Tax                      $24.00  │
│ Discount                -$120.00 │
│ ─────────────────────────────── │
│ Total                 $1,124.00  │
│ [    Proceed to Checkout     ]   │
└──────────────────────────────────┘
```

---

## Checkout Screen Wireframe

```
┌──────────────────────────────────┐
│ ←        Checkout                │
├──────────────────────────────────┤
│ 📍 Shipping Address     Change  │
│    Home                          │
│    123 Le Loi St, District 1     │
│    +84 912 345 678               │
├──────────────────────────────────┤
│ 🚚 Shipping Method               │
│ ○ Premium (2-3 days)     $20    │
│ ● Express (Next day)     $35    │
│ ○ Standard (5-7 days)    Free   │
├──────────────────────────────────┤
│ 💳 Payment Method                │
│ ○ Credit Card                    │
│ ○ Apple Pay                      │
│ ● Cash on Delivery               │
├──────────────────────────────────┤
│ Order Summary                    │
│ Sub-total / Shipping / Tax       │
│ Total                 $1,259.00  │
│ [      Place Order           ]   │
└──────────────────────────────────┘
```

---

## Profile Screen Wireframe

```
┌──────────────────────────────────┐
│ ←                           ⚙️   │
├──────────────────────────────────┤
│            👤 Avatar             │
│          Elowen Sutter           │
├──────────────────────────────────┤
│ 👤 Edit Profile              ▸  │
│ 📍 Manage Address            ▸  │
│ 💳 Payment Methods           ▸  │
│ 📦 My Orders                 ▸  │
│ 💰 My Wallet                 ▸  │
│ 🎫 My Coupons                ▸  │
│ ⚙️ Settings                  ▸  │
│ ❓ Help Center               ▸  │
│ 🔒 Privacy Policy            ▸  │
├──────────────────────────────────┤
│        [🚪 Log Out]             │
├──────────────────────────────────┤
│  🏠    🛒    📷    ❤️    👤    │
└──────────────────────────────────┘
```

---

## Full Navigation Map

```mermaid
graph TD
    HOME["🏠 Home"] --> SEARCH["Search Results"]
    HOME --> CATEGORY["Category Screen"]
    HOME --> BESTSELLER["Best Sellers"]
    HOME --> POPULAR["Popular Products"]
    HOME --> OFFERS["Special Offers"]
    HOME --> NOTIF["Notifications"]
    HOME --> PRODUCT["Product Detail"]

    PRODUCT --> GALLERY["Full Screen Gallery"]
    PRODUCT --> REVIEW["Reviews"]
    PRODUCT --> SELLER["Seller Profile"]
    PRODUCT --> CART

    REVIEW --> LEAVE_REVIEW["Leave Review"]
    SELLER --> CHAT_DETAIL["Chat Detail"]

    CART["🛒 Cart"] --> CHECKOUT["Checkout"]
    CART --> COUPON["Coupon Selection"]
    CHECKOUT --> SUCCESS["Order Success"]
    SUCCESS --> TRACK["Track Order"]
    SUCCESS --> HOME

    AISCAN["📷 AI Scan"] --> PRODUCT
    WISHLIST["❤️ Wishlist"] --> PRODUCT

    PROFILE["👤 Profile"] --> EDIT["Edit Profile"]
    PROFILE --> ADDRESS["Manage Address"]
    PROFILE --> PAYMENT["Payment Methods"]
    PROFILE --> ORDERS["My Orders"]
    PROFILE --> WALLET["Wallet"]
    PROFILE --> SETTINGS["Settings"]
    PROFILE --> HELP["Help Center"]
    PROFILE --> PRIVACY["Privacy Policy"]

    ORDERS --> TRACK
    ORDERS --> ERECEIPT["E-Receipt"]
    WALLET --> TOPUP["Top Up"]
    ADDRESS --> ADD_ADDR["Add Address"]
    PAYMENT --> ADD_CARD["Add Card"]

    SETTINGS --> PASS_MGR["Password Manager"]
    SETTINGS --> NOTIF_SET["Notification Settings"]
    SETTINGS --> DELETE["Delete Account"]

    HOME --> CHAT_LIST["Chat List"]
    CHAT_LIST --> CHAT_DETAIL
```

---

## Product Card Component Wireframe

```
┌────────────────────┐
│ ┌────────────────┐ │
│ │                │♡│  ← 32px translucent circle
│ │   🖼️ Product   │ │     with heart icon
│ │    Image       │ │
│ │   (1:1 ratio)  │ │  ← 8px border-radius
│ └────────────────┘ │
│                    │
│ Product Name       │  ← 14px, w600, ink
│ (max 2 lines)      │
│                    │
│ $1,200    Buy      │  ← Price: 14px, w400
│                    │     Buy: 13px, Action Blue
└────────────────────┘
  18px border-radius
  1px hairline border
  12px internal padding
  Scale 0.96 on press
```

---

## Onboarding Flow

```mermaid
graph LR
    OB1["Page 1<br/>Effortless Shopping"] --> OB2["Page 2<br/>Build Jewelry Box"]
    OB2 --> OB3["Page 3<br/>Quick & Secure"]
    OB3 --> SIGNIN["Sign In Screen"]

    OB1 -.->|Skip| SIGNIN
    OB2 -.->|Skip| SIGNIN
```

---

## Auth Flow

```mermaid
graph TD
    WELCOME["Welcome"] --> SI["Sign In"]
    WELCOME --> SU["Sign Up"]

    SU --> VC1["Verify Code"]
    VC1 --> CP["Complete Profile"]
    CP --> HOME["Home"]

    SI --> HOME
    SI --> FP["Forgot Password"]
    FP --> VC2["Verify Code"]
    VC2 --> NP["New Password"]
    NP --> SI
```

---

## Order Flow

```mermaid
graph LR
    CART["Cart"] --> CHECKOUT["Checkout"]
    CHECKOUT --> SUCCESS["Order Success"]
    SUCCESS --> TRACK["Track Order"]
    SUCCESS --> HOME["Home"]
    TRACK --> ERECEIPT["E-Receipt"]
```
