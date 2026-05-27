# Heritage Harvest Ranch — Website Project Specification

## Overview

A static marketing site for Heritage Harvest Ranch (Basin, WY). The site advertises the ranch’s products and routes order inquiries to `sales@heritageharvestranch.com` via `mailto:` links pre-populated with product context. There is no e-commerce, no cart, no customer accounts, no third-party form service. The architecture is intentionally simple and designed to migrate cleanly to Shopify (or another e-commerce backend) when product volume justifies it.

**Stack:** Jekyll + GitHub Pages (with Actions for build) + Alpine.js (used sparingly, only where needed)

**Monetization model (current):** Direct sales via email inquiry. Each product page has an “Email to Order / Inquire” button that opens the customer’s email client with the subject line, product details, and a structured template pre-filled. The customer fills in the blanks and sends. The ranch responds with pricing, pickup, and payment details.

**Monetization model (future):** Migrate the “Order” CTA on each product page to a Shopify Buy Button or full Shopify storefront. The product YAML schema includes optional Shopify-specific fields so the migration is data-only, not architectural.

-----

## Data Schema

### Site Settings (`_config.yml` + `_data/site.yml`)

Standard Jekyll `_config.yml` for build settings. Ranch-specific content (address, phone, email, hours, social links, hero copy) lives in `_data/site.yml` so it can be edited without touching layouts.

```yaml
# _data/site.yml
ranch:
  name: Heritage Harvest Ranch
  tagline: "Premium alfalfa hay from the Big Horn Basin"
  location:
    # Public-facing location only. Exact street address is intentionally
    # omitted and shared with customers directly during order coordination.
    city: Basin
    state: WY
    county: Big Horn County
  contact:
    sales_email: sales@heritageharvestranch.com
    info_email: info@heritageharvestranch.com
    phone: ""                                       # add when published
  hours:
    note: "By appointment. Call or email to schedule pickup."
  social:
    facebook: ""
    instagram: ""
  formspree:
    # Two endpoints, routed by intent:
    #   sales_endpoint    -> sales@heritageharvestranch.com (order forms on product pages)
    #   contact_endpoint  -> info@heritageharvestranch.com  (general contact form)
    sales_endpoint: "mkoepevw"
    contact_endpoint: "xkoepeqw"
```

### Product (`_data/products/` directory, one YAML file per category)

Organize by category file (`hay.yml`, and add more files like `firewood.yml` later if the catalog expands) so adding a new category is a new file rather than editing one large file.

```yaml
# _data/products/hay.yml
- id: alfalfa-round-bale
  name: Alfalfa Round Bales
  category: hay
  short_description: "Pivot-irrigated alfalfa in 4x6 round bales, suited for cattle and larger horse operations."
  unit: bale
  approx_weight_lbs: 1100              # 4x6 net-wrapped, varies by moisture and cutting

  # Pricing display
  # Use price_per_unit for fixed pricing, or pricing_note for "call/inquire"
  price_per_unit: null                # null = show pricing_note instead
  pricing_note: "Contact for current season pricing"
  pricing_currency: USD

  # Availability
  in_stock: true
  availability_note: "First cutting available mid-June through July"
  seasonal: true
  season_months: [6, 7, 8, 9, 10]     # numeric months when typically available

  # Media
  image: /assets/images/products/alfalfa-round-bale.jpg
  image_alt: "Round bales of alfalfa hay in a field"
  gallery: []                          # optional additional images

  # Detail content
  highlights:
    - "Established 2024 stand, irrigated by 7-tower center pivot"
    - "Cured and baled on-site in Basin, Wyoming"
    - "4x6 net-wrapped round bales"
    - "Forage analysis available on request"

  # Long-form description (Markdown supported)
  detail: |
    Our alfalfa is grown on pivot-irrigated ground in the Big Horn Basin
    under Wyoming senior water rights. Round bales suit cattle operations,
    larger horse operations, and commercial buyers who can handle and store
    them efficiently.

    Pickup at the ranch in Basin. Buyers are responsible for loading
    equipment (bale spear or grapple). Delivery may be available for larger
    orders within Big Horn County, contact us for arrangements.

  # Optional certifications or attributes (free-form list of strings)
  attributes:
    - "Wyoming-grown"
    - "Pivot-irrigated"

  # Inquiry configuration (drives the mailto template on this product page)
  inquiry:
    enabled: true
    unit_label: "bales"                 # used in subject line and template
    subject_line: "Order Inquiry: Alfalfa Round Bales"   # optional, defaults to "Order Inquiry: {name}"
    # The mailto body is built from a shared template (see Email Inquiry
    # section). Optional product-specific extra prompts can be added here.
    extra_prompts:
      - "Pickup or delivery?"
      - "Preferred pickup date or week?"

  # Future Shopify migration fields (leave empty until needed)
  shopify:
    product_id: null
    variant_id: null
    buy_button_html: null

  # Metadata
  last_updated: 2026-05-27
  display_order: 10                     # lower = displayed first within category
```

