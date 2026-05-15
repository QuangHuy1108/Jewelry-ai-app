# Jewelry App — Page-by-Page Detailed Description

> This document describes **every screen** in the app, listing all visual elements, components, data sources, interactions, and navigation targets. Designed as input for Google Stitch or any UI generation tool.

---

## Design System Reference

- **Color Tokens**: See `DESIGN.md` → `colors:` section
- **Typography Scale**: SF Pro Display / SF Pro Text — sizes 56px (hero) down to 14px (caption)
- **Interaction**: All buttons use `scale(0.96)` press animation. Pill-shaped (border-radius: 9999px) for CTAs.
- **Surfaces**: Zero elevation/shadow. Use 1px `hairline (#E0E0E0)` borders for card separation.
- **Background**: `canvasParchment (#F5F5F7)` for page backgrounds, `canvas (#FFFFFF)` for card surfaces.

---

## 1. Splash Screen

**Route**: `/splash`  
**File**: `lib/features/splash/screens/splash_screen.dart`

### Layout
- Full white background
- Center: Animated diamond icon inside a soft circular container (90×90px)
- Below icon: "JEWELRY SHOP" text with 4px letter-spacing
- Decorative background leaf icons at top-right and bottom-left corners (5% opacity)

### Behavior
- Fade-in → hold → fade-out animation over 4 seconds
- On complete: Check Firebase Auth state → navigate to Home (if logged in) or Welcome (if not)

---

## 2. Welcome Screen

**Route**: `/welcome`  
**File**: `lib/features/auth/screens/welcome_screen.dart`

### Layout
- Full-screen background image or illustration
- App logo centered
- Welcome title text and subtitle
- Two pill-shaped buttons stacked vertically:
  - **"Sign In"** — dark filled button → navigates to Sign In
  - **"Create Account"** — outlined button → navigates to Sign Up

---

## 3. Onboarding Screen

**Route**: `/onboarding`  
**File**: `lib/features/onboarding/screens/onboarding_screen.dart`

### Layout
- Top 55%: Concave-clipped grey background area with a phone mockup illustration (slides up with fade)
- Bottom 45%: Title (RichText with mixed weights) + description text
- Footer bar: Back button (circle, outlined) | Pagination dots (animated width) | Next button (circle, dark filled)
- Top-right: "Skip" text button (hidden on last page)

### Pages (3 total)
1. "Effortless Jewelry Shopping Experience"
2. "Build Your Perfect Jewelry Box"
3. "Shine Delivered: Quick & Secure Jewelry Shopping"

### Behavior
- PageView with horizontal swipe
- Saves `hasSeenOnboarding` to SharedPreferences → navigates to Sign In

---

## 4. Sign Up Screen

**Route**: `/signup`  
**File**: `lib/features/auth/screens/sign_up_screen.dart`

### Layout
- Header: Back button + "Create Account" title
- Form fields:
  - Full Name (text input)
  - Email (text input)
  - Password (text input with show/hide toggle)
  - Confirm Password (text input with show/hide toggle)
- Checkbox: "I agree to the Terms & Conditions"
- Full-width "Sign Up" pill button (dark)
- Footer: "Already have an account? Sign In" link

### Behavior
- Firebase Auth `createUserWithEmailAndPassword`
- On success → navigate to Verify Code or Complete Profile

---

## 5. Sign In Screen

**Route**: `/signin`  
**File**: `lib/features/auth/screens/sign_in_screen.dart`

### Layout
- Header: Back button + "Welcome Back" title
- Form fields:
  - Email (text input)
  - Password (text input with show/hide toggle)
- "Forgot Password?" link aligned right
- Full-width "Sign In" pill button (dark)
- Divider with "OR"
- Social login buttons row (Google, Apple, Facebook)
- Footer: "Don't have an account? Sign Up" link

### Behavior
- Firebase Auth `signInWithEmailAndPassword`
- On success → navigate to Home

---

## 6. Forgot Password Screen

**Route**: `/forgot-password`  
**File**: `lib/features/auth/screens/forgot_password_screen.dart`

### Layout
- Header: Back button + "Forgot Password" title
- Illustration/icon
- Instruction text: "Enter your email address"
- Email text input field
- Full-width "Send Code" pill button
- Footer: "Remember password? Sign In" link

### Behavior
- Firebase Auth `sendPasswordResetEmail`
- On success → navigate to Verify Code screen

---

## 7. Verify Code Screen

