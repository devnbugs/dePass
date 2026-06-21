window.laravel = {
    csrfToken: document.querySelector('meta[name="csrf-token"]')?.getAttribute('content'),
    asset: (path) => path,
};
