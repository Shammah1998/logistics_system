# Admin Panel Layout Reference Images

This folder contains reference images for the admin panel layouts. These images document the design patterns, layout structure, and UI components to guide implementation.

## Layout Patterns

### 1. Dashboard Structure
- **Layout Pattern**: Three-panel layout (header, sidebar, main content)
- **Header (Top Bar)**:
  - Logo on left
  - Search input field in center (with search icon)
  - Right section: User name, theme toggle icon, user profile icon with dropdown
  - Primary action button (e.g., "+ Add Driver") prominently placed on right
- **Left Sidebar Navigation**:
  - Logo at top of sidebar
  - Collapsible/expandable sections with icons
  - Hierarchical menu structure (main items with sub-items)
  - Active section highlighted with background color
  - Main navigation items: Orders (with sub-items), Customer, Partner
- **Main Content Area**:
  - Takes majority of screen space
  - Scrollable content area
  - Contains data tables, forms, or detail views

### 2. Partner/Driver Management Page
- **Layout Structure**: List view with detail panel
- **Top Section**:
  - Search bar with input field and search button
  - Action buttons above detail panel (Edit, Payment)
- **Data Table**:
  - Columns: Name, Phone, Status, Vehicle, Carrier, Signed Up, Balance
  - Selectable rows (highlighted when selected)
  - Right-pointing arrow on each row indicating expandability
  - Alternating row colors for readability
  - Scrollable table with vertical scrollbar
- **Detail Panel (Below Table)**:
  - Appears when row is selected
  - Tabbed interface: Info, Statement, Payments, Orders
  - Two-column layout within active tab
  - Key-value pairs displaying detailed information
- **Design Pattern**: Master-detail view with table selection revealing details

### 3. Customer Management Page
- **Layout Structure**: Customer list with pricing configuration
- **Top Section - Customer List**:
  - Search bar with phone number input
  - Action buttons: Payment, Charge, Pricing
  - Data table with columns: Name, Phone, Email, Payment, Status, Date Created, Balance
  - Expandable rows with dropdown indicator
- **Bottom Section - Pricing Configuration**:
  - Three-column form layout: Payment, Charge, Pricing
  - Each column contains:
    - Multiple labeled input fields
    - Numeric inputs with increment/decrement buttons
    - Dropdown selectors
  - Action buttons at bottom: "Add Pricing" (primary), "Show Pricing Table" (secondary)
- **Alternative View - Pricing Tables**:
  - Two sections: "Custom Pricing" and "Default Pricing"
  - Each section has a data table
  - Custom Pricing table includes Actions column (edit, delete icons)
  - Columns: Vehicle Type, Base Rate, Base Distance, Extra KM, Actions
- **Design Pattern**: List view with expandable configuration forms

### 4. Orders List Pages (Multiple Variants)
- **Layout Structure**: Table view with expandable detail sections
- **Search Bar**: Order number search input in header or main content area
- **Data Table**:
  - Columns: Status, Client, Time, Pickup, Dropoff, Vehicle, Driver, Amount
  - Status badges (color-coded pills: red for rejected/pending, orange for confirmed)
  - Right-pointing arrow on each row
  - Selected row highlighted with background color
- **Order Categories**:
  - Filtered views: Ongoing, For Review, All Orders
  - Active filter highlighted in sidebar
- **Expanded Order Details** (when row selected):
  - **Left Section**:
    - Vertical timeline showing order progression stages
    - Circular driver avatar placeholder
    - Timeline events with timestamps
  - **Right Section**:
    - Action buttons (Review, Confirm, Cancel) at top
    - Tabbed interface: Users, Order, Pricing, Route, Documents
    - Form-like display with key-value pairs
    - Multi-line text fields for notes
- **Design Pattern**: Expandable table rows with comprehensive detail view

### 5. Order Detail/Review Page
- **Layout Structure**: Split view with timeline and detailed information
- **Left Panel**:
  - Order status timeline (vertical)
  - Driver information card with circular avatar
  - Chronological event list with timestamps
- **Right Panel**:
  - Action buttons (primary actions)
  - Tabbed content area
  - Detailed form fields organized by category
  - User information, order details, pricing breakdown, route info, documents
