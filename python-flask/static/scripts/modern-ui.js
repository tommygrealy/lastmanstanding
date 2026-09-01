document.addEventListener('DOMContentLoaded', function () {
    const menuToggle = document.querySelector('[data-menu-toggle]');
    const menu = document.querySelector('[data-menu]');

    if (menuToggle && menu) {
        menuToggle.addEventListener('click', function () {
            const isOpen = menu.classList.toggle('open');
            menuToggle.setAttribute('aria-expanded', String(isOpen));
        });

        menu.addEventListener('click', function () {
            if (window.innerWidth < 768) {
                menu.classList.remove('open');
                menuToggle.setAttribute('aria-expanded', 'false');
            }
        });
    }
});
