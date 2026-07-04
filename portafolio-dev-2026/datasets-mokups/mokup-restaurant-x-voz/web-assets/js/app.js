document.addEventListener('DOMContentLoaded', () => {
  console.log('App Loaded');

  // Initialization: Theme Preference
  const savedTheme = localStorage.getItem('theme') || 'dark';
  document.documentElement.setAttribute('data-theme', savedTheme);

  // Expose global functions for the UI
  window.toggleTheme = function(e) {
    if(e) e.preventDefault();
    const currentTheme = document.documentElement.getAttribute('data-theme');
    const newTheme = currentTheme === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('theme', newTheme);
  };

  window.toggleMenu = function(e) {
    if(e) e.preventDefault();
    const menu = document.getElementById('side-menu');
    const overlay = document.getElementById('side-menu-overlay');
    if (menu && overlay) {
      menu.classList.toggle('active');
      overlay.classList.toggle('active');
    }
  };

  window.logout = function(e) {
    if(e) e.preventDefault();
    alert('Cerrando sesión...');
    // Real redirection would happen here
  };

  // Mic Button Logic for PWA Mesero
  const micBtn = document.getElementById('btn-mic');
  const transBox = document.getElementById('transcription-text');
  
  if (micBtn && transBox) {
    let isRecording = false;
    let transcriptionInterval;
    
    const sampleTexts = [
      "Mesa ",
      "cinco, ",
      "dos tacos ",
      "al pastor ",
      "con todo, ",
      "y una coca."
    ];

    micBtn.addEventListener('mousedown', startRecording);
    micBtn.addEventListener('touchstart', startRecording);
    
    micBtn.addEventListener('mouseup', stopRecording);
    micBtn.addEventListener('touchend', stopRecording);

    function startRecording(e) {
      e.preventDefault();
      if(isRecording) return;
      isRecording = true;
      micBtn.classList.add('active');
      transBox.innerHTML = '<span style="color:var(--text-secondary)">Escuchando...</span>';
      
      let i = 0;
      transBox.innerHTML = '';
      transcriptionInterval = setInterval(() => {
        if(i < sampleTexts.length) {
          transBox.innerHTML += sampleTexts[i];
          i++;
        }
      }, 400);
    }

    function stopRecording(e) {
      e.preventDefault();
      isRecording = false;
      micBtn.classList.remove('active');
      clearInterval(transcriptionInterval);
    }
  }

  // KDS Timers Logic
  const timers = document.querySelectorAll('.kds-timer');
  if (timers.length > 0) {
    setInterval(() => {
      timers.forEach(timer => {
        let timeParts = timer.innerText.split(':');
        let mins = parseInt(timeParts[0]);
        let secs = parseInt(timeParts[1]);
        
        secs++;
        if (secs >= 60) {
          secs = 0;
          mins++;
        }
        
        timer.innerText = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
        
        // Update Card Color Status dynamically based on minutes
        const card = timer.closest('.kds-card');
        if (mins >= 10 && mins < 20) {
          card.classList.remove('danger');
          card.classList.add('warning');
        } else if (mins >= 20) {
          card.classList.remove('warning');
          card.classList.add('danger');
        }
      });
    }, 1000);
  }
});
