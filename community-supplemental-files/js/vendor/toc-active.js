// This is a helper script that adds scroll-sync with the right-side TOC menu headers relative to your location in the body content.
window.addEventListener('DOMContentLoaded', () => {
  const observer = new IntersectionObserver(entries => {
    entries.forEach(entry => {
      const id = entry.target.getAttribute('id');
      if (id) {
        // Find the link in the right-hand TOC pointing to this ID
        const tocLink = document.querySelector(`.toc-menu a[href="#${id}"]`);
        
        if (entry.intersectionRatio > 0) {
          // Remove active class from all and add to the current one
          document.querySelectorAll('.toc-menu a').forEach(nav => nav.classList.remove('is-active'));
          tocLink?.classList.add('is-active');
        }
      }
    });
  }, { rootMargin: '-10% 0px -80% 0px' }); // Adjust margins to trigger highlight earlier/later

  // Track all headings that Antora generates with IDs
  document.querySelectorAll('h2[id], h3[id], h4[id]').forEach((section) => {
    observer.observe(section);
  });
});