**Route**: `/verify-code`  
**File**: `lib/features/auth/screens/verify_code_screen.dart`

### Layout
- Header: Back button + "Verify Code" title
- Instruction text with email displayed
- 4-digit OTP input fields (auto-focus next on input)
- "Resend Code" countdown timer
- Full-width "Verify" pill button

### Behavior
- Accepts `email` and `isFromForgotPassword` parameters
- On success → New Password screen (if forgot password flow) or Home

---

## 8. New Password Screen

**Route**: `/new-password`  
**File**: `lib/features/auth/screens/new_password_screen.dart`

### Layout
- Header: Back button + "New Password" title
- New Password input (with show/hide toggle)
- Confirm Password input (with show/hide toggle)
- Password strength indicator
- Full-width "Reset Password" pill button

---

## 9. Complete Profile Screen

**Route**: `/profile`  
**File**: `lib/features/auth/screens/complete_profile_screen.dart`

### Layout
- Header: "Complete Your Profile"
- Avatar picker (circular, tap to upload photo)
- Form fields: Name, Phone, Date of Birth, Gender dropdown
- Full-width "Continue" pill button
- "Skip for now" text link

---

## 10. Home Screen (Main Feed)

**Route**: `/` (root)  
**File**: `lib/features/home/screens/home_screen.dart`

### Layout (scrollable column)
1. **HomeHeader** — Logo area + notification bell icon (with badge) + profile avatar
2. **SearchBarWidget** — Pill-shaped search bar (44px height), search icon, "Search catalog..." placeholder, QR scanner icon
3. **OfferBanner** — Auto-scrolling carousel of promotional banners from Firestore
   - Each banner: Full-width image card with title, subtitle, and "Shop Now" CTA button
   - Pagination: SmoothPageIndicator dots below carousel
4. **CategoryList** — Section header "Catalog Collections" + "Browse All" link
   - Horizontal scrollable list of pill-shaped category chips (streamed from Firestore)
5. **ProductGrid** (Best Sellers) — Section header "Best Sellers" + "Browse All" link
   - 2-column vertical grid of `ProductCard` widgets (data from Firestore)
6. **PopularProductsSection** (Trending Items) — Section header "Trending Items" + "Browse All" link
   - Horizontal scrollable list of `ProductCard` widgets (165px wide, 260px container height)

### Product Card (shared component)
- Outer: White card with 18px border-radius, 1px hairline border, 12px padding
- Inner: 1:1 aspect-ratio image (8px border-radius, canvasParchment background)
- Overlay: 32px translucent circular favorite button (top-right of image)
- Below image: Product name (14px, w600), Price (14px, w400), "Buy" text (13px, Action Blue)
- Interaction: scale(0.96) tap animation, navigates to Product Detail

### Bottom Navigation Bar
- 5 tabs: Home, Cart, AI Scan (center, prominent), Wishlist, Profile
- Active tab: Action Blue icon + label; Inactive: muted grey

---

## 11. Category Screen

**Route**: push navigation (dynamic)  
**File**: `lib/features/category/screens/category_screen.dart`

### Layout
- Header: 44px circle back button + centered category name (17px, w600) + 44px spacer
- Body: 2-column `ProductCard` grid (streamed from Firestore, filtered by category)
- Fade-in + slide-up entry animation per card

---

## 12. Best Seller Screen

**Route**: push navigation  
**File**: `lib/features/product/screens/best_seller_screen.dart`

### Layout
- Header: Back button + "Best Sellers" centered title
- Body: 2-column `ProductCard` grid (Firestore stream)
- Loading: Shimmer placeholder grid
- Empty: Icon + "No best sellers found" + "Refresh" pill button
- Staggered fade-in animation per card

---

## 13. Popular Products Screen

**Route**: push navigation  
**File**: `lib/features/product/screens/popular_products_screen.dart`

### Layout
- Identical structure to Best Seller Screen
- Header title: "Popular Products"
- Data source: `getPopularProductsStream()`
- Loading: Shimmer placeholder (uses shimmer package)

---

## 14. Product Detail Screen

**Route**: `/product`  
**File**: `lib/features/product/screens/product_detail_screen.dart`

### Layout (scrollable)
1. **TopBarSearch** — Overlay search bar + back button + share/cart icons
2. **Image Gallery** — Full-width PageView of product images/videos
   - Dot indicators below
   - Tap to open `FullScreenGallery`
   - Video items use `ProductVideoPlayer`
