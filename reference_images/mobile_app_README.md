# Mobile App Layout Reference Images

This folder contains reference images for the mobile application layouts. These images document the design patterns, layout structure, and UI components to guide implementation.

## Layout Patterns

### 1. Login Screen
- **Layout Structure**: Centered form on white background
- **Header**: Title "Log in" prominently displayed
- **Form Elements**:
  - Phone number input with country code selector (flag icon, country code, dropdown)
  - PIN input field
  - Primary action button "Sign in"
- **Input Field Design**:
  - Rounded rectangular fields
  - Labels above inputs
  - Placeholder text
  - Light grey background for input fields
- **Design Pattern**: Minimalist vertical form layout with clear hierarchy

### 2. Map-Based Destination Selection
- **Layout Structure**: Full-screen map with bottom sheet overlay
- **Map View**:
  - Takes majority of screen space
  - Google Maps integration
  - Current location indicator (blue circle with white dot)
  - Destination marker (purple teardrop pin)
  - Road labels and points of interest
  - Map controls (compass/target icon in bottom-right)
- **Top Navigation**:
  - Back arrow icon
  - Hamburger menu icon
  - Status bar with time and system icons
- **Bottom Sheet**:
  - White rounded card overlaying map
  - Destination name/title
  - Price/fare information
  - Search/edit icon
  - Primary action button "Confirm destination"
- **Design Pattern**: Map-centric interface with contextual action panel

### 3. Map View with Location Marker
- **Layout Structure**: Full-screen map with bottom navigation
- **Map Features**:
  - Detailed street view with roads and landmarks
  - Location marker (blue circle with white dot)
  - Route visualization (colored lines)
  - Road labels and points of interest
- **Bottom Navigation Bar**:
  - Four navigation icons (Home, Orders, Earnings, More)
  - Active tab highlighted
  - Icon labels below icons
- **Design Pattern**: Persistent navigation with map as primary content

### 4. Orders List - Completed Orders
- **Layout Structure**: Header, summary card, scrollable list, bottom navigation
- **Header**:
  - Dark blue background
  - Title "Orders" centered
  - Status bar with time and system icons
- **Summary Section**:
  - Light grey card
  - "Number of orders" label
  - Large numeric count display
- **Order List Items**:
  - Each item has:
    - Circular icon placeholder (left)
    - Order ID (alphanumeric)
    - "Amount earned" with numeric value
    - Status badge "Delivered" (green, right-aligned)
  - Scrollable vertical list
- **Bottom Navigation**: Four-tab navigation bar
- **Design Pattern**: List view with summary statistics and status indicators

### 5. Orders List - Ongoing and Completed
- **Layout Structure**: Categorized list view
- **Section Organization**:
  - "Ongoing Orders" section
  - "Completed orders" section
- **Ongoing Order Item**:
  - Order ID
  - Timestamp
  - Status badge "confirmed" (orange/yellow)
  - Blue dot indicator
  - Right arrow icon (navigation)
- **Completed Orders**:
  - Summary card with count
  - List of completed orders (same structure as image 4)
- **Design Pattern**: Categorized list with different status types

### 6. Ongoing Order Detail View
- **Layout Structure**: Header, progress indicator, step list
- **Header**:
  - Back arrow (left)
  - Title "Ongoing Order" (center)
  - Order ID badge (right, pill-shaped)
- **Progress Indicator**:
  - Text showing "X/Y steps completed"
  - Horizontal progress bar
- **Step List**:
  - Each step has:
    - Colored circle icon (left)
    - Step label (e.g., "Pick up", "Drop off")
    - Status badge "Pending" (right)
    - Location name (large, bold)
    - Right arrow icon (navigation)
  - Visual distinction: Active steps (orange), inactive steps (grey)
- **Design Pattern**: Step-by-step progress tracking with visual indicators

### 7. Map with Pickup Location and Action
- **Layout Structure**: Full-screen map with bottom sheet
- **Map View**:
  - Detailed street map
  - Route highlighted (red line)
  - Location marker (blue teardrop pin)
  - Roads and landmarks labeled
