# Customer Panel Layout Reference Images

This folder contains reference images for the customer panel layouts. These images document the design patterns, layout structure, and UI components to guide implementation.

## Layout Patterns

### 1. Orders/Transactions List Page
- **Layout Structure**: Full-width dashboard with header, navigation, and main content area
- **Header Component**: 
  - Logo on left
  - Contact/helpline info in center
  - User info and menu dropdown on right
- **Navigation**: Breadcrumb trail showing current page location
- **Main Content**:
  - Data table with sortable columns (Transaction ID, Status, Date, Amount, From, To)
  - Expandable rows for detailed view
  - Action button (e.g., Download CSV) in top-right of table area
- **Expandable Row Details**:
  - Two-column layout within expanded section
  - Left: Order summary (amount, status, distance, requester info, pickup/dropoff locations, delivery count, tracking link)
  - Right: Driver information card with circular avatar placeholder
- **Status Indicators**: Color-coded badges (e.g., Pending, Delivered)
- **Visual Hierarchy**: Table rows with hover states, expandable sections with clear separation

### 2. Order Tracking Page
- **Layout Structure**: Split-screen layout (left panel + right map)
- **Left Panel**:
  - Order information card with key details (order number, amount, status, locations, date)
  - Vertical timeline component showing order events with timestamps
  - Timeline uses circular indicators with connecting lines
- **Right Panel**:
  - Full-height interactive map
  - Map type toggle buttons (Map/Satellite) in top-left of map
  - Route visualization: two markers connected by line
  - Standard map controls (zoom, fullscreen, street view)
- **Design Pattern**: Information-dense left panel, visual/spatial right panel

### 3. Place Order Page (Multiple Variants)
- **Layout Structure**: Split-screen layout (form on left, map on right)
- **Left Panel - Form Structure**:
  - Map type toggle tabs at top
  - Location input fields (pickup and destination)
  - "Add Destination" action link with icon
  - Vehicle size selection buttons (Small, Medium, Large) - horizontal button group
  - Vehicle type list with icons, names, and pricing
  - Tabbed sections for additional details (Notes, Manifest, Schedule)
  - Text area for notes input
  - Primary action button at bottom (Place Order)
- **Right Panel**:
  - Interactive map taking majority of screen space
  - Map markers indicating selected locations
  - Fullscreen toggle icon in top-right corner
- **Form Flow**: Top-to-bottom progression from location selection → vehicle selection → additional details → submit

### 4. Location Search Interface
- **Layout Structure**: Split-screen with search panel and map
- **Left Panel**:
  - Map type toggle tabs
  - Search input fields (autocomplete enabled)
  - Dropdown search results list with:
    - Icon indicators (map pins)
    - Truncated location names
    - Multiple result items
  - Attribution text at bottom ("powered by Google")
- **Right Panel**:
  - Large map display area
  - Single marker pin for selected location
- **Interaction Pattern**: Real-time search with autocomplete, clickable results

## Common UI Components

### Header Component (All Pages)
- **Structure**: Horizontal bar spanning full width
- **Left Section**: Brand logo
- **Center Section**: Contact/helpline information
- **Right Section**: User greeting and menu dropdown button
- **Menu Dropdown**: 
  - Opens on click
  - Contains navigation links with arrow indicators for sub-menus
  - Includes logout option

### Navigation Elements
- **Breadcrumbs**: Text path showing current location in site hierarchy
- **Menu System**: Dropdown menu with main navigation options

### Data Display Components
- **Data Tables**: 
  - Sortable columns
  - Expandable rows
  - Status badges
  - Action buttons
- **Information Cards**: 
  - Grouped related information
  - Clear visual separation
  - Label-value pairs

### Form Components
- **Input Fields**: Text inputs with placeholder text
- **Button Groups**: Horizontal selection buttons (e.g., Small/Medium/Large)
- **Selection Lists**: Vertical list with icons, labels, and secondary info (pricing)
- **Tabs**: Horizontal tab navigation for related content sections
- **Text Areas**: Multi-line input for longer text

### Map Integration
- **Map Container**: Takes significant portion of screen (right side or full width)
- **Map Controls**: 
  - Type toggle (Map/Satellite)
  - Zoom controls
  - Fullscreen toggle
  - Street view option
- **Markers**: Red pin icons for locations
- **Route Visualization**: Lines connecting markers

### Timeline Component
- **Structure**: Vertical list of events
- **Visual Elements**: 
  - Circular indicators
  - Connecting lines between events
  - Timestamp labels
- **Layout**: Chronological order (top to bottom)

## Design Patterns

### Color Usage
- **Primary Colors**: Blue and red for branding
- **Background**: White for main content areas
- **Accents**: Blue for selected/active states
- **Neutral**: Grey for secondary buttons and inactive elements
- **Status Colors**: Distinct colors for different status types

### Layout Principles
- **Split-Screen**: Left panel for controls/forms, right panel for visual content (maps)
- **Full-Width**: Header and navigation span entire width
- **Responsive Sections**: Content areas adapt to available space
- **Visual Hierarchy**: Clear separation between sections using spacing and borders

### Interaction Patterns
- **Expandable Rows**: Click to reveal additional details
- **Tab Navigation**: Switch between related content sections
- **Dropdown Menus**: Click to reveal options
- **Autocomplete Search**: Real-time suggestions as user types
- **Button Selection**: Visual feedback for selected options

### Information Architecture
- **Progressive Disclosure**: Show summary first, details on demand
- **Grouped Information**: Related data grouped in cards/sections
- **Clear Labels**: Descriptive labels for all inputs and data points
- **Action Placement**: Primary actions prominently placed (bottom of forms, top-right of tables)

## Implementation Notes

- **Map Integration**: Uses Google Maps API
- **Date/Time Format**: Standard format (DD/MM/YYYY HH:MM:SS)
- **Currency Display**: Format with currency code prefix
- **Responsive Design**: Layout adapts to different screen sizes
- **Accessibility**: Clear visual indicators, readable text sizes, sufficient contrast