3. **Primary Info Card** — Product name (28px, w600), category, rating stars, review count
4. **Price Row** — Base price display with discount price if applicable
5. **SizeSelector** — Horizontal pill chips for available sizes (6, 7, 8, 9, 10)
6. **Purity/Material Selector** — Pill chips (18K, 22K, 24K)
7. **VoucherListWidget** — Horizontal scrollable coupon cards from Firestore
8. **CollapsibleSection** — "Description" expandable text area
9. **CollapsibleSection** — "Specifications" expandable key-value table
10. **RecommendationList** — "Complete Your Set" horizontal product strip (165px cards)
11. **SimilarProductList** — "Similar Products" horizontal product strip (165px cards)

### Bottom Bar (sticky)
- **BottomBarCTA**: Seller avatar + "Chat" button | "Add to Cart" outline button | "Buy Now" filled pill button

---

## 15. Full Screen Gallery

**File**: `lib/features/product/widgets/full_screen_gallery.dart`

### Layout
- Black background, full-screen PageView of images
- Close button (top-left)
- Image counter "1/6" (top-right)
- Pinch-to-zoom support

---

## 16. Review Screen

**Route**: `/review`  
**File**: `lib/features/product/screens/review_screen.dart`

### Layout
- Header: Back button + "Reviews" title + star count
- Overall rating display (large number + stars)
- Rating distribution bars (5★ to 1★)
- Filter chips: All, 5★, 4★, 3★, 2★, 1★
- Review list: Avatar + name + rating + date + review text + images
- FAB: "Write a Review" button → navigates to Leave Review

---

## 17. Leave Review Screen

**Route**: `/leave-review`  
**File**: `lib/features/product/screens/leave_review_screen.dart`

### Layout
- Header: Back button + "Write Review" title
- Product info row (thumbnail + name)
- Star rating selector (5 tappable stars)
- Text area for review body
- Image upload row (tap to add photos)
- "Submit Review" pill button

---

## 18. Seller Profile Screen

**Route**: `/seller-profile`  
**File**: `lib/features/product/screens/seller_profile_screen.dart`

### Layout
- Cover image (30% screen height)
- Floating avatar (overlaps cover by 40px)
- Back button and Chat button on cover
- Seller name (24px, bold)
- Follow / Favorite buttons (pill-shaped)
- Expandable description with "Read more" toggle
- Metrics row: Followers | Favorites | Returning % (with vertical dividers)
- Service Quality section: 5 rating bars (Attitude, Consulting, Knowledge, Honesty, After-sales)
- Best Selling Products: Horizontal product card strip (165px cards, 260px height)

---

## 19. Search Results Screen

**Route**: `/search`  
**File**: `lib/features/search/screens/search_results_screen.dart`

### Layout
- Header: Animated back button + search text field (with clear button)
- Metadata row: "Results for 'query'" + "N Results Found"
- Filter/Sort pill buttons row (Filter | Sort)
- Active filter chips bar (horizontally scrollable, with "Clear All")
- 2-column ProductCard grid
- Skeleton loading grid (4 shimmer placeholders)
- Empty state: "No Results Found" icon + message

### Bottom Sheets
- **AdvancedFilterBottomSheet**: Price range, category checkboxes, material, rating
- **SortBottomSheet**: Popular, Price Low→High, Price High→Low, Newest

---

## 20. Cart Screen

**Route**: `/cart`  
**File**: `lib/features/cart/screens/cart_screen.dart`

### Layout
- AppBar: "My Cart" centered title
- "Select All" checkbox header
- Scrollable item list (each item is a dismissible card):
  - Checkbox + 80×80 product image + Name + Category
  - Size & Purity info
  - Price (with strikethrough original if discounted)
  - Quantity stepper (−/+) with pill border
  - Voucher row: Ticket icon + voucher code + discount amount + chevron (tap to select voucher)
  - Swipe left to reveal delete button
- Checkout Bar (sticky bottom):
  - Promo code text field + "Apply" button
  - Cost breakdown: Sub-Total, Delivery, Tax, Discount, Divider, **Total**
  - Full-width "Proceed to Checkout" pill button

### Empty State
- Shopping bag icon + "Your cart is empty" + "Continue Shopping" button

---

## 21. Checkout Screen

**Route**: `/checkout`  
**File**: `lib/features/checkout/screens/checkout_screen.dart`

