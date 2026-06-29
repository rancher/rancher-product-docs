/*
 * Automatically configures all external hyperlinks within the article body 
 * to open in a new browser tab. Applies secure 'rel' attributes to prevent 
 * reverse tab vulnerabilities: https://cwe.mitre.org/data/definitions/1022.html.
 */
(function () {
  'use strict'

  document.addEventListener('DOMContentLoaded', function () {
    // Select all links within the main documentation article body
    var links = document.querySelectorAll('.article a, .doc a');
    
    links.forEach(function (link) {
      // Check if the link is external (starts with http/https and points to a different domain)
      if (link.hostname && link.hostname !== window.location.hostname) {
        link.setAttribute('target', '_blank');
        link.setAttribute('rel', 'noopener noreferrer'); // Recommended security practice
      }
    });
  });
})()