// main.js — ExamHub client-side enhancements

// ── Password strength meter (register page only) ──────────────────
(function () {
  const passInput = document.getElementById('pass');
  const meter     = document.getElementById('pwd-meter');
  const bar       = document.getElementById('pwd-bar');
  const label     = document.getElementById('pwd-label');

  if (!passInput || !meter) return;   // not on register page, do nothing

  const rules = [
    { test: (p) => p.length >= 8,                          label: 'At least 8 characters'          },
    { test: (p) => /[A-Z]/.test(p),                        label: 'One uppercase letter'            },
    { test: (p) => /[0-9]/.test(p),                        label: 'One number'                      },
    { test: (p) => /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(p),
                                                            label: 'One special character'           },
    { test: (p) => p.length >= 12,                         label: '12+ characters (strong)'        },
  ];

  const levels = [
    { text: 'Too short',  color: 'var(--red)',   width: '15%'  },
    { text: 'Weak',       color: 'var(--red)',   width: '30%'  },
    { text: 'Fair',       color: 'var(--amber)', width: '55%'  },
    { text: 'Good',       color: 'var(--amber)', width: '72%'  },
    { text: 'Strong',     color: 'var(--green)', width: '90%'  },
    { text: 'Very strong',color: 'var(--green)', width: '100%' },
  ];

  passInput.addEventListener('input', function () {
    const val   = this.value;
    const score = val.length === 0 ? -1 : rules.filter(r => r.test(val)).length;

    if (score < 0) {
      meter.style.display = 'none';
      return;
    }

    meter.style.display = 'block';
    const lvl    = levels[Math.min(score, levels.length - 1)];
    bar.style.width            = lvl.width;
    bar.style.backgroundColor  = lvl.color;
    label.textContent          = lvl.text;
    label.style.color          = lvl.color;

    // Update hint list
    rules.forEach((rule, i) => {
      const li = document.getElementById('pwd-rule-' + i);
      if (!li) return;
      li.style.color = rule.test(val) ? 'var(--green)' : 'var(--ink-muted)';
      li.querySelector('.pwd-rule-icon').textContent = rule.test(val) ? '✓' : '○';
    });
  });
})();

// ── PDF Merger Logic (pdf_tools.jsp only) ──────────────────────────
(function () {
  const pdfForm = document.getElementById('pdfMergeForm');
  const pdfUploader = document.getElementById('pdfUploader');

  if (!pdfForm || !pdfUploader) return; // not on the PDF tools page

  pdfForm.addEventListener('submit', async function (e) {
    e.preventDefault(); // Stop the form from refreshing the page

    const files = pdfUploader.files;
    if (files.length === 0) {
      alert("Please select at least one PDF file.");
      return;
    }

    try {
      // 1. Create a new empty PDF document
      const { PDFDocument } = PDFLib;
      const mergedPdf = await PDFDocument.create();

      // 2. Loop through all uploaded files
      for (let i = 0; i < files.length; i++) {
        const file = files[i];

        // Read file as ArrayBuffer
        const arrayBuffer = await file.arrayBuffer();

        // Load the uploaded PDF
        const pdf = await PDFDocument.load(arrayBuffer);

        // Copy all pages from uploaded PDF into the new Merged PDF
        const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
        copiedPages.forEach((page) => mergedPdf.addPage(page));
      }

      // 3. Save the merged PDF as a byte array
      const mergedPdfFile = await mergedPdf.save();

      // 4. Trigger download in the browser
      const blob = new Blob([mergedPdfFile], { type: 'application/pdf' });
      const link = document.createElement('a');
      link.href = URL.createObjectURL(blob);
      link.download = 'Merged_ExamHub_Notes.pdf';
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

    } catch (error) {
      console.error("Error merging PDFs:", error);
      alert("An error occurred while merging the PDFs. Ensure they are valid PDF files.");
    }
  });
})();

// ── Theme Toggle Logic ──────────────────────────────────────────
document.addEventListener("DOMContentLoaded", () => {
  const html = document.documentElement;
  const themeBtn = document.getElementById('themeBtn');
  const savedTheme = localStorage.getItem('eh-theme') || 'dark';

  function applyTheme(theme) {
    if (theme === 'light') {
      html.setAttribute('data-theme', 'light');
      if (themeBtn) themeBtn.textContent = '☀️';
    } else {
      html.removeAttribute('data-theme');
      if (themeBtn) themeBtn.textContent = '🌙';
    }
    localStorage.setItem('eh-theme', theme);
  }

  // 1. Apply the saved theme immediately on load
  applyTheme(savedTheme);

  // 2. Attach the click listener to the button
  if (themeBtn) {
    themeBtn.addEventListener('click', function () {
      const currentTheme = localStorage.getItem('eh-theme') || 'dark';
      applyTheme(currentTheme === 'dark' ? 'light' : 'dark');
    });
  }
});