### Layout
- AppBar: "Checkout" title
- **Shipping Address** section: Address card with name, street, city, phone + "Change" button
- **Shipping Method** section: Radio-selectable options
  - Insured Premium Delivery (2-3 days, $20)
  - Express Delivery (Next day, $35)
  - Standard Delivery (5-7 days, Free)
- **Order Items** section: Compact product list with thumbnails
- **Voucher** section: Applied voucher display or "Select Voucher" button
- **Payment Method** section: Radio-selectable
  - Credit Card
  - Apple Pay
  - Cash on Delivery
- **Order Summary**: Sub-total, Shipping, Tax, Discount, **Grand Total**
- Full-width "Place Order" pill button

---

## 22. Order Success Screen

**Route**: `/order-success`  
**File**: `lib/features/checkout/screens/order_success_screen.dart`

### Layout
- Animated checkmark icon (green circle)
- "Order Placed Successfully!" title
- Order ID display
- Estimated delivery date
- Two buttons:
  - "Track Order" → Track Order screen
  - "Continue Shopping" → Home

---

## 23. My Orders Screen

**Route**: `/my-orders`  
**File**: `lib/features/checkout/screens/my_orders_screen.dart`

### Layout
- Header: Back button + "My Orders" title
- Tab bar: Active | Completed | Cancelled
- Order cards list:
  - Order ID + date
  - Product thumbnails row
  - Status badge (Processing / Shipped / Delivered)
  - Total amount
  - "Track Order" or "Leave Review" button

---

## 24. Track Order Screen

**Route**: `/track-order`  
**File**: `lib/features/checkout/screens/track_order_screen.dart`

### Layout
- Header: Back button + "Track Order" title
- Order info card (ID, date, items count)
- Delivery timeline (vertical stepper):
  - Order Placed ✓
  - Processing ✓
  - Shipped (current)
  - Out for Delivery
  - Delivered
- Estimated delivery date
- Delivery address card

---

## 25. E-Receipt Screen

**Route**: `/e-receipt`  
**File**: `lib/features/checkout/screens/e_receipt_screen.dart`

### Layout
- Header: Back button + "E-Receipt" title
- Receipt card:
  - Order ID, date
  - Itemized list with prices
  - Divider
  - Sub-total, Shipping, Tax, Discount
  - **Grand Total** (bold)
- "Download PDF" and "Share" buttons

---

## 26. Add Card Screen

**Route**: `/add-card`  
**File**: `lib/features/checkout/screens/add_card_screen.dart`

### Layout
- Header: Back button + "Add New Card" title
- Visual credit card preview (animated, shows input in real time)
- Form fields: Card Number, Cardholder Name, Expiry Date, CVV
- "Save Card" pill button

---

## 27. Wishlist Screen

**Route**: `/wishlist`  
**File**: `lib/features/wishlist/screens/wishlist_screen.dart`

### Layout
- Header: "My Wishlist" title with item count
- Tab bar: All | Jewelry | Accessories (or dynamic categories)
- 2-column ProductCard grid
- Each card has favorite heart (pre-filled red)
- Staggered fade-in animation per card
- Empty state: Heart icon + "Your wishlist is empty"

### Bottom Navigation Bar (same as Home)

---

## 28. AI Scan Screen

**Route**: `/ai-scan`  
**File**: `lib/features/ai_scan/screens/ai_scan_screen.dart`

### Layout
- AppBar: "AI Jewelry Scanner" title
- Image picker box (300px height):
  - Empty state: Camera icon + instructions + Camera/Gallery buttons
  - With image: Full preview + close button overlay
- Loading state: Spinner + "AI is analyzing your jewelry..."
- Result card (on success):
  - "AI Analysis Complete" header with sparkle icon
  - Result rows: Type, Material, Gemstone, Style
  - Estimated Price Range (highlighted gold)
- "Similar Pieces" section: Horizontal ProductCard strip (Firestore query filtered by detected type)
- Bottom: "Analyze Jewelry" full-width button

---

## 29. Camera Scanner Screen

**Route**: `/camera`  
**File**: `lib/features/camera/screens/camera_screen.dart`

### Layout
- Full-screen camera viewfinder
- Scan frame overlay (centered rectangle with corner markers)
- Bottom controls: Flash toggle, capture button, gallery button
- Results overlay when QR/barcode detected

---

## 30. AI Chat Screen

**Route**: `/chat`  
**File**: `lib/features/chat_ai/screens/chat_screen.dart`

### Layout
- AppBar: "AI Assistant" title
- Chat message list (scrollable, bubbles)
- Bottom: Text input field with send button
- Placeholder: "Ask something..." hint

