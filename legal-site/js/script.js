// === MAIN JAVASCRIPT FILE FOR VALIARK WEBSITE ===

document.addEventListener("DOMContentLoaded", function () {
  // Initialize all functionality
  initMobileMenu();
  initScrollAnimations();
  initContactForm();
  initSmoothScrolling();
  initHeaderScrollEffect();
});

// === MOBILE MENU FUNCTIONALITY ===
function initMobileMenu() {
  const hamburger = document.querySelector(".hamburger");
  const navMenu = document.querySelector(".nav-menu");

  if (hamburger && navMenu) {
    hamburger.addEventListener("click", function () {
      hamburger.classList.toggle("active");
      navMenu.classList.toggle("active");
    });

    // Close menu when clicking on a link
    const navLinks = document.querySelectorAll(".nav-link");
    navLinks.forEach((link) => {
      link.addEventListener("click", function () {
        hamburger.classList.remove("active");
        navMenu.classList.remove("active");
      });
    });

    // Close menu when clicking outside
    document.addEventListener("click", function (e) {
      if (!hamburger.contains(e.target) && !navMenu.contains(e.target)) {
        hamburger.classList.remove("active");
        navMenu.classList.remove("active");
      }
    });
  }
}

// === HEADER SCROLL EFFECT === (Disabled - using common header)
function initHeaderScrollEffect() {
  // This function is now handled in header.js
  // Keeping for compatibility but not using
}

// === SMOOTH SCROLLING ===
function initSmoothScrolling() {
  const links = document.querySelectorAll('a[href^="#"]');

  links.forEach((link) => {
    link.addEventListener("click", function (e) {
      e.preventDefault();

      const targetId = this.getAttribute("href");
      const targetElement = document.querySelector(targetId);

      if (targetElement) {
        const headerHeight = document.querySelector(".header").offsetHeight;
        const targetPosition = targetElement.offsetTop - headerHeight;

        window.scrollTo({
          top: targetPosition,
          behavior: "smooth",
        });
      }
    });
  });
}

// === SCROLL ANIMATIONS ===
function initScrollAnimations() {
  const observerOptions = {
    threshold: 0.1,
    rootMargin: "0px 0px -50px 0px",
  };

  const observer = new IntersectionObserver(function (entries) {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        entry.target.classList.add("visible");
      }
    });
  }, observerOptions);

  // Add animation classes to elements
  const animateElements = document.querySelectorAll(`
        .mvv-item,
        .service-card,
        .feature-card,
        .contact-item,
        .founder-card,
        .value-card,
        .process-step,
        .why-choose-item,
        .work-card,
        .contact-info-item,
        .faq-item
    `);

  animateElements.forEach((element, index) => {
    element.classList.add("fade-in");
    element.style.transitionDelay = `${index * 0.1}s`;
    observer.observe(element);
  });

  // Service detail animations
  const serviceDetails = document.querySelectorAll(".service-detail-content");
  serviceDetails.forEach((element, index) => {
    if (index % 2 === 0) {
      element.classList.add("slide-in-left");
    } else {
      element.classList.add("slide-in-right");
    }
    observer.observe(element);
  });
}