### Category (`_data/categories.yml`)

Categories are first-class so they can have their own descriptions, hero images, and ordering on the products page.

```yaml
# _data/categories.yml
- id: hay
  name: Hay & Forage
  description: "Pivot-irrigated alfalfa from the Big Horn Basin."
  hero_image: /assets/images/categories/hay-hero.jpg
  display_order: 10
```

Additional categories can be added as the operation expands. The schema is generic enough that adding a category is one new entry here plus a new YAML file under `_data/products/`.

**Notes on the schema:**

- `id` is the URL slug (`/products/alfalfa-round-bale/`). Keep IDs stable once published, as changing them breaks bookmarks and any indexed search results.
- `price_per_unit: null` + `pricing_note: "Contact for pricing"` is the default pattern for products without a fixed retail price (hay being the obvious case). When you settle on a price, switch `price_per_unit` to a number and leave `pricing_note` empty.
- `in_stock: false` should hide the inquiry button but keep the product page visible (so it can stay indexed for SEO and convert to “notify me when available” later).
- The `shopify` block stays empty until you migrate. Then the build can detect `shopify.buy_button_html` is populated and swap the CTA from the email-inquiry button to the Shopify button.

-----

## Site Architecture

### Directory Structure

```
heritage-harvest-ranch/
├── _config.yml
├── _data/
│   ├── site.yml                  # ranch contact info, hours, settings
│   ├── categories.yml            # product categories
│   └── products/
│       └── hay.yml
├── _includes/
│   ├── head.html
│   ├── nav.html
│   ├── footer.html
│   ├── product-card.html         # reusable product card partial
│   ├── inquiry-button.html       # product-page email-to-order button
│   └── contact-link.html         # general contact email link
├── _layouts/
│   ├── default.html
│   ├── page.html
│   ├── product.html              # individual product page
│   └── category.html             # category landing page
├── _plugins/
│   └── product_pages.rb          # generates /products/<id>/ pages from YAML
├── scripts/
│   └── validate_data.rb          # schema validation for product YAML
├── assets/
│   ├── css/
│   │   └── main.css
│   └── images/
│       ├── products/             # product photos
│       ├── categories/           # category hero images
│       └── ranch/                # ranch lifestyle / hero images
├── pages/
│   ├── index.html                # landing page
│   ├── about.md                  # about the ranch
│   ├── products.html             # products listing (all categories)
│   ├── contact.md                # general contact page
│   ├── terms.md
│   ├── privacy.md
│   └── 404.html
├── .github/
│   └── workflows/
│       └── build.yml             # GitHub Actions: Jekyll build + Pages deploy
├── docs/
│   └── SPEC.md                   # this file
├── Gemfile
└── README.md
```

### Build Pipeline (GitHub Actions)

Same pattern as Success Outdoors. Use Actions rather than the default GitHub Pages build so custom plugins work.

```yaml
# .github/workflows/build.yml
name: Build and Deploy
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - name: Validate product data
        run: ruby scripts/validate_data.rb
      - name: Build site
        run: bundle exec jekyll build
      - name: Deploy to Pages
        uses: actions/deploy-pages@v4
```

### Build-Time Plugin (`_plugins/product_pages.rb`)

One small Ruby plugin that:

1. Reads all files in `_data/products/`
1. Validates required fields (also done by `scripts/validate_data.rb` in CI)
1. Generates an individual page at `/products/<id>/` for each product using the `product` layout
1. Sorts products within each category by `display_order`

Keep this plugin small. It does page generation only. No derived-field computation (the Success Outdoors spec had price-per-calorie and similar calculations; there is no equivalent here).

### Page Descriptions

**Landing Page (`/`):**
Hero image of the ranch with tagline. Featured product card or cards (with only one category at launch, this is a single prominent hay card with a clear “View / Order” CTA). Short “About the ranch” paragraph. Single email-signup form (optional, defer to Phase 2). Footer with full contact info. The hero and featured section are built to handle multiple categories later, but should look intentional and uncluttered with just one.

**About (`/about`):**
Story of the ranch, owners, location, philosophy. Photos. Mention of the property at whatever level of detail you’re comfortable sharing publicly (acreage, general location in Big Horn County, water rights provenance). Avoid showing a property-level map or pin. A general area map of Big Horn County or the Big Horn Basin is fine if useful.

**Products Listing (`/products`):**
Lists all categories in order, with each category showing its products as cards. Each card shows: image, name, short description, price or pricing note, and an “View / Order” link to the product detail page. No filters, no sorting. If the catalog grows past about 20 products, revisit and add simple category filter tabs at the top.

**Category Page (`/products/category/<id>/`):**
Optional in MVP. If included, shows the category hero image, full category description, and that category’s products. Useful for SEO (“alfalfa hay Wyoming” landing).

**Product Detail Page (`/products/<id>/`):**
Hero image (and gallery if provided). Name, category, price or pricing note, availability. Highlights as a short list. Long-form `detail` markdown. **Order / Inquire form** prominently placed, pre-filled with product context. Related products from the same category at the bottom (optional in MVP).

**Contact (`/contact`):**
General contact form (not product-specific). Hours, general location (Basin, WY), phone. Exact address and pickup directions are shared with customers via email after an inquiry. Note that for orders, the product pages are the better route.

**Legal pages (`/terms`, `/privacy`):**
Standard terms of use and a privacy policy. Privacy policy is required because of GA4 cookies. Templates are fine for the PoC, get them reviewed before any real marketing push.

### Client-Side JavaScript Architecture

Use Alpine.js, loaded via CDN, same rationale as Success Outdoors. The only meaningful client-side interactivity is the order form (validation, submit-to-Formspree, success/error states).

```html
<script defer src="https://cdn.jsdelivr.net/npm/alpinejs@3.x.x/dist/cdn.min.js"></script>
```

Form behavior lives in `assets/js/order-form.js` as a single Alpine component that the `order-form.html` include initializes:

```html
<!-- _includes/order-form.html -->
<div x-data="orderForm({
       productId: '{{ include.product.id }}',
       productName: '{{ include.product.name }}',
       quantityLabel: '{{ include.product.order_form.quantity_label }}',
       quantityMin: {{ include.product.order_form.quantity_min | default: 1 }},
       endpointId: '{{ site.data.site.ranch.formspree.sales_endpoint }}'
     })">
  <!-- form fields and submit button bound to Alpine state -->
</div>
```

The general contact form on `/contact` uses an analogous `contactForm()` Alpine component pointed at `site.data.site.ranch.formspree.contact_endpoint`.

Keep the Alpine component under 100 lines. It handles: field state, basic client-side validation (required fields, valid email), POST to Formspree via fetch, and showing success/error UI. No framework, no bundler.

-----

## Form Handling

### Formspree Setup

Two endpoints are already configured on Formspree:

|Purpose        |Endpoint ID|Routes To                                                              |Used By                          |
|---------------|-----------|-----------------------------------------------------------------------|---------------------------------|
|Sales / orders |`mkoepevw` |[sales@heritageharvestranch.com](mailto:sales@heritageharvestranch.com)|Order forms on every product page|
|General contact|`xkoepeqw` |[info@heritageharvestranch.com](mailto:info@heritageharvestranch.com)  |`/contact` page general form     |

Both IDs live in `_data/site.yml` under `ranch.formspree.sales_endpoint` and `ranch.formspree.contact_endpoint`. To rotate or replace an endpoint, change those values in one place.