---

## 31. Chat List Screen

**Route**: `/chat-list`  
**File**: `lib/features/chat/screens/chat_list_screen.dart`

### Layout
- Header: "Messages" title
- Search bar for filtering conversations
- Conversation list:
  - Seller avatar (circular) + Seller name + Last message preview + Timestamp
  - Unread message count badge
  - Tap → navigates to Chat Detail

---

## 32. Chat Detail Screen

**Route**: `/chat-detail`  
**File**: `lib/features/chat/screens/chat_detail_screen.dart`

### Layout
- Header: Back button + seller avatar + seller name + online status
- Message list (scrollable):
  - Sent messages (right-aligned, dark bubble)
  - Received messages (left-aligned, light bubble)
  - Product context card (if shared): thumbnail + name + price
  - Timestamps between message groups
- Bottom input bar: Attachment button + text field + send button
- Product context banner (if navigated from product page)

---

## 33. Seller Chat Screen

**File**: `lib/features/chat/screens/seller_chat_screen.dart`

### Layout
- Similar to Chat Detail but from seller's perspective
- Includes quick-reply suggestions
- Product recommendation cards inline

---

## 34. Notification Screen

**Route**: `/notification`  
**File**: `lib/features/notification/screens/notification_screen.dart`

### Layout
- Header: Back button + "Notification Center" title + unread count badge (red pill)
- Grouped sections: 📌 Pinned | ⭐ Recommended | Today | Yesterday | Earlier
- Each notification item:
  - Type icon in circle (shipping/promo/chat, colored)
  - Title (bold if unread) + optional badges (IMPORTANT / RECOMMENDED)
  - Body text (2 lines max)
  - Age string (5m / 2h / 3d)
  - Unread items have slight pink tint background
- Interactions:
  - Tap → navigate to relevant screen (orders/chat)
  - Long-press → mark as read/unread bottom sheet
  - Swipe left → delete (red background, with undo snackbar)
- Floating "New notifications" pill (appears when scrolled down and new items arrive)
- Empty state: "You're all caught up!" with bell-off icon

---

## 35. Coupon Screen

**Route**: push navigation  
**File**: `lib/features/offer/screens/coupon_screen.dart`

### Layout
- Header: Back button + "Available Vouchers" title
- Voucher card list:
  - Left colored strip + discount badge (e.g., "20% OFF")
  - Voucher code + minimum purchase + expiry date
  - "Apply" button
- Returns selected voucher to previous screen

---

## 36. Special Offers Screen

**Route**: push navigation  
**File**: `lib/features/offer/screens/special_offers_screen.dart`

### Layout
- Header: Back button + "Special Offers" title
- Banner cards list (from Firestore):
  - Full-width promotional image
  - Title + description overlay
  - "Shop Now" CTA button

---

## 37. User Profile Screen

**Route**: `/user-profile`  
**File**: `lib/features/profile/screens/user_profile_screen.dart`

### Layout
- Header: Back button + Settings gear icon
- Profile avatar (circular, from Firebase or placeholder)
- User name (from Firestore, real-time stream)
- Menu items list (each is a row with icon + label + chevron):
  - Edit Profile
  - Manage Address
  - Payment Methods
  - My Orders
  - My Wallet
  - My Coupons
  - Settings
  - Help Center
  - Privacy Policy
- "Log Out" button (red accent)

### Bottom Navigation Bar

---

## 38. Edit Profile Screen

**Route**: `/edit-profile`  
**File**: `lib/features/profile/screens/edit_profile_screen.dart`

### Layout
- Header: Back button + "Edit Profile" title
- Avatar with camera overlay button (tap to change photo)
- Form fields: Full Name, Email (disabled), Phone, Date of Birth
- "Save Changes" pill button

---

## 39. Manage Address Screen

**Route**: `/manage-address`  
**File**: `lib/features/profile/screens/manage_address_screen.dart`

### Layout
- Header: Back button + "My Addresses" title
- Address card list:
  - Address label (Home/Work/Other)
  - Full address text
  - Edit / Delete action buttons
  - Default address badge
- FAB: "Add New Address" → Add Address screen

---

## 40. Add Address Screen

**Route**: `/add-address`  
**File**: `lib/features/profile/screens/add_address_screen.dart`

### Layout
- Header: Back button + "Add Address" title
- Form fields: Label, Street, City, State, Zip Code, Country
- "Set as Default" toggle
- "Save Address" pill button