// === CONTACT FORM FUNCTIONALITY ===
function initContactForm() {
  const form = document.getElementById("contactForm");
  const inquiryTypeSelect = document.querySelector('select[name="inquiryType"]');
  const inquiryTypeRadios = document.querySelectorAll(
    'input[name="inquiryType"]'
  );
  const companyGroup = document.getElementById("companyGroup");
  const positionGroup = document.getElementById("positionGroup");
  const facultyGroup = document.getElementById("facultyGroup");
  const gradeGroup = document.getElementById("gradeGroup");

  if (form) {
    // Handle inquiry type change (select or radio)
    if (inquiryTypeSelect) {
      inquiryTypeSelect.addEventListener("change", function () {
        handleInquiryTypeChange(this.value);
      });
      handleInquiryTypeChange(inquiryTypeSelect.value);
    } else {
      inquiryTypeRadios.forEach((radio) => {
        radio.addEventListener("change", function () {
          handleInquiryTypeChange(this.value);
        });
      });
    }

    // Handle form submission
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      handleFormSubmission(this);
    });
  }

  function handleInquiryTypeChange(value) {
    // Reset all groups
    if (companyGroup) companyGroup.style.display = "block";
    if (positionGroup) positionGroup.style.display = "block";
    if (facultyGroup) facultyGroup.style.display = "none";
    if (gradeGroup) gradeGroup.style.display = "none";

    // Show/hide relevant fields based on inquiry type
    if (value === "recruitment") {
      if (companyGroup) companyGroup.style.display = "none";
      if (positionGroup) positionGroup.style.display = "none";
      if (facultyGroup) facultyGroup.style.display = "block";
      if (gradeGroup) gradeGroup.style.display = "block";
    } else if (value === "other") {
      if (companyGroup) companyGroup.style.display = "none";
      if (positionGroup) positionGroup.style.display = "none";
    }
  }

  async function handleFormSubmission(form) {
    // Collect form data
    const formData = new FormData(form);
    const data = {};

    for (let [key, value] of formData.entries()) {
      data[key] = value;
    }

    // Basic validation
    if (!validateForm(data)) {
      return;
    }

    // Show loading state
    const submitButton = form.querySelector('button[type="submit"]');
    const formStatus = document.getElementById('formStatus');
    const originalText = submitButton.textContent;
    submitButton.textContent = "送信中...";
    submitButton.disabled = true;
    
    if (formStatus) {
      formStatus.textContent = "送信中...";
      formStatus.style.color = "#666";
    }

    try {
      // Submit to Formspree
      const response = await fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'Accept': 'application/json'
        }
      });

      if (response.ok) {
        showSuccessMessage();
        form.reset();
        if (formStatus) {
          formStatus.textContent = "送信が完了しました！ありがとうございます。";
          formStatus.style.color = "#4CAF50";
        }
        
        // Reset form visibility
        handleInquiryTypeChange("");
      } else {
        const errorData = await response.json();
        throw new Error(errorData.error || "送信に失敗しました");
      }
    } catch (error) {
      console.error('Form submission error:', error);
      showErrorMessage("送信に失敗しました。もう一度お試しください。");
      if (formStatus) {
        formStatus.textContent = "送信に失敗しました。もう一度お試しください。";
        formStatus.style.color = "#f44336";
      }
    } finally {
      submitButton.textContent = originalText;
      submitButton.disabled = false;
    }
  }

  function validateForm(data) {
    const requiredFields = [
      "inquiryType",
      "lastName",
      "firstName",
      "email",
      "subject",
      "message",
    ];

    for (let field of requiredFields) {
      if (!data[field] || data[field].trim() === "") {
        showErrorMessage(`${getFieldLabel(field)}は必須項目です。`);
        return false;
      }
    }

    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(data.email)) {
      showErrorMessage("有効なメールアドレスを入力してください。");
      return false;
    }

    // Privacy policy agreement
    if (!data.privacy) {
      showErrorMessage("プライバシーポリシーへの同意が必要です。");
      return false;
    }

    return true;
  }

  function getFieldLabel(field) {
    const labels = {
      inquiryType: "お問い合わせ種別",
      lastName: "姓",
      firstName: "名",
      email: "メールアドレス",
      subject: "件名",
      message: "お問い合わせ内容",
    };
    return labels[field] || field;
  }

  function showSuccessMessage() {
    const message = document.createElement("div");
    message.className = "success-message";
    message.innerHTML = `
            <div style="
                position: fixed;
                top: 50%;
                left: 50%;
                transform: translate(-50%, -50%);
                background: #4CAF50;
                color: white;
                padding: 2rem;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0, 0, 0, 0.2);
                z-index: 9999;
                text-align: center;
                max-width: 400px;
            ">
                <h3 style="margin-bottom: 1rem;">送信完了</h3>
                <p style="margin-bottom: 0;">お問い合わせありがとうございます。<br>2営業日以内にご返信いたします。</p>
            </div>
            <div style="
                position: fixed;
                top: 0;
                left: 0;
                width: 100%;
                height: 100%;
                background: rgba(0, 0, 0, 0.5);
                z-index: 9998;
            "></div>
        `;

    document.body.appendChild(message);

    setTimeout(() => {
      document.body.removeChild(message);
    }, 3000);
  }

  function showErrorMessage(text) {
    const message = document.createElement("div");
    message.className = "error-message";
    message.innerHTML = `
            <div style="
                position: fixed;
                top: 20px;
                right: 20px;
                background: #f44336;
                color: white;
                padding: 1rem 1.5rem;
                border-radius: 8px;
                box-shadow: 0 5px 20px rgba(0, 0, 0, 0.2);
                z-index: 9999;
                max-width: 350px;
            ">
                ${text}
            </div>
        `;

    document.body.appendChild(message);

    setTimeout(() => {
      document.body.removeChild(message);
    }, 5000);
  }
}

// === UTILITY FUNCTIONS ===

// Debounce function for performance optimization
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

// Throttle function for scroll events
function throttle(func, limit) {
  let inThrottle;
  return function () {
    const args = arguments;
    const context = this;
    if (!inThrottle) {
      func.apply(context, args);
      inThrottle = true;
      setTimeout(() => (inThrottle = false), limit);
    }
  };
}

// Add optimized scroll listener
window.addEventListener(
  "scroll",
  throttle(function () {
    // Any scroll-based functionality can be added here
  }, 100)
);

// === PAGE-SPECIFIC FUNCTIONALITY ===

// Add any page-specific JavaScript here
if (document.body.classList.contains("home-page")) {
  // Home page specific code
}

if (document.body.classList.contains("contact-page")) {
  // Contact page specific code
}

// === ACCESSIBILITY IMPROVEMENTS ===

// Add keyboard navigation support
document.addEventListener("keydown", function (e) {
  // Escape key closes mobile menu
  if (e.key === "Escape") {
    const hamburger = document.querySelector(".hamburger");
    const navMenu = document.querySelector(".nav-menu");

    if (hamburger && navMenu && navMenu.classList.contains("active")) {
      hamburger.classList.remove("active");
      navMenu.classList.remove("active");
    }
  }
});

// === PERFORMANCE OPTIMIZATIONS ===

// Lazy load images (if any are added later)
if ("IntersectionObserver" in window) {
  const imageObserver = new IntersectionObserver((entries) => {
    entries.forEach((entry) => {
      if (entry.isIntersecting) {
        const img = entry.target;
        if (img.dataset.src) {
          img.src = img.dataset.src;
          img.classList.remove("lazy");
          imageObserver.unobserve(img);
        }
      }
    });
  });

  document.querySelectorAll("img[data-src]").forEach((img) => {
    imageObserver.observe(img);
  });
}

// === ERROR HANDLING ===

// Global error handler
window.addEventListener("error", function (e) {
  console.error("JavaScript error:", e.error);
  // In production, you might want to send this to a logging service
});

// Unhandled promise rejection handler
window.addEventListener("unhandledrejection", function (e) {
  console.error("Unhandled promise rejection:", e.reason);
  // In production, you might want to send this to a logging service
});

console.log("VALIARK website JavaScript loaded successfully!");
