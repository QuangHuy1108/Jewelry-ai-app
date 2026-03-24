# 💎 GlowUp - Luxury Jewelry E-commerce Mobile App

> ✨ *Elevating luxury shopping with AI & AR-powered experiences.*

GlowUp is a **mobile app (iOS & Android)** built with **Flutter + Firebase**, offering a premium jewelry shopping experience with **Luxury-Minimalist** design, smooth performance, and advanced **AI/AR** integration.

---

# 🎯 Product Vision

- 🎨 **Luxury UI:** Minimalist, sophisticated, product-focused
- ⚡ **Seamless UX:** No interruptions, no unnecessary redirects
- 🤖 **AI-first:** Personalized shopping experience
- 🪞 **AR Experience:** Try on jewelry directly via camera

---

# 📱 Tech Stack

| Layer | Technology |
|------|-----------|
| Platform | Flutter (iOS & Android) |
| Backend | Firebase (Auth, Firestore, Storage, Cloud Functions) |
| State Management | Provider |
| AI | Google Gemini, ML Kit |
| AR | ARCore / ARKit |

---

# 🧩 Core Features

## 👤 User Features

### 🔐 Authentication
- Registration/Login (Firebase Auth)
- Personal Profile
- Order History

### 🛍️ Shopping Flow
- **Home:** Banner, Campaign, Featured Products
- **Shop:** Product List
- **Product Detail:**
  - Images, Price, Description
  - Variant: Size, Material, Purity
  - Actions: `Add to Cart`, `Buy Now`

### ❤️ Wishlist
- Save Favorite Products
- Synchronize by User (Firestore)

### 🛒 Cart (Drawer UX)
- Add/Delete/Update Quantity
- Display as Drawer (NO page changes)

### 💳 Checkout
- Enter Address
- Payment
- Order Confirmation

### 🚚 Shipping
- Door-to-door delivery
- Status tracking

### 💬 Support
- AI Chat / Seller
- Contact form

---

## 🛠️ Admin Features

- Role-based access control
- Dashboard (Revenue, orders)
- Product CRUD (Credit, Data)
- Order management

---

## 🤖 AI & AR Features

### 🎯 Visual Experience
- AR Virtual Try-on
- Visual Search
- Image scanning (material, purity)

### 🧠 AI Personal Stylist
- Skin tone analysis
- Face analysis
- Recommendation system

### 🎨 Generative AI
- Jewelry design based on descriptions
- Greeting card generation

### 🔐 Trust & Security
- Diamond certificate scanning
- AI valuation
- Fraud detection

---

# 🏗️ Architecture

## 🧱 Pattern
- Clean Architecture
- Feature-first structure

## 📂 Folder Structure

```text
lib/
├── core/       # Theme, constants, config, utils
├── features/
│   ├── auth/
│   ├── camera/
│   ├── cart/
│   ├── chat_ai/
│   ├── product/
│   ├── wishlist/
│   ├── checkout/
│   └── admin/
├── routers/    # Centralized navigation system
├── shared/     # Reusable widgets/components
└── main.dart   # Entry point
```

---

# ⚙️ Setup Requirements

Follow these steps to set up and run the app in **< 5 minutes**:

1. **Install Dependencies:**
   ```bash
   flutter pub get
   ```
2. **Firebase Configuration:** Ensure the following files are added:
   - `google-services.json` (Android -> `android/app/`)
   - `GoogleService-Info.plist` (iOS -> `ios/Runner/`)
3. **Environment Setup:** Make sure the **Gemini API Key** is correctly configured in your environment or `.env` file.
4. **Run Application:**
   ```bash
   flutter run
   ```

---

# 🚨 BUSINESS LOGIC RULES (DO NOT VIOLATE)

This section contains mandatory rules for Developers and AI Agents to ensure architectural integrity.

## 1. Navigation Rules
### Standard Flow:
`Home` → `Product Detail` → `Cart Drawer` → `Checkout` → `Order Success`

### MANDATORY:
- ❌ **DO NOT** navigate to the `SplashScreen` (incorrect logic).
- ✅ **Back Navigation:** Always use `pop()` to return to the previous screen.
- ❌ **DO NOT** open the Cart with a new page.
- ✅ **Cart UI:** MUST be displayed as a `Drawer` or `BottomSheet`.

### GLOBAL RULE:
👉 Click on a product ANYWHERE (Home, Wishlist, Search):
→ **ALWAYS** open `ProductDetailScreen`.

## 2. State Management Rules
- **Tool:** Use `Provider`.
### Cart:
- Synchronize with Firestore by user.
### Update Flow:
- ⚡ **UI update immediately** (local state).
- 🔄 **Sync server later** (asynchronous).

## 3. Cart & Checkout Rules
### ⚠️ MANDATORY:
The user **must** select:
- Size
- Material

👉 *Before* they can click:
- `Add to Cart`
- `Buy Now`

**If not selected:** → Disable the button.

## 4. Wishlist Rules
- Only display the heart icon as active *after* adding.
- Always sync with Firestore.

**⚠️ Possible errors:**
- Not syncing when switching tabs.
👉 **AI must check:**
- Firestore Listener
- Provider state consistency

## 5. UX Rules (CRITICAL)
- ❌ NO interruption of the shopping flow.
- ✅ Cart Drawer maintains flow.
- ✅ Smooth animations.
- ✅ Consistent, luxury UI.

---

# 🚧 KNOWN ISSUES (MUST BE FIXED)

1. **Back Navigation Errors:** Verify standard `pop()` behavior avoids splash screens.
2. **Wishlist State Synchronization:** State is currently not syncing properly across tabs.

---

> **Note to AI Agent:**
> You are functioning as the Senior Software Architect, Tech Lead, Flutter/Firebase Expert, AI Integration Specialist, and UX/UI Specialist. You must read this README to continue coding *without breaking architecture*, fix bugs logically, adhere to UI/UX rules, and avoid creating incorrect flows.