---

## 41. Payment Methods Screen

**Route**: `/payment-methods`  
**File**: `lib/features/profile/screens/payment_methods_screen.dart`

### Layout
- Header: Back button + "Payment Methods" title
- Saved cards list (visual card representation)
- "Add New Card" button → Add Card screen

---

## 42. Wallet Screen

**Route**: `/wallet`  
**File**: `lib/features/profile/screens/wallet_screen.dart`

### Layout
- Header: Back button + "My Wallet" title
- Balance card: Current balance display (large number)
- "Top Up" button → Top Up screen
- Transaction history list:
  - Transaction type icon + description + amount (+/-) + date

---

## 43. Top Up Wallet Screen

**Route**: `/top-up-wallet`  
**File**: `lib/features/profile/screens/top_up_wallet_screen.dart`

### Layout
- Header: Back button + "Top Up" title
- Amount input field
- Quick amount chips ($10, $20, $50, $100)
- Payment method selector
- "Top Up" pill button

---

## 44. Settings Screen

**Route**: `/settings`  
**File**: `lib/features/profile/screens/settings_screen.dart`

### Layout
- Header: Back button + "Settings" title
- Menu sections:
  - **Account**: Password Manager, Notification Settings
  - **App**: Language, Theme (Dark/Light toggle)
  - **Danger Zone**: Delete Account
- Each item: Icon + label + chevron (or toggle switch)

---

## 45. Password Manager Screen

**Route**: `/password-manager`  
**File**: `lib/features/profile/screens/password_manager_screen.dart`

### Layout
- Header: Back button + "Password Manager" title
- Current Password input
- New Password input
- Confirm Password input
- "Update Password" pill button

---

## 46. Notification Settings Screen

**Route**: `/notification-settings`  
**File**: `lib/features/profile/screens/notification_settings_screen.dart`

### Layout
- Header: Back button + "Notification Settings" title
- Toggle switches:
  - Push Notifications
  - Order Updates
  - Promotional Offers
  - Chat Messages
  - Price Drop Alerts

---

## 47. Delete Account Screen

**Route**: `/delete-account`  
**File**: `lib/features/profile/screens/delete_account_screen.dart`

### Layout
- Header: Back button + "Delete Account" title
- Warning icon and message
- Reason selection (radio buttons or checkboxes)
- Password confirmation input
- "Delete Account" red button with confirmation dialog

---

## 48. Help Center Screen

**Route**: `/help-center`  
**File**: `lib/features/profile/screens/help_center_screen.dart`

### Layout
- Header: Back button + "Help Center" title
- Search bar
- FAQ categories (expandable accordion):
  - Orders & Shipping
  - Returns & Refunds
  - Account & Security
  - Payment Issues
- "Contact Support" button

---

## 49. Privacy Policy Screen

**Route**: `/privacy-policy`  
**File**: `lib/features/profile/screens/privacy_policy_screen.dart`

### Layout
- Header: Back button + "Privacy Policy" title
- Scrollable formatted text content
- Sections: Data Collection, Usage, Sharing, Security, Rights, Contact

---

## 50. Location Permission Screen

**Route**: `/location-permission`  
**File**: `lib/features/onboarding/screens/location_permission_screen.dart`

### Layout
- Map/location illustration
- "Enable Location" title + description
- "Allow Location Access" pill button
- "Skip" text link

---

## 51. Enter Location Screen

**Route**: `/enter-location`  
**File**: `lib/features/onboarding/screens/enter_location_screen.dart`

### Layout
- Header: Back button + "Your Location" title
- Map view (Google Maps widget)
- Current location pin
- Address text field (auto-filled from GPS)
- "Confirm Location" pill button

---

## 52. Enable Notification Screen

**Route**: `/enable-notification`  
**File**: `lib/features/onboarding/screens/enable_notification.dart`

### Layout
- Bell/notification illustration
- "Stay Updated" title + description about notification benefits
- "Enable Notifications" pill button
- "Maybe Later" text link

---

## 53. Filter Screen

**File**: `lib/features/filter/screens/filter_screen.dart`

### Layout
- Header: "Filters" title + "Reset" button
- Sections:
  - Price Range (range slider with min/max labels)
  - Categories (chip selection, multi-select)
  - Materials (Gold, Silver, Platinum chips)
  - Rating (star-based minimum selector)
- "Apply Filters" full-width pill button
- "Cancel" text button