- **Bottom Sheet**:
  - Location pin icon and location name
  - "Pick up" label
  - Client details section:
    - Client name
    - Phone number
  - Primary action button "PICK THE ORDER" (dark blue, with arrow icon)
- **Design Pattern**: Contextual action sheet with map visualization

### 8. Document Upload Screen
- **Layout Structure**: Centered content with clear instructions
- **Header**: Title "Document Upload"
- **Content**:
  - Instruction text: "Please take a photo of the signed / stamped document"
  - "Take picture" button:
    - Light grey border, white background
    - Camera icon (left)
    - Text label
  - "Submit Images" button:
    - Dark blue/navy background
    - White text
    - Centered
- **Design Pattern**: Single-purpose screen with clear call-to-action

### 9. Payments/Earnings Screen
- **Layout Structure**: Header, balance card, navigation list, bottom nav
- **Header**: Dark blue bar with title "Payments"
- **Balance Card**:
  - White card with rounded corners
  - "Account balance" label (centered)
  - Large numeric display with currency
- **Navigation List**:
  - "My Statements" item with right arrow
  - "Payments" item with right arrow
  - List-item pattern with navigation indicators
- **Bottom Navigation**: Four-tab bar with "Earnings" active
- **Design Pattern**: Financial overview with navigation to details

### 10. Account Statement Screen
- **Layout Structure**: Header, scrollable transaction list
- **Header**:
  - Back arrow (left)
  - Title "Account Statement" (center)
  - Light grey background
- **Transaction List**:
  - Each transaction item has:
    - Circular icon (left) with colored triangle:
      - Green upward triangle (credit/positive)
      - Red downward triangle (debit/negative)
    - Transaction title (bold)
    - Sub-description/reference
    - Amount (right-aligned, color-coded)
    - Date and time (below amount)
  - Scrollable vertical list
- **Design Pattern**: Financial transaction list with color-coded indicators

### 11. Payment Detail View
- **Layout Structure**: Header, single transaction detail card
- **Header**: Back arrow and title "Payments"
- **Transaction Card**:
  - White card background
  - Left icon (colored circle with triangle)
  - Transaction details (left-aligned):
    - Service name
    - Transaction type and recipient
  - Amount and date (right-aligned, color-coded)
- **Design Pattern**: Detailed single-item view

### 12. Profile/More Screen
- **Layout Structure**: Header, profile section, action list, bottom nav
- **Header**: Title "More"
- **Profile Section**:
  - Circular avatar (dark blue with initial)
  - Name (large font)
  - Phone number (smaller font)
- **Action List**:
  - "Get Help" item with icon and right arrow
  - "Log Out" item with icon and right arrow
  - List-item pattern
- **Version Info**: App version displayed at bottom
- **Bottom Navigation**: Four-tab bar with "More" active
- **Design Pattern**: User profile with settings/actions

## Common UI Components

### Header Component
- **Structure**: Horizontal bar at top
- **Variants**:
  - Dark blue background with white text
  - Light grey background with dark text
- **Elements**:
  - Back arrow (left)
  - Title (center)
  - Optional badge/indicator (right)
- **Status Bar**: System status bar above header (time, network, battery)

### Bottom Navigation Bar
- **Structure**: Fixed horizontal bar at bottom
- **Design**: Dark blue or white background
- **Elements**: Four icons with labels
- **Active State**: Highlighted background/color for active tab
- **Icons**: Home, Orders/Packages, Earnings/Payments, More/Grid

### Input Fields
- **Design**: Rounded rectangular, light grey background
- **Structure**: Label above, placeholder text inside
- **Special Types**:
  - Phone input with country code selector (flag, code, dropdown)
  - PIN input (secure entry)
- **Styling**: Clear borders, adequate padding

### Buttons
- **Primary Button**:
  - Dark blue/navy background
  - White text
  - Full-width or prominent placement
  - May include icon (left side)
- **Secondary Button**:
  - Light grey border, white background
  - Dark text
  - Icon and text combination

