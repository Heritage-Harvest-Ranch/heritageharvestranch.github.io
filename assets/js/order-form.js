document.addEventListener('alpine:init', () => {
  Alpine.data('orderForm', (ds) => {
    const quantityMin = parseInt(ds.quantityMin, 10) || 1;
    return {
      formData: {
        name: '',
        email: '',
        phone: '',
        quantity: quantityMin,
        delivery_preference: 'pickup',
        message: '',
        product_id: ds.productId,
        product_name: ds.productName,
        _subject: `Order Inquiry: ${ds.productName}`,
        _gotcha: '',
      },
      state: 'idle',
      errorMessage: '',
      started: false,

      trackStart() {
        if (this.started) return;
        this.started = true;
        if (window.gtag) gtag('event', 'order_form_started', {
          product_id: ds.productId,
          product_name: ds.productName,
        });
      },

      validate() {
        if (!this.formData.name.trim()) return 'Please enter your name.';
        if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.formData.email))
          return 'Please enter a valid email address.';
        if (this.formData.quantity < quantityMin)
          return `Minimum quantity is ${quantityMin}.`;
        return null;
      },

      async submit() {
        const err = this.validate();
        if (err) {
          this.errorMessage = err;
          this.state = 'error';
          if (window.gtag) gtag('event', 'order_form_error', { product_id: ds.productId, error_type: 'validation' });
          return;
        }
        this.state = 'submitting';
        this.errorMessage = '';
        try {
          const res = await fetch(`https://formspree.io/f/${ds.endpointId}`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
            body: JSON.stringify(this.formData),
          });
          if (res.ok) {
            this.state = 'success';
            if (window.gtag) gtag('event', 'order_form_submitted', {
              product_id: ds.productId,
              product_name: ds.productName,
            });
          } else {
            const data = await res.json().catch(() => ({}));
            this.errorMessage = data.errors?.[0]?.message
              || 'Something went wrong. Please try again or email sales@heritageharvestranch.com directly.';
            this.state = 'error';
            if (window.gtag) gtag('event', 'order_form_error', { product_id: ds.productId, error_type: 'server' });
          }
        } catch {
          this.errorMessage = 'Network error. Please try again or email sales@heritageharvestranch.com directly.';
          this.state = 'error';
          if (window.gtag) gtag('event', 'order_form_error', { product_id: ds.productId, error_type: 'network' });
        }
      },
    };
  });
});
