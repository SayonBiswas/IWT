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