Enable Formspree’s built-in honeypot (the `_gotcha` hidden field, included in our form payload) on both endpoints. Add reCAPTCHA later if spam gets through. The free tier (50 submissions/month, 1 form) historically applies per account, so two free endpoints share that monthly budget. *Confidence: medium on the exact current free-tier rules, since Formspree’s pricing has shifted a few times. Verify in the Formspree dashboard before launch and upgrade to a paid plan if either form approaches the cap.*

### Integration Approach

Submit forms by POSTing JSON to the Formspree endpoint from inside the Alpine component using the browser’s `fetch()` API. Do not include the `@formspree/ajax` SDK. The SDK uses its own data-attribute system (`data-fs-field`, `data-fs-error`, `data-fs-submit-btn`) to manage form state, which would compete with Alpine doing the same job. One library managing the form is cleaner.

POSTing JSON with `Accept: application/json` tells Formspree to return a JSON response instead of redirecting. That’s what lets the page stay put and show an inline success state.

Sketch of the Alpine component (`assets/js/order-form.js`):

```js
function orderForm(config) {
  return {
    formData: {
      name: '',
      email: '',
      phone: '',
      quantity: config.quantityMin || 1,
      delivery: 'pickup',
      message: '',
      // Hidden context fields, pre-filled from the product page:
      product_id: config.productId,
      product_name: config.productName,
      _subject: `Order Inquiry: ${config.productName}`,
      _gotcha: '',   // Formspree honeypot, must stay empty
    },
    state: 'idle',   // 'idle' | 'submitting' | 'success' | 'error'
    errorMessage: '',

    async submit() {
      this.state = 'submitting';
      this.errorMessage = '';

      try {
        const res = await fetch(`https://formspree.io/f/${config.endpointId}`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: JSON.stringify(this.formData),
        });

        if (res.ok) {
          this.state = 'success';
          if (window.gtag) {
            gtag('event', 'order_form_submitted', {
              product_id: config.productId,
              product_name: config.productName,
            });
          }
        } else {
          const data = await res.json().catch(() => ({}));
          this.errorMessage = (data.errors && data.errors[0]?.message)
            || 'Something went wrong. Please try again or email sales@heritageharvestranch.com directly.';
          this.state = 'error';
        }
      } catch (err) {
        this.errorMessage = 'Network error. Please try again or email sales@heritageharvestranch.com directly.';
        this.state = 'error';
      }
    },
  };
}
```

The general `contactForm()` component is structurally identical with a different field set (name, email, subject, message, `_gotcha`) and the contact endpoint ID.

### Order Form Fields

Every order/inquiry form submits these fields to Formspree:

|Field              |Type    |Required   |Notes                                                     |
|-------------------|--------|-----------|----------------------------------------------------------|
|name               |text    |yes        |                                                          |
|email              |email   |yes        |                                                          |
|phone              |tel     |no         |recommended, helps with order coordination                |
|product_id         |hidden  |yes        |pre-filled from page context                              |
|product_name       |hidden  |yes        |pre-filled, used in email subject                         |
|quantity           |number  |yes        |uses product’s `quantity_label` and `quantity_min`        |
|delivery_preference|select  |conditional|only if `show_delivery_question: true`                    |
|message            |textarea|no         |“Notes, questions, preferred pickup date”                 |
|_subject           |hidden  |yes        |Formspree special field: `"Order Inquiry: {product_name}"`|
|_gotcha            |hidden  |n/a        |Formspree honeypot, must stay empty for valid submissions |

The general contact form on `/contact` is simpler: name, email, subject, message, plus the `_gotcha` honeypot. It submits to the `contact_endpoint` rather than the `sales_endpoint`.

### Spam Protection

- Formspree’s built-in honeypot field (`_gotcha`) for the cheap layer.
- Add Formspree’s reCAPTCHA v3 if spam gets through (requires paid tier).
- Do not use a plain `mailto:` fallback. It exposes the inbox to scrapers.

### Email Routing

Order inquiries route to `sales@heritageharvestranch.com` (endpoint `mkoepevw`). General contact form submissions route to `info@heritageharvestranch.com` (endpoint `xkoepeqw`). This split is already in place at the Formspree side, so no per-product routing logic is needed.

If the catalog later grows to the point where different product categories should route to different inboxes (e.g., hay vs. forestry vs. equipment), Formspree’s paid tiers support conditional routing, or you can add more endpoints to `_data/site.yml` and reference them per category. Defer that decision until volume justifies it.

### Migration Path to Shopify

When ready to move to Shopify:

1. Set up Shopify store and create products matching the YAML catalog.
1. For each migrated product, populate `shopify.buy_button_html` (or `product_id` + `variant_id` if using a custom integration) in the product YAML.
1. Update the product layout to conditionally render the Shopify Buy Button when those fields are populated, falling back to the order form when they aren’t.
1. Migrate products incrementally. Products with conversation-driven pricing (hay being the obvious example) can stay on the contact-form model, while products with stable per-unit retail pricing move to Shopify when added.

The architecture supports a mixed state. No big-bang migration needed.

-----

## Key Design Decisions and Rationale

**Why static Jekyll instead of WordPress, Wix, or Squarespace:**
Zero hosting cost on GitHub Pages. No CMS to maintain or update. Markdown and YAML edits are diffable and revertible via Git. You already have the tooling and habits from Success Outdoors. The tradeoff is that adding a product requires a Git commit rather than logging into a dashboard, which is fine for a small catalog updated occasionally.

**Why Alpine.js instead of vanilla JS or React:**
The only stateful UI is the contact form. Alpine handles that with a few attributes on Jekyll-rendered HTML. Vanilla JS works but means hand-rolling DOM updates. React is massive overkill for one form.

**Why Formspree instead of a backend or Netlify Forms:**
GitHub Pages is static and has no backend. Netlify Forms only works on Netlify-hosted sites. Building a backend (a tiny serverless function on Cloudflare Workers, Lambda, etc.) is more work for no real benefit over Formspree at this stage. Formspree is boring infrastructure that solves exactly this problem.

**Why two Formspree endpoints (sales and contact) instead of one per product:**
Two endpoints cleanly separate “buying intent” (sales inbox) from “general questions” (info inbox) without forcing the sales team to filter. Going further and creating one endpoint per product would multiply Formspree forms unnecessarily, push us past free-tier limits faster, and complicate maintenance. The hidden `product_id` and `product_name` fields plus the `_subject` field already let the sales inbox identify which product a given inquiry is about.

**Why contact-form ordering instead of e-commerce now:**
Current product mix (hay especially) does not have stable retail pricing. Hay is sold by the load, by the season, and often with negotiated delivery. A contact form fits how this business actually works. Eggs and chicken could go on Shopify earlier than hay, but starting with one model across all products is simpler.

**Why generate individual product pages instead of a single-page-app catalog:**
SEO. Each product page is a separately indexable URL with its own title, description, and structured data. Search visibility for terms like “alfalfa hay Basin Wyoming” or “round bales Big Horn County” is the primary driver of organic discovery for a local ranch business.

-----

## Legal

### Privacy Policy (required)

GA4 sets cookies. A privacy policy that discloses cookie use, what data is collected, and how it’s used is required by GA4’s terms of service and by various jurisdictions’ laws. Use a template (e.g., Termly, iubenda’s free generator, or a hand-rolled one). Not optional, but doesn’t need to be lawyer-drafted for the PoC.

### Terms of Use

Standard terms covering: information accuracy (“provided as-is, verify pricing and availability at time of order”), no warranties beyond what’s stated at point of sale, limitation of liability. Again, template-level is fine for launch.

### Order / Sale Terms (separate from Terms of Use)

When a customer submits an order inquiry, the response email (sent manually) should confirm pricing, quantity, pickup or delivery terms, and payment method. The site itself does not need to embed sales terms in the form, since the form is an inquiry rather than a binding order.

-----

## Analytics

### Implementation

**Google Analytics 4:** Add the GA4 script tag to `_includes/head.html`. Free, sufficient for any traffic this site will see.

### Events to Track

- **Page views** (automatic in GA4)
- **Product card clicked** (from products listing or category page)
- **Order form started** (first field focus or first keystroke)
- **Order form submitted successfully**
- **Order form error** (Formspree returned an error or validation failed)
- **Contact form submitted**
- **External link clicked** (Facebook, Instagram, etc., if added later)

Knowing which products draw the most form submissions, and where in the funnel people drop off, is the difference between guessing and managing.

-----

## SEO

### On-Page Basics (MVP)

- Unique `<title>` and meta description per page, generated from YAML data
- Open Graph and Twitter Card meta tags so shared links render with images
- Canonical URLs
- Sitemap (use the `jekyll-sitemap` plugin)
- robots.txt allowing all crawlers

### Structured Data (MVP)

Two Schema.org types matter for a local ranch business:

1. **LocalBusiness** on the home page and contact page. Includes name, general location (Basin, WY, Big Horn County), opening-hours note, contact email, and sameAs links to social profiles. Standard Schema.org LocalBusiness expects a `streetAddress`. Since the exact address is intentionally not public, the `address` block uses `addressLocality` and `addressRegion` only. This reduces the chance of a fully populated Google Knowledge Panel and may slightly weaken local-pack ranking compared to a business with a complete public address, but it’s a deliberate privacy tradeoff and a Google Business Profile (which can use a service-area business setting that hides the street address) is the better venue for local-pack visibility. *Confidence: high on the tradeoff existing, medium on how much it matters for a ranch versus a storefront business.*
1. **Product** on each product detail page. Includes name, description, image, and either `offers.price` (when set) or `offers.availability`. Even without a fixed price, this helps search visibility.

### Local SEO

- Claim and verify the Google Business Profile for Heritage Harvest Ranch. Set it up as a “service-area business” rather than a storefront so the street address can be hidden from the public profile while still feeding Google’s local index.
- Submit the site to Bing Places (same approach if it supports service-area mode).
- Get listed in any Big Horn County or Wyoming agricultural directories that exist (Wyoming Made, Wyoming Beef Council if you do beef later, local Chamber of Commerce, etc.).
- Encourage early customers to leave Google reviews.

This is more about doing things off the site than building things on it. Document it as a launch checklist.

-----

## Image Strategy

Real photography matters far more on a ranch site than on a tech product site. People want to see the actual hay, actual eggs, actual ranch. Stock photos undermine credibility instantly.

- Take product photos in natural light against simple backgrounds (a round bale in a field, hay being baled, the stand at peak bloom, etc.).
- Take a few ranch landscape and lifestyle shots: the pivot in operation, the property from a few angles, the cutting and baling process during haying season.
- Optimize images at build time (use the `jekyll-picture-tag` plugin or pre-process with ImageMagick / Squoosh). Target ~150-300 KB per hero image, smaller for cards.
- Store images in the repo until catalog size or page count makes that painful, then migrate to a CDN.

-----

## MVP Scope (PoC)

For the first deployable version, build only:

1. **Jekyll scaffold**: `_config.yml`, layouts, includes, default styling.
1. **Site data**: `_data/site.yml` populated with real ranch contact info.
1. **One category, one or two products** in YAML. Hay is the starter (and currently only) category.
1. **Landing page**: hero, three featured category cards, footer with contact info. Doesn’t need to be polished, must be responsive.
1. **About page**: real content about the ranch.
1. **Products listing page**: renders all categories and products from YAML.
1. **Product detail pages**: auto-generated by the plugin from YAML. Includes the order form.
1. **Order form**: working, submits to Formspree, routes to `sales@heritageharvestranch.com` (endpoint `mkoepevw`). `_gotcha` honeypot enabled.
1. **General contact form** on `/contact`, submits to Formspree, routes to `info@heritageharvestranch.com` (endpoint `xkoepeqw`).
1. **Legal pages**: privacy policy and terms of use.
1. **GA4**: installed, basic events firing.
1. **Sitemap and robots.txt**.
1. **Schema.org structured data**: LocalBusiness on home page, Product on detail pages.
1. **Data validation script**: catches missing required fields, invalid types, broken image paths.

**Explicitly not in MVP:**

- Blog or news section
- Email newsletter signup
- Online payments
- Customer reviews
- Shopify integration
- Multi-language support
- Search functionality across products
- Category-specific landing pages (if catalog grows, add these)
- Inventory tracking beyond `in_stock: true/false`

-----

## Claude Code Implementation Notes

When using Claude Code to build this, work in this order:

### Phase 1: Scaffold + Foundation

- Initialize Jekyll project with Gemfile, `_config.yml`, default layout, head/nav/footer includes
- Set up the GitHub Actions workflow
- Create `_data/site.yml` with real ranch info
- Build the data validation script (Ruby, runs in CI)
- Create legal page stubs (`terms.md`, `privacy.md`)
- Add GA4 script tag (with a placeholder measurement ID)

### Phase 2: Product Pipeline

- Create the product YAML schema with one real category populated (hay, with one or two round bale entries)
- Build the `product_pages.rb` plugin to generate per-product pages
- Build the `product` layout, the `category` layout, and the `product-card.html` include
- Build the `/products` listing page
- Verify URLs render and pages look reasonable (unstyled is fine at this stage)

### Phase 3: Order Form

- Confirm both Formspree endpoints are active (`mkoepevw` for sales, `xkoepeqw` for contact). They are already created and the IDs are in `_data/site.yml`.
- Build `_includes/order-form.html` with Alpine bindings, hidden product context fields, and the `_gotcha` honeypot.
- Build `assets/js/order-form.js` Alpine component using `fetch()` to POST JSON to the configured endpoint (do not pull in `@formspree/ajax`).
- Test end-to-end: submit a form on a product page, verify the email lands in `sales@heritageharvestranch.com` with the correct subject line and product context.
- Build the general contact form on `/contact` as a parallel `contactForm()` Alpine component pointed at the contact endpoint, and verify email lands in `info@heritageharvestranch.com`.
- Add GA4 event tracking for form interactions (start, submit success, submit error).

### Phase 4: Landing and About

- Build the landing page (hero, featured categories, about teaser, contact footer)
- Write and style the About page
- Add Open Graph and Twitter Card meta tags

### Phase 5: SEO and Polish

- Add `jekyll-sitemap` and verify sitemap.xml generates
- Add Schema.org JSON-LD: LocalBusiness on home, Product on detail pages
- Add real product photos
- Mobile-responsive QA pass at 375px width (iPhone SE)
- Test form submission from a real phone
- Claim Google Business Profile and submit the sitemap to Google Search Console

### Tips for Claude Code sessions

- The Jekyll plugin is Ruby. State that explicitly so Claude Code doesn’t reach for JavaScript.
- For the Alpine component, request “no build step, no bundler, single JS file” so it doesn’t pull in npm dependencies.
- Test the form locally with Formspree’s test mode before deploying.
- The data validation script should check: required fields present, `id` is unique across all product files, `category` matches a defined category in `_data/categories.yml`, `image` path resolves to a real file, `price_per_unit` is either null or a positive number.
- Mobile-first from Phase 1. The form especially should be usable on a phone keyboard without zooming.
- Keep the styling minimal and warm. Heavy parallax, animated heroes, and “modern SaaS” aesthetics are wrong for this brand. Look at examples like small-farm CSAs, family vineyards, and regional ranches for tonal reference.

-----

## Scalability and Future Considerations

Documented here so early decisions don’t block them, not because they belong in the MVP.

**Shopify integration:** Schema already supports it via the `shopify` block on each product. Migration is per-product, not all-or-nothing.

**Blog / news:** Jekyll has `_posts/` out of the box. When ready, add a blog index page, a post layout, and enable RSS via `jekyll-feed`. Useful for SEO and customer updates (cutting schedules, hay availability announcements, forage test results, etc.).

**Email newsletter:** Mailchimp or Buttondown signup embed on the landing page footer. Defer until there’s a reason to email people regularly.

**Customer reviews / testimonials:** Add a `testimonials` data file and a section on the landing page or product pages. Use real customer quotes with their permission. Defer until you have testimonials worth showing.

**Multiple operators / staff accounts:** Not relevant for a single-operator ranch. If the operation grows and multiple people need to update the site without using Git, that’s the point to revisit static vs CMS.

**Internationalization:** Not applicable. Local ranch, local market.

**E-commerce search and filtering:** Not needed until the catalog has 20+ products across enough categories that browsing becomes painful.