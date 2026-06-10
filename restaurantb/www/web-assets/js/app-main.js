/**
 * SADM Tlapa - Main Application UI Helpers
 */

$(document).ready(function() {
    // Resaltar elemento de navegación activo
    $('#clutter ul li a').click(function() {
        $('#clutter ul li').removeClass('active');
        // Si no es un enlace externo (como asamblea/)
        if ($(this).attr('target') !== '_blank') {
            $(this).parent().addClass('active');
        }
    });
});

// Setup de cargador global de AJAX
$(document).on('ajaxStart', function() {
    $('#loader-overlay').addClass('active');
});
$(document).on('ajaxComplete', function() {
    $('#loader-overlay').removeClass('active');
});
