document.addEventListener('alpine:init', () => {
  Alpine.data('contactForm', (ds) => ({
    formData: {
      name: '',
      email: '',
      subject: '',
      message: '',
      _gotcha: '',
    },
    state: 'idle',
    errorMessage: '',

    validate() {
      if (!this.formData.name.trim()) return 'Please enter your name.';
      if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(this.formData.email))
        return 'Please enter a valid email address.';
      if (!this.formData.message.trim()) return 'Please enter a message.';
      return null;
    },

    async submit() {
      const err = this.validate();
      if (err) { this.errorMessage = err; this.state = 'error'; return; }
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
          if (window.gtag) gtag('event', 'contact_form_submitted');
        } else {
          const data = await res.json().catch(() => ({}));
          this.errorMessage = data.errors?.[0]?.message
            || 'Something went wrong. Please try again or email info@heritageharvestranch.com directly.';
          this.state = 'error';
          if (window.gtag) gtag('event', 'contact_form_error', { error_type: 'server' });
        }
      } catch {
        this.errorMessage = 'Network error. Please try again or email info@heritageharvestranch.com directly.';
        this.state = 'error';
        if (window.gtag) gtag('event', 'contact_form_error', { error_type: 'network' });
      }
    },
  }));
});