### Status Badges
- **Design**: Pill-shaped, rounded corners
- **Colors**:
  - Green for "Delivered"/positive states
  - Orange/yellow for "Pending"/"confirmed"
  - Red for negative/rejected states
- **Placement**: Right-aligned in list items

### Cards
- **Design**: White background, rounded corners
- **Usage**: Summary information, balance display, content grouping
- **Styling**: Light grey for summary cards, white for content cards

### List Items
- **Structure**: Horizontal layout with icon, content, action
- **Elements**:
  - Left icon/avatar
  - Main content (title, subtitle)
  - Right element (badge, arrow, amount)
- **Interaction**: Tappable with visual feedback

### Map Components
- **Map View**: Full-screen or large portion of screen
- **Markers**:
  - Blue circle with white dot (current location)
  - Purple/blue teardrop pin (destination)
- **Controls**: Compass/target icon for map controls
- **Integration**: Google Maps

### Bottom Sheet
- **Design**: White rounded card overlaying map
- **Structure**: Slides up from bottom
- **Content**: Contextual information and actions
- **Styling**: Rounded top corners, shadow/elevation

### Progress Indicators
- **Progress Bar**: Horizontal bar showing completion
- **Text**: "X/Y steps completed"
- **Visual**: Filled portion indicates progress

### Timeline/Step List
- **Structure**: Vertical list of steps
- **Visual Elements**:
  - Colored circles (left) for step status
  - Step labels
  - Status badges
  - Location names (prominent)
  - Navigation arrows
- **Color Coding**: Active (orange), inactive (grey)

### Transaction List Items
- **Structure**: Icon, details, amount, date
- **Icon Design**: Circular with colored triangle
  - Green upward triangle (credit)
  - Red downward triangle (debit)
- **Layout**: Left-aligned details, right-aligned amount/date
- **Color Coding**: Green for credits, red for debits

## Design Patterns

### Color Usage
- **Primary**: Dark blue/navy for headers, primary buttons, active states
- **Background**: White for content, light grey for cards/summaries
- **Status Colors**:
  - Green for delivered/credit/positive
  - Orange/yellow for pending/confirmed
  - Red for rejected/debit/negative
- **Text**: Dark for primary text, grey for secondary

### Layout Principles
- **Full-Screen Maps**: Map takes majority of screen for location-based screens
- **Bottom Sheets**: Contextual actions and information overlay maps
- **List-First**: Most screens use list-based navigation
- **Card-Based**: Information grouped in cards for clarity
- **Persistent Navigation**: Bottom nav bar always accessible

### Interaction Patterns
- **Tap to Navigate**: List items, buttons, navigation arrows
- **Bottom Sheet**: Swipe up/down for contextual panels
- **Map Interaction**: Tap markers, pan/zoom map
- **Form Submission**: Primary button for actions
- **Back Navigation**: Back arrow in header

### Information Architecture
- **Hierarchical Navigation**: Main sections → Detail views
- **Contextual Actions**: Action buttons relevant to current view
- **Status at a Glance**: Badges and color coding for quick recognition
- **Progressive Disclosure**: Summary → Detail views
- **Categorized Lists**: Ongoing vs Completed, etc.

### Mobile-Specific Patterns
- **Touch Targets**: Adequate size for buttons and list items
- **Scrollable Content**: Lists and content areas scroll independently
- **Status Bar Integration**: System status bar visible
- **Bottom Navigation**: Thumb-friendly navigation placement
- **Full-Screen Utilization**: Maps and content use full screen space

## Implementation Notes

- **Map Integration**: Google Maps API for map views
- **Bottom Navigation**: Fixed position, always accessible
- **Status Bar**: System status bar styling (dark/light)
- **Currency Format**: "Ksh" prefix for amounts
- **Date Format**: "DD MMM YYYY HH:MM" or similar
- **Responsive Design**: Optimized for mobile screens
- **Touch Interactions**: Adequate spacing and touch targets
- **Dark/Light Themes**: Support for both themes (status bar indicators)
- **Navigation**: Stack-based navigation with back button support