- **Design Pattern**: Information-rich detail view with chronological tracking

## Common UI Components

### Header Component
- **Structure**: Full-width horizontal bar
- **Left**: Brand logo
- **Center**: Search input field (context-specific: phone number, order number)
- **Right**: User info, theme toggle, profile menu, primary action button
- **Primary Actions**: Prominent buttons for key operations (e.g., "+ Add Driver")

### Sidebar Navigation
- **Structure**: Vertical navigation panel on left
- **Top**: Logo placement
- **Navigation Items**:
  - Expandable sections with icons and caret indicators
  - Sub-items indented below parent items
  - Active item highlighted with background color
  - Icons accompany main navigation items
- **Visual Hierarchy**: Clear distinction between main sections and sub-items

### Data Tables
- **Structure**: Sortable columns with clear headers
- **Row Features**:
  - Selectable rows (highlight on selection)
  - Expandable rows (arrow indicator)
  - Alternating row colors
  - Hover states
- **Status Indicators**: Color-coded badge/pill components
- **Action Indicators**: Arrow icons suggesting expandability or navigation
- **Scrollable**: Vertical scrollbar for long lists

### Detail Panels
- **Structure**: Appears below or beside selected table row
- **Tabbed Interface**: Multiple tabs for organizing information categories
- **Layout**: Two-column or single-column form layout
- **Content Types**:
  - Key-value pairs
  - Form inputs
  - Action buttons
  - Timeline components

### Form Components
- **Multi-Column Forms**: Three-column layout for related input groups
- **Numeric Inputs**: With increment/decrement buttons
- **Dropdown Selectors**: For categorical data
- **Action Buttons**: Primary (dark/colored) and secondary (light/outlined) buttons
- **Labeled Inputs**: Clear labels above or beside inputs

### Timeline Component
- **Structure**: Vertical list of chronological events
- **Visual Elements**:
  - Circular indicators for events
  - Connecting lines between events
  - Timestamp labels
- **Layout**: Top-to-bottom chronological order
- **Usage**: Order status progression, activity history

### Search and Filter
- **Search Input**: Text field with search icon/button
- **Placeholder Text**: Context-specific (phone number, order number)
- **Search Button**: Icon button or colored button for triggering search

## Design Patterns

### Layout Principles
- **Three-Panel Structure**: Header (top), Sidebar (left), Main Content (right)
- **Master-Detail Pattern**: List view with expandable detail panel
- **Tabbed Organization**: Multiple information categories within detail views
- **Progressive Disclosure**: Summary in table, details on selection

### Color Usage
- **Status Badges**: 
  - Red for rejected/pending/negative states
  - Orange for confirmed/pending review
  - Green for active/positive states
- **Background**: White for main content, light grey for sidebar
- **Accents**: Dark colors for primary actions, blue for active states
- **Row Highlighting**: Light background color for selected rows

### Interaction Patterns
- **Row Selection**: Click row to select and reveal details
- **Expandable Sections**: Click to expand/collapse navigation sections
- **Tab Navigation**: Click tabs to switch information categories
- **Search**: Real-time or button-triggered search functionality
- **Action Buttons**: Clear primary and secondary action hierarchy

### Information Architecture
- **Hierarchical Navigation**: Main sections with sub-categories
- **Contextual Actions**: Action buttons relevant to current view
- **Grouped Data**: Related information grouped in columns or sections
- **Clear Visual Hierarchy**: Active states, selected items, and primary actions clearly distinguished

### Data Presentation
- **Table-First Approach**: Lists displayed as tables for efficient scanning
- **Detail on Demand**: Comprehensive details revealed when item selected
- **Status at a Glance**: Color-coded badges for quick status recognition
- **Chronological Tracking**: Timeline components for order/activity progression

## Implementation Notes

- **Responsive Design**: Sidebar may collapse on smaller screens
- **Scrollable Areas**: Tables and content areas have independent scrolling
- **Theme Support**: Theme toggle icon suggests dark/light mode support
- **Accessibility**: Clear visual indicators, readable text, sufficient contrast
- **Data Format**: Dates, times, and currency formatted consistently

