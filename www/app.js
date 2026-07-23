(function() {
  var splash = document.getElementById('splash-screen');
  setTimeout(function() {
    splash.classList.add('exit');
    setTimeout(function() {
      splash.classList.add('hidden');
    }, 420);
  }, 4500);
})();
// ═══════════════════════════════
  /* ===== Safe Storage (يشتغل حتى لو localStorage محجوب) ===== */
  const _store = (() => {
    try { localStorage.setItem('_t','1'); localStorage.removeItem('_t'); return localStorage; }
    catch(e) {
      const mem = {};
      return { getItem: k => mem[k]||null, setItem: (k,v) => { mem[k]=String(v); }, removeItem: k => { delete mem[k]; } };
    }
  })();
  // تغطي كل استخدام localStorage في الملف
  const _ls = { getItem: k => _store.getItem(k), setItem: (k,v) => _store.setItem(k,v), removeItem: k => _store.removeItem(k) };
  Object.defineProperty(window, 'localStorage', { value: _ls, configurable: true });

  /* ============================================================
     🔴 ضع رابطك الحقيقي من GitHub هنا
     ============================================================ */
  const DATA_BASE_URL = "https://raw.githubusercontent.com/akramfaeq/manga/refs/heads/main/";

  /* ============================================================
     🔴 ضع Firebase API Key هنا (اختياري)
     ============================================================ */
  const FIREBASE_API_KEY = "ضع_apiKey_هنا";
  const FIREBASE_PROJECT_ID = "manga-app-18065";
  const AUTH_BASE = "https://identitytoolkit.googleapis.com/v1/accounts";
  const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${FIREBASE_PROJECT_ID}/databases/(default)/documents`;

  /* ===== نظام الصفحات (SPA) ===== */
  let currentPage = "home";
  let mangaList = [];
  let currentManga = null;
  let pendingPhotoBase64 = null;  // الصورة المختارة للتحديث
  const HIDE_NAV_PAGES = ["reader", "timeline"];

  /* ===== حالات صفحة حسابي ===== */
  function onProfilePageOpen() {
    updateFavoritesCount();
    const session = getSession();
    if (session && session.localId) {
      showEditState();
    } else {
      showAuthState('login'); // مباشرة للفورم بدون صفحة وسيطة
    }
  }

  function showGuestState() {
    document.getElementById("profile-guest-state").style.display = "block";
    document.getElementById("profile-auth-state").style.display = "none";
    document.getElementById("profile-edit-state").style.display = "none";
    // تحديث البانر بصورة المانغا العشوائية
    const bgEl = document.getElementById("profile-banner-bg");
    if (mangaList.length > 0 && mangaList[0].cover) {
      bgEl.style.backgroundImage = `url('${mangaList[0].cover}')`;
    }
  }

  function showAuthState(mode) {
    setTimeout(() => updateUIText?.(), 30);
    document.getElementById("profile-guest-state").style.display = "none";
    document.getElementById("profile-auth-state").style.display = "block";
    document.getElementById("profile-edit-state").style.display = "none";
    const emailEl = document.getElementById("login-email");
    const passEl  = document.getElementById("login-password");
    const msgEl   = document.getElementById("auth-status-msg");
    if (emailEl) emailEl.value = "";
    if (passEl)  passEl.value  = "";
    if (msgEl)   msgEl.textContent = "";
    // تحديث نص الفورم بدون click()
    authMode = mode === "register" ? "signup" : "login";
    const formTitle = document.getElementById("form-title");
    const submitBtn = document.getElementById("submit-btn");
    const switchText = document.getElementById("switch-mode-text");
    if (formTitle) formTitle.textContent = authMode === "login" ? t("loginTitle") : t("registerTitle");
    if (submitBtn) submitBtn.textContent = authMode === "login" ? t("loginTitle") : t("registerTitle");
    if (switchText) switchText.innerHTML = authMode === "login"
      ? `${t("noAccountText")} <span id="switch-mode-link" style="color:var(--accent-neon);cursor:pointer;text-decoration:underline;">${t("createAccount")}</span>`
      : `${t("haveAccount")} <span id="switch-mode-link" style="color:var(--accent-neon);cursor:pointer;text-decoration:underline;">${t("signIn")}</span>`;
  }

  function showEditState() {
    document.getElementById("profile-guest-state").style.display = "none";
    document.getElementById("profile-auth-state").style.display = "none";
    document.getElementById("profile-edit-state").style.display = "block";
    const session = getSession();
    if (session) {
      document.getElementById("email-input").value = session.email || "";
      const _origName = session.displayName || "";
      const _origPhoto = session.photoBase64 || "";
      document.getElementById("name-input").value = _origName;

      // إظهار زر الحفظ فقط عند التعديل
      function checkProfileChanged() {
        const input = document.getElementById("name-input");
        const baseline = input.dataset.saved || _origName;
        const nameChanged = input.value.trim() !== baseline;
        const photoChanged = !!pendingPhotoBase64;
        document.getElementById("save-btn").style.display = (nameChanged || photoChanged) ? "" : "none";
      }
      document.getElementById("name-input").addEventListener("input", checkProfileChanged);
      // سيتم استدعاء checkProfileChanged أيضاً عند اختيار صورة جديدة
      if (session.photoBase64) {
        setAvatarPreview(session.photoBase64);
        // حفظ الصورة الحالية كـ pending حتى إذا غيرها المستخدم
        pendingPhotoBase64 = session.photoBase64;
      } else {
        pendingPhotoBase64 = null;
        resetAvatarPreview();
      }
    }
  }

  function setAvatarPreview(src) {
    const aw = document.getElementById("avatar-wrap");
    if (!aw) return;
    aw.innerHTML = `
      <img src="${src}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">
      <div class="avatar-edit-badge">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M12 5V19M5 12H19" stroke="white" stroke-width="2.5" stroke-linecap="round"/></svg>
      </div>`;
  }

  function resetAvatarPreview() {
    const aw = document.getElementById("avatar-wrap");
    if (!aw) return;
    aw.innerHTML = `
      <svg width="40" height="40" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="#C9B6F5" stroke-width="2"/><path d="M4 20C4 16.5 7.5 14 12 14C16.5 14 20 16.5 20 20" stroke="#C9B6F5" stroke-width="2" stroke-linecap="round"/></svg>
      <div class="avatar-edit-badge">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><path d="M12 5V19M5 12H19" stroke="white" stroke-width="2.5" stroke-linecap="round"/></svg>
      </div>`;
  }

  function toggleDrawer() { /* الدروار محذوف */ }

  /* ===== جلب البيانات الأساسية ===== */
  function showSkeletons() {
    const skeletonCard = () => `<div class="skeleton-card" style="flex:0 0 110px;">
      <div class="skeleton" style="width:110px;height:155px;border-radius:12px;"></div>
      <div class="skeleton skeleton-title" style="margin-top:6px;width:80%;"></div>
      <div class="skeleton" style="height:8px;width:60%;margin-top:4px;border-radius:4px;"></div>
    </div>`;
    const skeletonGrid = () => `<div class="skeleton-card">
      <div class="skeleton" style="width:100%;aspect-ratio:2/3;border-radius:10px;"></div>
      <div class="skeleton skeleton-title" style="margin-top:6px;"></div>
      <div class="skeleton" style="height:8px;width:50%;margin-top:4px;border-radius:4px;"></div>
    </div>`;
    const newRow = document.getElementById("new-chapters-row");
    if (newRow) newRow.innerHTML = Array(5).fill(0).map(skeletonCard).join("");
    const topRow = document.getElementById("top-rated-row");
    if (topRow) topRow.innerHTML = Array(5).fill(0).map(skeletonCard).join("");
    const libGrid = document.getElementById("library-grid");
    if (libGrid) libGrid.innerHTML = Array(9).fill(0).map(skeletonGrid).join("");
  }

  async function fetchWithTimeout(url, timeout = 8000) {
    const controller = new AbortController();
    const id = setTimeout(() => controller.abort(), timeout);
    try {
      const res = await fetch(url, { cache: "no-store", signal: controller.signal });
      clearTimeout(id);
      if (!res.ok) throw new Error("HTTP " + res.status);
      return res;
    } catch(e) { clearTimeout(id); throw e; }
  }

  async function loadMangaList() {
    showSkeletons();
    let retries = 2;
    while (retries >= 0) {
      try {
        const res = await fetchWithTimeout(DATA_BASE_URL + "manga-list.json?t=" + Date.now());
        mangaList = await res.json();
        if (!Array.isArray(mangaList) || mangaList.length === 0) throw new Error("empty");
        renderContinueReading();
        loadHomeMangaList();
        return;
      } catch (err) {
        retries--;
        if (retries < 0) {
          // عرض رسالة خطأ بدل الشاشة الفارغة
          ["new-chapters-row","top-rated-row","library-grid"].forEach(id => {
            const el = document.getElementById(id);
            if (el) el.innerHTML = `<div style="color:#BF5FFF;font-size:13px;padding:20px 0;text-align:center;width:100%;">⚠️ تعذّر تحميل البيانات<br><span style="font-size:11px;color:#7A728E;">تحقق من الاتصال ثم اسحب للأسفل للتحديث</span></div>`;
          });
        } else {
          await new Promise(r => setTimeout(r, 1500));
        }
      }
    }
  }

  function getFavHeart(id) {
    const favIds = getFavorites().map(f => f.id);
    return favIds.includes(id)
      ? '<svg viewBox="0 0 24 24" fill="#E63946"><path d="M12 21C12 21 3 14 3 8.5C3 5.4 5.4 3 8.5 3C10.2 3 11.7 3.8 12 5C12.3 3.8 13.8 3 15.5 3C18.6 3 21 5.4 21 8.5C21 14 12 21 12 21Z"/></svg>'
      : '<svg viewBox="0 0 24 24" fill="none"><path d="M12 21C12 21 3 14 3 8.5C3 5.4 5.4 3 8.5 3C10.2 3 11.7 3.8 12 5C12.3 3.8 13.8 3 15.5 3C18.6 3 21 5.4 21 8.5C21 14 12 21 12 21Z" stroke="white" stroke-width="2"/></svg>';
  }

  /* ===== الصفحة الرئيسية ===== */
  function renderStars(rating) {
    const r = parseFloat(rating) || 0;
    const full = Math.round(r);
    let stars = '';
    for (let i = 1; i <= 5; i++) {
      const color = i <= full ? '#E8B85C' : 'rgba(255,255,255,0.2)';
      stars += `<svg viewBox="0 0 24 24" fill="${color}"><path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z"/></svg>`;
    }
    return stars;
  }

  function renderMangaCardV2(m) {
    const stars = renderStars(m.rating);
    const views = formatViews(m.views || m.chapters_count || 0);
    return `
      <div class="manga-card-v2" onclick="selectManga('${m.id}')">
        <div class="cover" ${coverStyle(m)}>
          <div class="cover-fav-btn" onclick="event.stopPropagation(); checkLoginAndFav(${JSON.stringify(m).replace(/"/g,'&quot;')}, this);">
            ${getFavHeart(m.id)}
          </div>
          <div class="cover-rating-badge">★ ${m.rating}</div>
        </div>
        <div class="card-name">${truncateTitle(m.title, 13)}</div>
        <div class="star-row">${stars}</div>
        ${views ? `<div class="card-views">${views}</div>` : ''}
      </div>`;
  }

  function renderGridItemV2(m) {
    return `
      <div class="grid-item-v2" onclick="selectManga('${m.id}')">
        <div class="cover" ${coverStyle(m)}>
          <div class="cover-fav-btn" onclick="event.stopPropagation(); checkLoginAndFav(${JSON.stringify(m).replace(/"/g,'&quot;')}, this);">
            ${getFavHeart(m.id)}
          </div>
          <div class="cover-rating-badge">★ ${m.rating}</div>
        </div>
        <div class="item-title">${truncateTitle(m.title, 12)}</div>
        <div class="item-stars">${renderStars(m.rating)}</div>
        <div class="item-status">${_appLang==="en" ? (m.status==="مكتملة"?"Completed":"Ongoing") : (m.status||"مستمرة")}</div>
      </div>`;
  }

  function formatViews(n) {
    if (!n) return '';
    if (n >= 1000000) return (n/1000000).toFixed(1) + 'M';
    if (n >= 1000) return (n/1000).toFixed(1) + 'K';
    return String(n);
  }

  window.switchHomeTab = function(tab, el) {
    document.querySelectorAll('.home-tab').forEach(t => t.classList.remove('active'));
    el.classList.add('active');
    // يمكن إضافة منطق تصفية لاحقاً
  };

  function loadHomeMangaList() {
    const newChaptersRow = document.getElementById("new-chapters-row");
    const topRatedRow = document.getElementById("top-rated-row");
    const libraryGrid = document.getElementById("library-grid");

    try {
      // آخر الإصدارات
      if (newChaptersRow) {
        const newChaptersList = mangaList.filter(m => m.new_chapter);
        const displayList = newChaptersList.length > 0 ? newChaptersList : mangaList.slice(0, 8);
        newChaptersRow.innerHTML = displayList.slice(0, 8).map(m => renderMangaCardV2(m)).join("");
        observeCovers(newChaptersRow);
        const newChaptersSection = document.getElementById("new-chapters-section");
        if (newChaptersSection) newChaptersSection.style.display = "";
      }

      // الأعلى تقييماً
      if (topRatedRow) {
        const topRated = [...mangaList].sort((a, b) => (parseFloat(b.rating) || 0) - (parseFloat(a.rating) || 0));
        topRatedRow.innerHTML = topRated.slice(0, 8).map(m => renderMangaCardV2(m)).join("");
        observeCovers(topRatedRow);
      }

      // مكتبة المانغا - شريط أفقي
      if (libraryGrid) {
        libraryGrid.className = "hscroll";
        const shuffled = [...mangaList].sort(() => Math.random() - 0.5);
        libraryGrid.innerHTML = shuffled.map(m => renderMangaCardV2(m)).join("");
        observeCovers(libraryGrid);
      }
    } catch (err) {
      console.error("خطأ في تحميل المانغا:", err);
    }
  }

  function renderHeroSlide(manga) {
    const tagsHtml = (manga.genres || []).slice(0, 3).map(g => `<span class="tag">${g}</span>`).join("");
    return `
      <div class="hero-slide" onclick="selectManga('${manga.id}')" style="background-image:url('${manga.cover}'); background-size:cover; background-position:center;">
        <div class="hero-content">
          <div class="hero-rating">★ ${manga.rating}</div>
          <div class="hero-title">${manga.title.toUpperCase()}</div>
          <div class="hero-desc">${manga.description || ""}</div>
          <div class="hero-tags">${tagsHtml}</div>
        </div>
      </div>`;
  }

  function coverStyle(manga) {
    return manga.cover ? `data-cover="${manga.cover}"` : "";
  }

  // Lazy loading للصور
  const coverObserver = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        const el = entry.target;
        const cover = el.dataset.cover;
        if (cover) {
          el.style.backgroundImage = `url('${cover}')`;
          el.style.backgroundSize = "cover";
          el.style.backgroundPosition = "center";
          delete el.dataset.cover;
          coverObserver.unobserve(el);
        }
      }
    });
  }, { rootMargin: "100px 0px", threshold: 0.01 });

  function observeCovers(container) {
    (container || document).querySelectorAll("[data-cover]").forEach(el => {
      coverObserver.observe(el);
    });
  }

  function truncateTitle(title, max = 10) {
    return title && title.length > max ? title.slice(0, max) + "..." : (title || "");
  }

  function initSliderObserver() {
    const slider = document.getElementById('hero-slider');
    const dots = document.querySelectorAll('#slider-dots .dot');
    const slides = Array.from(document.querySelectorAll('.hero-slide'));
    if (!slider || slides.length === 0) return;

    const observer = new IntersectionObserver((entries) => {
      entries.forEach((entry) => {
        if (entry.isIntersecting && entry.intersectionRatio > 0.6) {
          const index = slides.indexOf(entry.target);
          dots.forEach((d, i) => d.classList.toggle('active', i === index));
        }
      });
    }, { root: slider, threshold: [0.6] });

    slides.forEach(slide => observer.observe(slide));
  }

  function refreshUserUI() {
    const session = getSession();
    const headerAvatarEl = document.getElementById("header-avatar");
    const profileTopAvatar = document.getElementById("profile-top-avatar");
    const moreAvatarWrap = document.getElementById("more-avatar-wrap");
    const defaultSvg = `<svg viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="#C9B6F5" stroke-width="2"/><path d="M4 20C4 16.5 7.5 14 12 14C16.5 14 20 16.5 20 20" stroke="#C9B6F5" stroke-width="2" stroke-linecap="round"/></svg>`;

    if (!session || !session.localId) {
      if (headerAvatarEl) headerAvatarEl.innerHTML = defaultSvg;
      if (profileTopAvatar) profileTopAvatar.innerHTML = defaultSvg.replace('viewBox="0 0 24 24"','viewBox="0 0 24 24" style="width:36px;height:36px;"');
      if (moreAvatarWrap) moreAvatarWrap.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none" id="more-avatar-svg"><circle cx="12" cy="8" r="4" stroke="#C084FC" stroke-width="2"/><path d="M4 20C4 16.5 7.5 14 12 14C16.5 14 20 16.5 20 20" stroke="#C084FC" stroke-width="2" stroke-linecap="round"/></svg>`;
      // تحديث هيرو سلايد
      const heroSlides = document.querySelectorAll(".hero-slide-avatar");
      heroSlides.forEach(el => el.innerHTML = defaultSvg);
      return;
    }

    // مسجل دخول
    if (session.photoBase64) {
      const imgHtml = `<img src="${session.photoBase64}" alt="" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">`;
      const imgHtmlCover = `<img src="${session.photoBase64}" alt="" style="width:100%;height:100%;object-fit:cover;">`;
      if (headerAvatarEl) headerAvatarEl.innerHTML = imgHtml;
      if (profileTopAvatar) profileTopAvatar.innerHTML = imgHtmlCover;
      if (moreAvatarWrap) moreAvatarWrap.innerHTML = imgHtml;
      // تحديث الهيرو سلايد banner
      const bgEl = document.getElementById("profile-banner-bg");
      if (bgEl) bgEl.style.backgroundImage = `url(${session.photoBase64})`;
    } else {
      if (headerAvatarEl) headerAvatarEl.innerHTML = defaultSvg;
      if (profileTopAvatar) profileTopAvatar.innerHTML = defaultSvg.replace('viewBox="0 0 24 24"','viewBox="0 0 24 24" style="width:36px;height:36px;"');
      if (moreAvatarWrap) moreAvatarWrap.innerHTML = `<svg width="24" height="24" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="8" r="4" stroke="#C084FC" stroke-width="2"/><path d="M4 20C4 16.5 7.5 14 12 14C16.5 14 20 16.5 20 20" stroke="#C084FC" stroke-width="2" stroke-linecap="round"/></svg>`;
      const bgEl = document.getElementById("profile-banner-bg");
      if (bgEl) bgEl.style.backgroundImage = "";
    }

    // تحديث إظهار/إخفاء قسم المفضلة في more-page
    const favSection = document.getElementById("more-fav-section");
    if (favSection) {
      favSection.style.display = (session && session.localId) ? "flex" : "none";
    }
  }

  /* ===== صفحة البحث (Lazy Loading) ===== */
  let searchMangaList = [];
  let activeGenres = [];
  let activeType = null;
  let activeStatus = null;
  let searchQuery = "";
  let tempGenres = [], tempType = null, tempStatus = null; // مؤقتة للـ filter sheet

  async function loadSearchLibrary() {
    try {
      const res = await fetch(DATA_BASE_URL + "manga-list.json?t=" + Date.now(), { cache: "no-store" });
      searchMangaList = await res.json();
      buildGenreChips();
      renderSearch();
    } catch (err) {
      document.getElementById("loading-state").innerHTML = `<div class="loading-state">تعذر تحميل المكتبة 🌐</div>`;
    }
  }

  function buildGenreChips() {
    const TYPE_STATUS = ["مانغا","مانهوا","manhwa","manga","مستمرة","مكتملة","ongoing","completed","finished","مستمر","مكتمل","publishing","releasing","continuing","ended"];
    const allGenres = new Set();
    searchMangaList.forEach(m => (m.genres || []).forEach(g => {
      if (!TYPE_STATUS.map(x=>x.toLowerCase()).includes(g.toLowerCase().trim())) {
        allGenres.add(g);
      }
    }));
    const genreChipsContainer = document.getElementById("genre-chips");
    genreChipsContainer.innerHTML = Array.from(allGenres).map(g =>
      `<div class="sheet-chip" data-value="${g}">${g}</div>`
    ).join("");
    bindChipEvents(genreChipsContainer, "genre");
  }

  // دالة مشتركة بين buildGenreChips والـ DOMContentLoaded
  function bindChipEvents(container, group) {
    container.querySelectorAll(".sheet-chip").forEach(chip => {
      chip.addEventListener("click", () => {
        const value = chip.dataset.value;
        if (group === "genre") {
          chip.classList.toggle("active");
          if (tempGenres.includes(value)) {
            tempGenres = tempGenres.filter(g => g !== value);
          } else {
            tempGenres.push(value);
          }
        } else {
          const isActive = chip.classList.contains("active");
          container.querySelectorAll(".sheet-chip").forEach(c => c.classList.remove("active"));
          if (group === "type") tempType = isActive ? null : value;
          if (group === "status") tempStatus = isActive ? null : value;
          if (!isActive) chip.classList.add("active");
        }
      });
    });
  }

  function applySearchFilters(list) {
    let result = list;

    if (activeGenres.length > 0) {
      result = result.filter(m => {
        const mg = (m.genres || []).map(g => g.toLowerCase().trim());
        return activeGenres.every(g => mg.includes(g.toLowerCase().trim()));
      });
    }

    if (activeType) {
      const typeMap = { "مانغا": ["manga","مانغا","منجا"], "مانهوا": ["manhwa","مانهوا"] };
      const allowed = typeMap[activeType] || [activeType.toLowerCase()];
      result = result.filter(m => {
        const typeVal = (m.type || "").toLowerCase().trim();
        if (typeVal) return allowed.some(a => typeVal.includes(a));
        // fallback: لو ما في type field نشوف في genres
        return (m.genres || []).some(g => allowed.some(a => g.toLowerCase().trim() === a));
      });
    }

    if (activeStatus) {
      const statusMap = {
        "مستمرة": ["ongoing","مستمرة","مستمر","publishing","releasing","continuing"],
        "مكتملة": ["completed","مكتملة","مكتمل","finished","ended"]
      };
      const allowed = statusMap[activeStatus] || [activeStatus.toLowerCase()];
      result = result.filter(m => {
        const statusVal = (m.status || "").toLowerCase().trim();
        if (statusVal) return allowed.some(a => statusVal.includes(a));
        // fallback: لو ما في status field نشوف في genres
        return (m.genres || []).some(g => allowed.some(a => g.toLowerCase().trim() === a));
      });
    }

    if (searchQuery) {
      result = result.filter(m => m.title.toLowerCase().includes(searchQuery.toLowerCase()));
    }

    return result;
  }

  function renderSearch() {
    const filtered = applySearchFilters(searchMangaList);

    if (searchQuery) {
      if (filtered.length === 0) {
        document.getElementById("loading-state").classList.remove("visible");
        document.getElementById("suggestions-state").classList.remove("visible");
        document.getElementById("browse-state").classList.remove("visible");
        document.getElementById("empty-state").classList.add("visible");
        return;
      }
      document.getElementById("suggestions-list").innerHTML = filtered.map(renderSuggestion).join("");
      document.getElementById("loading-state").classList.remove("visible");
      document.getElementById("suggestions-state").classList.add("visible");
      document.getElementById("browse-state").classList.remove("visible");
      document.getElementById("empty-state").classList.remove("visible");
    } else {
      if (filtered.length === 0) {
        document.getElementById("loading-state").classList.remove("visible");
        document.getElementById("suggestions-state").classList.remove("visible");
        document.getElementById("browse-state").classList.remove("visible");
        document.getElementById("empty-state").classList.add("visible");
        return;
      }
      const hasFilter = activeGenres.length > 0 || activeType || activeStatus;
      document.getElementById("results-title").textContent = hasFilter ? `النتائج (${filtered.length})` : "كل المانغا";
      document.getElementById("browse-grid").innerHTML = filtered.map(renderCard).join("");
      observeCovers(document.getElementById("browse-grid"));
      document.getElementById("loading-state").classList.remove("visible");
      document.getElementById("suggestions-state").classList.remove("visible");
      document.getElementById("browse-state").classList.add("visible");
      document.getElementById("empty-state").classList.remove("visible");
    }
  }

  function renderCard(manga) {
    return `
      <div class="grid-item" onclick="selectManga('${manga.id}')">
        <div class="cover" ${coverStyle(manga)}>
          <span class="cover-badge small">★ ${manga.rating}</span>
          <div class="cover-fav-btn" onclick="event.stopPropagation(); checkLoginAndFav(${JSON.stringify(manga).replace(/"/g,'&quot;')}, this);">
            ${getFavHeart(manga.id)}
          </div>
        </div>
        <div class="manga-title" style="text-align:left;">${truncateTitle(manga.title)}</div>
      </div>`;
  }

  function renderSuggestion(manga) {
    return `
      <div class="suggestion-item" onclick="selectManga('${manga.id}')">
        <div class="suggestion-cover" ${coverStyle(manga)}></div>
        <div class="suggestion-info">
          <div class="suggestion-title">${manga.title}</div>
          <div class="suggestion-meta">${(manga.genres || []).join(" · ")}</div>
        </div>
        <div class="suggestion-rating">★ ${manga.rating}</div>
      </div>`;
  }

  document.addEventListener("DOMContentLoaded", () => {
    const searchInput = document.getElementById("search-input");
    const clearBtn = document.getElementById("clear-btn");
    const filterBtn = document.getElementById("filter-btn");
    const filterDot = document.getElementById("filter-dot");
    const sheetOverlay = document.getElementById("sheet-overlay");
    const filterSheet = document.getElementById("filter-sheet");

    searchInput.addEventListener("input", () => {
      searchQuery = searchInput.value.trim();
      clearBtn.classList.toggle("show", searchQuery.length > 0);
      renderSearch();
    });

    clearBtn.addEventListener("click", () => {
      searchInput.value = "";
      searchQuery = "";
      clearBtn.classList.remove("show");
      renderSearch();
    });

    filterBtn.addEventListener("click", () => {
      // نزامن حالة الـ temp مع الـ active الحالية عند كل فتح للـ sheet
      tempGenres = [...activeGenres];
      tempType = activeType;
      tempStatus = activeStatus;

      // نرسم حالة الـ chips بشكل صحيح (active/غير active)
      document.querySelectorAll("#genre-chips .sheet-chip").forEach(chip => {
        chip.classList.toggle("active", tempGenres.includes(chip.dataset.value));
      });
      document.querySelectorAll("#type-chips .sheet-chip").forEach(chip => {
        chip.classList.toggle("active", chip.dataset.value === tempType);
      });
      document.querySelectorAll("#status-chips .sheet-chip").forEach(chip => {
        chip.classList.toggle("active", chip.dataset.value === tempStatus);
      });

      sheetOverlay.classList.add("open");
      filterSheet.classList.add("open");
      document.querySelector(".bottom-nav")?.style.setProperty("display", "none");
    });

    function closeFilterSheet() {
      sheetOverlay.classList.remove("open");
      filterSheet.classList.remove("open");
      document.querySelector(".bottom-nav")?.style.removeProperty("display");
    }

    sheetOverlay.addEventListener("click", () => closeFilterSheet());

    bindChipEvents(document.getElementById("type-chips"), "type");
    bindChipEvents(document.getElementById("status-chips"), "status");

    document.getElementById("sheet-apply").addEventListener("click", () => {
      activeGenres = [...tempGenres];
      activeType = tempType;
      activeStatus = tempStatus;
      closeFilterSheet();
      renderActiveFilterChips();
      renderSearch();
    });

    function renderActiveFilterChips() {
      const chips = [];
      activeGenres.forEach(g => chips.push({ key: "genre", value: g, label: g }));
      if (activeType) chips.push({ key: "type", value: activeType, label: activeType });
      if (activeStatus) chips.push({ key: "status", value: activeStatus, label: activeStatus });

      const hasAny = chips.length > 0;
      filterBtn.classList.toggle("has-active", hasAny);
      filterDot.classList.toggle("show", hasAny);
      document.getElementById("active-filters-row").classList.toggle("show", hasAny);

      if (!hasAny) {
        document.getElementById("active-filters-row").innerHTML = "";
        return;
      }

      document.getElementById("active-filters-row").innerHTML = chips.map(c => `
        <div class="active-chip">
          ${c.label}
          <svg width="10" height="10" viewBox="0 0 24 24" fill="none" onclick="removeSearchFilter('${c.key}', '${c.value}')"><path d="M6 6L18 18M6 18L18 6" stroke="#C9B6F5" stroke-width="3" stroke-linecap="round"/></svg>
        </div>
      `).join("");
    }

    window.removeSearchFilter = function (key, value) {
      if (key === "all") { activeGenres = []; activeType = null; activeStatus = null; }
      if (key === "genre") activeGenres = activeGenres.filter(g => g !== value);
      if (key === "type") activeType = null;
      if (key === "status") activeStatus = null;
      renderActiveFilterChips();
      renderSearch();
    };
  });

  /* ===== صفحة التفاصيل ===== */
  function selectManga(mangaId) {
    localStorage.setItem("selected_manga_id", mangaId);
    goToPage("details");
  }

  async function loadMangaDetails() {
    const mangaId = localStorage.getItem("selected_manga_id");
    const container = document.getElementById("manga-content");

    try {
      // لو mangaList فارغة نحملها أولاً
      if (!mangaList || mangaList.length === 0) {
        const res = await fetch(DATA_BASE_URL + "manga-list.json?t=" + Date.now(), { cache: "no-store" });
        mangaList = await res.json();
      }

      const manga = mangaList.find(m => m.id === mangaId);

      if (!manga) {
        container.innerHTML = `<div class="not-found"><p>لم نجد هذه المانغا 🤔</p></div>`;
        return;
      }

      renderMangaInfo(manga);

      try {
        const chaptersRes = await fetch(DATA_BASE_URL + "chapters-" + manga.id + ".json?t=" + Date.now(), { cache: "no-store" });
        if (!chaptersRes.ok) throw new Error("HTTP " + chaptersRes.status);
        manga.chaptersList = await chaptersRes.json();
      } catch (e) {
        manga.chaptersList = [];
      }

      currentManga = manga;
      selectedManga = manga;

      renderChaptersSection(manga);

    } catch (err) {
      container.innerHTML = `<div class="not-found"><p>تعذر الاتصال 🌐</p></div>`;
    }
  }

  function renderMangaInfo(manga) {
    const container = document.getElementById("manga-content");
    const coverUrl = manga.cover || "";

    container.innerHTML = `
      <div class="hero-cover" style="background-image:url('${coverUrl}');">
        <div class="hero-overlay"></div>
        <div class="back-btn" onclick="goBack()">
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M15 19L8 12L15 5" stroke="#fff" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
        </div>
      </div>
      <div class="content">
        <div class="cover-rating-badge" style="position:relative;bottom:auto;left:auto;display:inline-flex;margin-bottom:10px;font-size:14px;padding:5px 14px;">★ ${manga.rating}</div>
        <div class="manga-title" style="text-align:start; direction:${_appLang==='en'?'ltr':'rtl'};">${manga.title}</div>
        <div class="manga-tags">
          ${manga.genres.map(g => `<span class="tag">${g}</span>`).join("")}
        </div>
        <div class="manga-desc">${manga.description}</div>

        <div class="action-bar">
          <button class="btn-read" id="read-btn">
            <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M6 4L20 12L6 20V4Z"/></svg>
            <span data-i18n="startReading">ابدأ القراءة</span>
          </button>
          <button class="btn-fav" id="fav-btn">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none"><path d="M6 4H18V20L12 16L6 20V4Z" stroke="#C9B6F5" stroke-width="2" stroke-linejoin="round"/></svg>
          </button>
        </div>

        <div class="info-grid">
          <div class="info-card">
            <div class="info-card-label" data-i18n="chapters">الفصول</div>
            <div class="info-card-value">${manga.chapters}</div>
          </div>
          <div class="info-card">
            <div class="info-card-label" data-i18n="type">النوع</div>
            <div class="info-card-value">${manga.type || "مانغا"}</div>
          </div>
          <div class="info-card">
            <div class="info-card-label" data-i18n="status">الحالة</div>
            <div class="info-card-value ${manga.status === 'مكتملة' ? 'status-completed' : 'status-ongoing'}">${_appLang==="en" ? (manga.status==="مكتملة"?"Completed":"Ongoing") : (manga.status||"مستمرة")}</div>
          </div>
        </div>

        <div class="chapters-section">
          <div class="chapters-head">
            <div class="chapters-title" data-i18n="chapters">الفصول</div>
            <div class="sort-toggle" id="sort-toggle">
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none" id="sort-icon"><path d="M12 5V19M12 19L7 14M12 19L17 14" stroke="#C9B6F5" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </div>
          </div>

          <div class="chapter-search">
            <svg width="15" height="15" viewBox="0 0 24 24" fill="none"><circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="2"/><path d="M21 21L17 17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/></svg>
            <input type="number" id="chapter-search-input" placeholder="ابحث برقم الفصل..." data-i18n-placeholder="chapterSearch">
          </div>

          <div id="chapters-list-container">
            <div style="text-align:center; padding:20px; color:#8E8696; font-size:13px;">جاري تحميل الفصول...</div>
          </div>
          <button class="load-more-btn" id="load-more-btn" style="display:none;" data-i18n="showMore">عرض المزيد</button>
        </div>
      </div>
    `;

    // زر المفضلة — يحفظ ويحذف من localStorage
    const favBtn = document.getElementById("fav-btn");
    const isFav = getFavorites().some(f => f.id === manga.id);
    if (isFav) favBtn.classList.add("active");
    favBtn.addEventListener("click", function () {
      const session = getSession();
      if (!session) { goToPage("profile"); return; }
      toggleFavorite(manga);
      this.classList.toggle("active", getFavorites().some(f => f.id === manga.id));
    });

    renderChaptersSection(manga);
  }

  function renderChaptersSection(manga) {
    const CHAPTERS_PER_PAGE = 30;
    let sortDescending = true;
    let visibleCount = CHAPTERS_PER_PAGE;
    let searchNumber = "";

    const chaptersListContainer = document.getElementById("chapters-list-container");
    const loadMoreBtn = document.getElementById("load-more-btn");
    const sortToggle = document.getElementById("sort-toggle");
    const sortIcon = document.getElementById("sort-icon");
    const searchInput = document.getElementById("chapter-search-input");

    function getFilteredChapters() {
      let list = [...(manga.chaptersList || [])];
      list.sort((a, b) => sortDescending ? b.number - a.number : a.number - b.number);
      if (searchNumber) {
        list = list.filter(c => String(c.number).includes(searchNumber));
      }
      return list;
    }

    function renderChapters() {
      const filtered = getFilteredChapters();

      if (filtered.length === 0) {
        chaptersListContainer.innerHTML = `<div class="no-chapters">لا توجد فصول مطابقة</div>`;
        loadMoreBtn.style.display = "none";
        return;
      }

      const toShow = searchNumber ? filtered : filtered.slice(0, visibleCount);

      chaptersListContainer.innerHTML = toShow.map(ch => `
        <div class="chapter-item" onclick="openChapter(${ch.number})">
          <div class="chapter-item-info">
            <div class="chapter-item-title">${t("chapterWord")} ${ch.number}</div>
            <div class="chapter-item-meta">${ch.pages ? ch.pages.length : 0} صفحة</div>
          </div>
          <div class="chapter-play-icon">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="#C9B6F5"><path d="M6 4L20 12L6 20V4Z"/></svg>
          </div>
        </div>
      `).join("");

      loadMoreBtn.style.display = (!searchNumber && filtered.length > visibleCount) ? "block" : "none";
    }

    sortToggle.addEventListener("click", () => {
      sortDescending = !sortDescending;
      sortIcon.style.transform = sortDescending ? "rotate(0deg)" : "rotate(180deg)";
      renderChapters();
    });

    searchInput.addEventListener("input", () => {
      searchNumber = searchInput.value.trim();
      renderChapters();
    });

    loadMoreBtn.addEventListener("click", () => {
      visibleCount += CHAPTERS_PER_PAGE;
      renderChapters();
    });

    const sortedAsc = [...(manga.chaptersList || [])].sort((a, b) => Number(a.number) - Number(b.number));

    window.openChapter = function (chapterNumber) {
      const chapter = manga.chaptersList.find(c => Number(c.number) === Number(chapterNumber));
      console.log("[openChapter]", chapterNumber, "found:", !!chapter, "pages:", chapter?.pages?.length);
      if (!chapter) return;
      const index = sortedAsc.findIndex(c => Number(c.number) === Number(chapter.number));
      const prevChapter = sortedAsc[index - 1] || null;
      const nextChapter = sortedAsc[index + 1] || null;

      localStorage.setItem("reader_data", JSON.stringify({
        mangaTitle: manga.title,
        chapterNumber: chapter.number,
        pages: chapter.pages || [],
        prevChapterNumber: prevChapter ? prevChapter.number : null,
        nextChapterNumber: nextChapter ? nextChapter.number : null,
        mangaId: manga.id
      }));

      openReader();
    };


    const readBtn = document.getElementById("read-btn");
    if (readBtn) {
      readBtn.addEventListener("click", () => {
        if (sortedAsc.length > 0) window.openChapter(sortedAsc[0].number);
      });
    }

    // حدّث النصوص حسب اللغة بعد بناء الصفحة
    setTimeout(() => updateUIText?.(), 50);

    renderChapters();
  }

  /* ===== التايم لاين ===== */
  function renderTimeline() {
    const content = document.getElementById("timeline-content");
    if (!content) return;

    const newList = (mangaList || []).filter(m => m.new_chapter && m.updated_at);
    if (newList.length === 0) {
      content.innerHTML = `<div class="empty-state" style="margin-top:60px;">
        <svg width="48" height="48" viewBox="0 0 24 24" fill="none"><circle cx="12" cy="12" r="9" stroke="#8E8696" stroke-width="1.5"/><path d="M12 7v5l3 3" stroke="#8E8696" stroke-width="1.5" stroke-linecap="round"/></svg>
        <div class="empty-state-title">لا توجد تحديثات</div>
        <div class="empty-state-text">ما في فصول جديدة حالياً</div>
      </div>`;
      return;
    }

    const now = new Date();
    const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const yesterday = new Date(today - 86400000);
    const weekAgo = new Date(today - 7 * 86400000);

    const groups = { today: [], yesterday: [], week: [], older: [] };
    newList.forEach(m => {
      const d = new Date(m.updated_at);
      const day = new Date(d.getFullYear(), d.getMonth(), d.getDate());
      if (day >= today) groups.today.push(m);
      else if (day >= yesterday) groups.yesterday.push(m);
      else if (day >= weekAgo) groups.week.push(m);
      else groups.older.push(m);
    });

    function timeAgo(dateStr) {
      const diff = Math.floor((now - new Date(dateStr)) / 1000);
      if (diff < 60) return "الآن";
      if (diff < 3600) return `قبل ${Math.floor(diff/60)} دقيقة`;
      if (diff < 86400) return `قبل ${Math.floor(diff/3600)} ساعة`;
      if (diff < 172800) return "الأمس";
      return new Date(dateStr).toLocaleDateString("ar-IQ", { month: "short", day: "numeric" });
    }

    function renderGroup(label, items) {
      if (!items.length) return "";
      return `
        <div class="timeline-group">
          <div class="timeline-day-label">${label}</div>
          ${items.map(m => `
            <div class="timeline-item" onclick="selectManga('${m.id}')">
              <div class="timeline-cover" style="background-image:url('${m.cover}');"></div>
              <div class="timeline-info">
                <div class="timeline-title">${m.title}</div>
                <div class="timeline-chapter">الفصل ${m.new_chapter}</div>
                ${m.genres && m.genres.length ? `<div class="timeline-genres">${m.genres.slice(0,2).join(' · ')}</div>` : ''}
                <div class="timeline-time">${timeAgo(m.updated_at)}</div>
              </div>
              <svg class="timeline-arrow" width="18" height="18" viewBox="0 0 24 24" fill="none"><path d="M9 18l-6-6 6-6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>
            </div>
          `).join("")}
        </div>`;
    }

    content.innerHTML =
      renderGroup("اليوم", groups.today) +
      renderGroup("الأمس", groups.yesterday) +
      renderGroup(t("thisWeek"), groups.week) +
      renderGroup(t("older"), groups.older);
  }

  /* ===== أكمل القراءة ===== */
  async function resumeReading(mangaId, chapterNumber) {
    try {
      let manga = (mangaList || []).find(m => m.id === mangaId);
      if (!manga) {
        const res = await fetch(DATA_BASE_URL + "manga-list.json?t=" + Date.now(), { cache: "no-store" });
        manga = (await res.json()).find(m => m.id === mangaId);
      }
      if (!manga) return;

      // حمّل الفصول
      if (!manga.chaptersList) {
        const r = await fetch(DATA_BASE_URL + "chapters-" + mangaId + ".json?t=" + Date.now(), { cache: "no-store" });
        manga.chaptersList = await r.json();
      }

      // ضبط selectedManga حتى أزرار التالي/السابق تشتغل
      selectedManga = manga;

      // افتح الفصل عبر openChapter الرسمي حتى كل المنطق يشتغل
      const sortedAsc = [...manga.chaptersList].sort((a, b) => Number(a.number) - Number(b.number));
      const chapter = manga.chaptersList.find(c => Number(c.number) === Number(chapterNumber));
      if (!chapter) { selectManga(mangaId); return; }

      const idx = sortedAsc.findIndex(c => Number(c.number) === Number(chapter.number));
      const prevChapter = sortedAsc[idx - 1] || null;
      const nextChapter = sortedAsc[idx + 1] || null;

      localStorage.setItem("reader_data", JSON.stringify({
        mangaTitle: manga.title,
        chapterNumber: chapter.number,
        pages: chapter.pages || [],
        prevChapterNumber: prevChapter ? prevChapter.number : null,
        nextChapterNumber: nextChapter ? nextChapter.number : null,
        mangaId: manga.id
      }));

      openReader();
    } catch(e) { selectManga(mangaId); }
  }

  function getContinueReading() {
    try { return JSON.parse(localStorage.getItem("continue_reading") || "[]"); }
    catch(e) { return []; }
  }

  function renderContinueReading() {
    const list = getContinueReading();
    const section = document.getElementById("continue-reading-section");
    const container = document.getElementById("continue-reading-list");
    if (!section || !container) return;
    if (list.length === 0) { section.style.display = "none"; return; }

    section.style.display = "";
    container.innerHTML = list.map(item => `
      <div class="continue-card" onclick="resumeReading('${item.mangaId}', ${item.chapterNumber})">
        <div class="continue-cover" style="background-image:url('${item.cover}');"></div>
        <div class="continue-info">
          <div class="continue-title">${item.mangaTitle}</div>
          <div class="continue-chapter">${t("chapterWord")} ${item.chapterNumber} ${_appLang==="en"?"of":"من"} ${item.totalChapters}</div>
          <div class="continue-progress">
            <div class="continue-progress-fill" style="width:${Math.round((item.chapterNumber / item.totalChapters) * 100)}%;"></div>
          </div>
        </div>
        <div class="continue-play">
          <svg width="14" height="14" viewBox="0 0 24 24" fill="white"><path d="M6 4L20 12L6 20V4Z"/></svg>
        </div>
      </div>
    `).join("");
  }

  /* ===== تصنيفات المفضلة ===== */
  let _favCurrentCat = "all";
  let _favCatMenuMangaId = null;
  const FAV_CAT_LABELS = () => ({ reading:t("reading"), planread:t("planRead"), paused:t("paused"), completed:t("completedCat"), none:"—" });

  function setFavCategory(cat) {
    _favCurrentCat = cat;
    document.querySelectorAll(".fav-cat-btn").forEach(b => {
      b.classList.toggle("active", b.dataset.cat === cat);
    });
    renderFavoritesPage();
  }

  function openFavCatMenu(mangaId) {
    _favCatMenuMangaId = mangaId;
    const favs = getFavorites();
    const fav = favs.find(f => f.id === mangaId);
    const titleEl = document.getElementById("fav-cat-menu-manga-title");
    if (titleEl) titleEl.textContent = fav?.title || "";
    // تمييز التصنيف الحالي
    const cur = fav?.category || "none";
    document.querySelectorAll(".fav-cat-menu-item").forEach(el => {
      el.classList.toggle("selected", el.dataset.cat === cur);
    });
    document.getElementById("fav-cat-menu").classList.add("show");
    document.getElementById("fav-cat-overlay").style.display = "block";
  }

  function closeFavCatMenu() {
    document.getElementById("fav-cat-menu").classList.remove("show");
    document.getElementById("fav-cat-overlay").style.display = "none";
    _favCatMenuMangaId = null;
  }

  function applyFavCategory(cat) {
    if (!_favCatMenuMangaId) return;
    let favs = getFavorites();
    const idx = favs.findIndex(f => f.id === _favCatMenuMangaId);
    if (idx >= 0) {
      if (cat === "none") delete favs[idx].category;
      else favs[idx].category = cat;
      localStorage.setItem("manga_favorites", JSON.stringify(favs));
    }
    closeFavCatMenu();
    renderFavoritesPage();
  }

  /* ===== المفضلة ===== */
  function getFavHeart(mangaId) {
    const isFav = getFavorites().some(f => f.id === mangaId);
    return isFav
      ? `<svg viewBox="0 0 24 24" fill="#E63946"><path d="M12 21C12 21 3 14 3 8.5C3 5.4 5.4 3 8.5 3C10.2 3 11.7 3.8 12 5C12.3 3.8 13.8 3 15.5 3C18.6 3 21 5.4 21 8.5C21 14 12 21 12 21Z"/></svg>`
      : `<svg viewBox="0 0 24 24" fill="none"><path d="M12 21C12 21 3 14 3 8.5C3 5.4 5.4 3 8.5 3C10.2 3 11.7 3.8 12 5C12.3 3.8 13.8 3 15.5 3C18.6 3 21 5.4 21 8.5C21 14 12 21 12 21Z" stroke="white" stroke-width="2"/></svg>`;
  }

  function makeFavBtn(m) {
    const mStr = encodeURIComponent(JSON.stringify(m));
    return `<div class="cover-fav-btn" onclick="event.stopPropagation();checkLoginAndFav(JSON.parse(decodeURIComponent('${mStr}')),this);">${getFavHeart(m.id)}</div>`;
  }

  function getFavorites() {
    try { return JSON.parse(localStorage.getItem("manga_favorites") || "[]"); }
    catch (e) { return []; }
  }

  function checkLoginAndFav(manga, el) {
    const session = getSession();
    if (!session) { goToPage("profile"); return; }
    toggleFavorite(manga);
    if (el) el.innerHTML = getFavHeart(manga.id);
  }

  function toggleFavorite(manga) {
    const TYPE_STATUS = ["مانغا","مانهوا","manhwa","manga","مستمرة","مكتملة","ongoing","completed","finished"];
    let favs = getFavorites();
    const idx = favs.findIndex(f => f.id === manga.id);
    if (idx >= 0) {
      favs.splice(idx, 1);
    } else {
      // نحفظ التصنيفات فقط بدون النوع والحالة
      const genres = (manga.genres || []).filter(g => !TYPE_STATUS.includes(g.toLowerCase().trim()) && !TYPE_STATUS.includes(g.trim()));
      favs.push({ id: manga.id, title: manga.title, cover: manga.cover, rating: manga.rating, genres: genres.slice(0,3) });
    }
    localStorage.setItem("manga_favorites", JSON.stringify(favs));
    updateFavoritesCount();
  }

  function updateFavoritesCount() {
    const count = getFavorites().length;
    const sub = document.getElementById("favorites-count-sub");
    if (sub) sub.textContent = count > 0 ? `${count} مانغا محفوظة` : "المانغا المحفوظة";
  }

  let _favSelectMode = false;
  let _favSelected = new Set();

  function renderFavoritesPage() {
    let favs = getFavorites();
    const grid = document.getElementById("favorites-grid");
    const empty = document.getElementById("favorites-empty");
    if (!grid) return;
    _favSelectMode = false;
    _favSelected.clear();
    document.getElementById("fav-select-bar").classList.remove("show");

    // فلترة حسب التصنيف
    const filtered = _favCurrentCat === "all" ? favs : favs.filter(f => f.category === _favCurrentCat);

    if (filtered.length === 0) {
      grid.innerHTML = "";
      empty.style.display = "block";
      empty.querySelector("div:last-child").textContent = _favCurrentCat === "all"
        ? "ما أضفت أي مانغا للمفضلة بعد"
        : "ما في مانغا بهذا التصنيف";
      return;
    }
    empty.style.display = "none";
    grid.className = "grid-3-v2";
    grid.style.padding = "0 12px";
    const CAT_COLORS = { reading:"#9B5CF6", planread:"#3B82F6", paused:"#F59E0B", completed:"#10B981" };
    const CAT_LABELS = FAV_CAT_LABELS();
    grid.innerHTML = filtered.map(m => `
      <div class="grid-item-v2" data-id="${m.id}" data-title="${m.title.replace(/"/g,'&quot;')}"
        onclick="onFavCardClick(event,'${m.id}')"
        oncontextmenu="event.preventDefault();enterFavSelectMode('${m.id}')">
        <div class="cover" style="background-image:url('${m.cover}');background-size:cover;background-position:center;">
          <div class="cover-rating-badge">★ ${m.rating}</div>
          ${m.category ? `<div style="position:absolute;bottom:6px;right:6px;background:${CAT_COLORS[m.category]};color:white;font-size:9px;font-weight:700;padding:2px 6px;border-radius:6px;font-family:'Tajawal',sans-serif;">${FAV_CAT_LABELS()[m.category]}</div>` : ''}
        </div>
        <div class="item-title">${truncateTitle(m.title, 14)}</div>
        <div class="item-stars">${renderStars(m.rating)}</div>
        <button onclick="event.stopPropagation();openFavCatMenu('${m.id}')" style="background:rgba(191,95,255,0.1);border:1px solid rgba(191,95,255,0.2);border-radius:6px;padding:3px 8px;font-size:10px;color:#C9B6F5;cursor:pointer;font-family:'Tajawal',sans-serif;width:100%;margin-top:3px;">${m.category ? FAV_CAT_LABELS()[m.category] : t('addCategory')}</button>
      </div>
    `).join("");
  }

  function onFavCardClick(e, id) {
    if (_favSelectMode) {
      e.stopPropagation();
      toggleFavSelect(id);
    } else {
      selectManga(id);
    }
  }

  function enterFavSelectMode(id) {
    _favSelectMode = true;
    _favSelected.clear();
    _favSelected.add(id);
    updateFavSelectUI();
    document.getElementById("fav-select-bar").classList.add("show");
  }

  function toggleFavSelect(id) {
    if (_favSelected.has(id)) _favSelected.delete(id);
    else _favSelected.add(id);
    if (_favSelected.size === 0) cancelFavSelect();
    else updateFavSelectUI();
  }

  function updateFavSelectUI() {
    document.querySelectorAll("#favorites-grid .grid-item-v2").forEach(card => {
      card.classList.toggle("selected", _favSelected.has(card.dataset.id));
    });
    const count = _favSelected.size;
    document.getElementById("fav-select-count").textContent = count + " محدد";
  }

  function cancelFavSelect() {
    _favSelectMode = false;
    _favSelected.clear();
    document.getElementById("fav-select-bar").classList.remove("show");
    document.querySelectorAll("#favorites-grid .grid-item-v2").forEach(c => c.classList.remove("selected"));
  }

  function deleteSelectedFavs() {
    if (_favSelected.size === 0) return;
    const count = _favSelected.size;
    document.getElementById("confirm-manga-name").textContent =
      count === 1 ? "سيتم حذف هذه المانغا من مفضلتك" : `سيتم حذف ${count} مانغا من مفضلتك`;
    document.getElementById("confirm-overlay").dataset.pendingIds = JSON.stringify([..._favSelected]);
    document.getElementById("confirm-overlay").classList.add("show");
  }

  // Long press للمفضلة - يدخل وضع التحديد
  let _lpTimer = null;
  document.addEventListener("touchstart", function(e) {
    if (document.getElementById("favorites-page")?.classList.contains("active")) {
      const card = e.target.closest("#favorites-grid .grid-item-v2");
      if (!card) return;
      _lpTimer = setTimeout(() => {
        _lpTimer = null;
        enterFavSelectMode(card.dataset.id);
      }, 500);
    }
  }, { passive: true });
  document.addEventListener("touchend", () => { clearTimeout(_lpTimer); _lpTimer = null; }, { passive: true });
  document.addEventListener("touchmove", () => { clearTimeout(_lpTimer); _lpTimer = null; }, { passive: true });



  const SWIPE_THRESHOLD = 80;
  const SWIPE_DELETE_AT  = 180;

  function bindFavSwipe(wrap) {
    const item = wrap.querySelector(".fav-item");
    const deleteBg = wrap.querySelector(".fav-delete-bg");
    let startX = 0, startY = 0, currentX = 0, dragging = false, opened = false, directionLocked = false, isHorizontal = false;

    item.addEventListener("touchstart", e => {
      startX = e.touches[0].clientX;
      startY = e.touches[0].clientY;
      dragging = true;
      directionLocked = false;
      isHorizontal = false;
      item.classList.remove("snapping");
    }, { passive: true });

    item.addEventListener("touchmove", e => {
      if (!dragging) return;
      const dx = e.touches[0].clientX - startX;
      const dy = e.touches[0].clientY - startY;

      if (!directionLocked) {
        if (Math.abs(dx) < 5 && Math.abs(dy) < 5) return;
        isHorizontal = Math.abs(dx) > Math.abs(dy);
        directionLocked = true;
      }
      if (!isHorizontal) return;

      e.preventDefault();
      const base = opened ? SWIPE_THRESHOLD : 0;
      // السحب لليمين فقط (dx موجب)
      currentX = Math.max(0, Math.min(base + dx, SWIPE_DELETE_AT + 40));
      item.style.transform = `translateX(${currentX}px)`;
    }, { passive: false });

    item.addEventListener("touchend", () => {
      if (!dragging) return;
      dragging = false;
      item.classList.add("snapping");
      const mangaId = wrap.dataset.id;
      if (currentX > SWIPE_DELETE_AT) {
        item.style.transform = `translateX(110%)`;
        setTimeout(() => {
          // رجّع العنصر وافتح تأكيد الحذف
          item.style.transition = "transform 0.2s ease";
          item.style.transform = "translateX(0)";
          opened = false; currentX = 0;
          showConfirmDelete(mangaId, wrap.dataset.title || "");
        }, 180);
      } else if (currentX > SWIPE_THRESHOLD / 2) {
        currentX = SWIPE_THRESHOLD;
        item.style.transform = `translateX(${SWIPE_THRESHOLD}px)`;
        opened = true;
      } else {
        item.style.transform = "translateX(0)";
        currentX = 0;
        opened = false;
      }
    });
  }

  function removeFavorite(mangaId) {
    let favs = getFavorites().filter(f => f.id !== mangaId);
    localStorage.setItem("manga_favorites", JSON.stringify(favs));
  }

  function closeConfirm() {
    document.getElementById("confirm-overlay").classList.remove("show");
  }
  function confirmDeleteFav() {
    const overlay = document.getElementById("confirm-overlay");
    const ids = JSON.parse(overlay.dataset.pendingIds || "[]");
    if (ids.length === 0) return;
    let favs = getFavorites().filter(f => !ids.includes(f.id));
    localStorage.setItem("manga_favorites", JSON.stringify(favs));
    cancelFavSelect();
    renderFavoritesPage();
    updateFavoritesCount();
    closeConfirm();
  }
  function getReadChapters(mangaId) {
    try { return JSON.parse(localStorage.getItem("read_progress_" + mangaId) || "[]"); }
    catch (e) { return []; }
  }

  function markChapterAsRead(mangaId, chapterNumber) {
    const list = getReadChapters(mangaId);
    if (!list.includes(chapterNumber)) {
      list.push(chapterNumber);
      localStorage.setItem("read_progress_" + mangaId, JSON.stringify(list));
    }
    // إذا كانت هذه المانغا مفتوحة حالياً في صفحة التفاصيل، حدّث الشريط فوراً
    if (currentManga && currentManga.id === mangaId) renderReadingProgress(currentManga);
  }

  function renderReadingProgress(manga) {
    const container = document.getElementById("reading-progress-container");
    if (!container) return;
    const total = (manga.chaptersList || []).length;
    if (total === 0) { container.innerHTML = ""; return; }

    const readList = getReadChapters(manga.id);
    const readCount = readList.filter(n => manga.chaptersList.some(c => c.number === n)).length;
    const furthest = readList.length ? Math.max(...readList) : 0;
    const percent = Math.min(100, Math.round((readCount / total) * 100));

    container.innerHTML = `
      <div class="reading-progress-wrap">
        <div class="reading-progress-top">
          <span class="reading-progress-label">${furthest > 0 ? `وصلت للفصل ${furthest} · اكتمل ${percent}%` : "لم تبدأ القراءة بعد"}</span>
          <span class="reading-progress-value">${readCount} / ${total}</span>
        </div>
        <div class="reading-progress-bar">
          <div class="reading-progress-fill" style="width:${percent}%;"></div>
        </div>
      </div>
    `;
  }

  /* ===== القارئ المدمج ===== */

  const WORKER_BASE_URL = "https://manga-layer.akramfaeq523.workers.dev/?id=";

  // تحويل أي شكل بيانات للصفحة لرابط صورة صالح
  function resolvePageUrl(p) {
    if (!p) return "";
    let id = typeof p === "string" ? p : (p.url || p.image || p.src || p.link || "");
    if (!id) return "";
    // إذا كان رابط كامل يرجعه مباشرة
    if (/^https?:\/\//i.test(id)) return id;
    // Telegram file_id → يحوّله عبر Cloudflare Worker
    return WORKER_BASE_URL + encodeURIComponent(id);
  }

  // يرسم محتوى القارئ فقط (بدون تغيير الصفحة أو السجل)
  function _openReaderContent() {
    const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
    document.getElementById("reader-manga-title").textContent = data.mangaTitle || "—";
    document.getElementById("reader-chapter-title").textContent = `${t("chapterWord")} ${data.chapterNumber}`;
    // الزر السابق: الفصل الأول → باهت (مازال قابل للضغط ويرجع للتفاصيل)
    document.getElementById("reader-prev-btn").disabled = false;
    document.getElementById("reader-next-btn").disabled = false;
    // حدّث حالة الأزرار من selectedManga
    if (selectedManga && selectedManga.chaptersList) {
      const sortedAsc = [...selectedManga.chaptersList].sort((a, b) => Number(a.number) - Number(b.number));
      const idx = sortedAsc.findIndex(c => Number(c.number) === Number(data.chapterNumber));
      document.getElementById("reader-prev-btn").classList.toggle("dim", idx <= 0);
      document.getElementById("reader-next-btn").classList.toggle("dim", idx >= sortedAsc.length - 1);
    }
    const wrap = document.getElementById("reader-pages-wrap");
    // نزيل الـ footer القديم إذا كان موجوداً (عند الانتقال لفصل جديد)
    const oldFooter = document.querySelector(".reader-progress-footer");
    if (oldFooter) oldFooter.remove();

    // ريست الزوم
    const zi = document.getElementById("reader-zoom-inner");
    if (zi) { zi.style.transform = ""; }

    if (data.pages && data.pages.length > 0) {
      const pagesHtml = data.pages.map((p, i) => {
        const url = resolvePageUrl(p);
        return `<img class="reader-page-img" src="${url}" loading="eager" data-page="${i}"
                  onload="this.classList.add('loaded');updateReaderProgress();"
                  onerror="this.outerHTML='<div class=\'reader-page-img img-broken\'>تعذر تحميل هذه الصفحة</div>';">`;
      }).join("");
      if (zi) { zi.innerHTML = pagesHtml; }
      else { wrap.innerHTML = pagesHtml; }
    } else {
      const msg = `<div class="reader-loading">لا توجد صفحات لهذا الفصل</div>`;
      if (zi) { zi.innerHTML = msg; }
      else { wrap.innerHTML = msg; }
    }

    if (data.mangaId && data.chapterNumber) markChapterAsRead(data.mangaId, data.chapterNumber);

    const totalPages = (data.pages && data.pages.length) || 1;
    const footerHtml = `
      <div class="reader-progress-footer">
        <div class="reader-progress-bar-small" style="flex:1;">
          <div class="reader-progress-fill-small" id="reader-progress-fill" style="width:0%;"></div>
        </div>
      </div>
    `;
    wrap.insertAdjacentHTML('afterend', footerHtml);
    // طبّق الوضع الحالي بعد بناء الصفحات (يضمن الـ listener يشتغل)
    setTimeout(() => {
      applyReadingMode();
      refreshModeButtons();
    }, 150);
  }

  // يفتح القارئ من خارجه (يضيف "reader" للسجل)
  let _readerTimer = null;

  function openReader() {
    _openReaderContent();
    goToPage("reader");
    _lastScrollY = 0;
    const topbar = document.querySelector(".reader-topbar");
    if (topbar) topbar.classList.remove("hidden");
    const footer2 = document.querySelector(".reader-progress-footer");
    if (footer2) footer2.classList.remove("hidden");

    // طبّق وضع القراءة المحفوظ
    applyReadingMode();

    // استعد موضع السكرول المحفوظ
    const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
    if (data.mangaId && data.chapterNumber) {
      const key = `read_pos_${data.mangaId}_${data.chapterNumber}`;
      const savedY = parseInt(localStorage.getItem(key) || "0");
      if (savedY > 0) {
        setTimeout(() => {
          window.scrollTo({ top: savedY, behavior: "instant" });
          _lastScrollY = savedY;
        }, 300); // نستنى الصور تبدأ تتحمل
      }
    }

    // إخفاء أزرار الأندرويد عبر أول لمسة (متصفح يسمح بعدها)
    const _fsOnce = () => {
      if (document.documentElement.requestFullscreen && !document.fullscreenElement) {
        document.documentElement.requestFullscreen().catch(() => {});
      }
      document.removeEventListener("touchstart", _fsOnce);
    };
    document.addEventListener("touchstart", _fsOnce, { once: true });
    clearTimeout(_readerTimer);
    _readerTimer = setTimeout(() => {
      const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
      if (!data.mangaId) return;
      const continueList = getContinueReading();
      const existing = continueList.findIndex(c => c.mangaId === data.mangaId);
      const totalChapters = (mangaList || []).find(m => m.id === data.mangaId)?.chapters || "?";
      const entry = {
        mangaId: data.mangaId,
        mangaTitle: data.mangaTitle,
        cover: (mangaList || []).find(m => m.id === data.mangaId)?.cover || "",
        chapterNumber: data.chapterNumber,
        totalChapters,
        timestamp: Date.now()
      };
      if (existing >= 0) continueList.splice(existing, 1);
      continueList.unshift(entry);
      localStorage.setItem("continue_reading", JSON.stringify(continueList.slice(0, 10)));
    }, 10 * 1000);
  }

  function updateReaderProgress() {
    if (currentPage !== "reader") return;
    const fillEl = document.getElementById("reader-progress-fill");
    const footer = document.querySelector(".reader-progress-footer");
    if (!fillEl) return;

    if (_readingMode === "horizontal") {
      const zi = document.getElementById("reader-zoom-inner");
      if (!zi) return;
      if (footer) footer.style.opacity = "1";
      const maxScroll = zi.scrollWidth - zi.clientWidth;
      if (maxScroll <= 0) return;
      const rawScroll = Math.abs(zi.scrollLeft);

      let percent;
      if (_appLang === "en") {
        percent = (rawScroll / maxScroll) * 100;
        fillEl.style.cssText = `width:${Math.min(100,percent)}%;height:100%;background:#E8B85C;border-radius:999px;transition:width 0.25s ease;margin-left:0;margin-right:auto;`;
      } else {
        // direction:ltr على zi → scrollLeft=0 عند صفحة 1، يكبر مع التقدم
        // نريد يمتلئ من اليمين → margin-left:auto + نسبة عادية
        percent = (rawScroll / maxScroll) * 100;
        fillEl.style.cssText = `width:${Math.min(100,percent)}%;height:100%;background:#E8B85C;border-radius:999px;transition:width 0.25s ease;margin-left:auto;margin-right:0;`;
      }
      return;
    }

    if (footer) {
      footer.style.opacity = "1";
      footer.style.direction = ""; // يرجع للـ dir الأصلي للصفحة
    }
    const wrap = document.getElementById("reader-pages-wrap");
    if (!wrap) return;
    const wrapTop = wrap.getBoundingClientRect().top + window.scrollY;
    const wrapHeight = wrap.scrollHeight;
    if (wrapHeight <= 0) return;
    const percent = Math.max(0, Math.min(100, ((window.scrollY + window.innerHeight - wrapTop) / wrapHeight) * 100));
    fillEl.style.width = percent + "%";

    if (percent >= 95) {
      const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
      if (data.mangaId) {
        const continueList = getContinueReading().filter(c => c.mangaId !== data.mangaId);
        localStorage.setItem("continue_reading", JSON.stringify(continueList));
        clearTimeout(_readerTimer);
      }
    }
  }

  // إخفاء/إظهار هيدر القارئ عند السكرول
  let _lastScrollY = 0;
  let _scrollSaveTimer = null;
  document.addEventListener("DOMContentLoaded", () => {
    const zi = document.getElementById("reader-zoom-inner");
    if (zi) {
      zi.addEventListener("scroll", () => {
        if (currentPage === "reader" && _readingMode === "horizontal") {
          updateReaderProgress();
          clearTimeout(_scrollSaveTimer);
          _scrollSaveTimer = setTimeout(() => {
            const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
            if (data.mangaId && data.chapterNumber) {
              localStorage.setItem(`read_pos_${data.mangaId}_${data.chapterNumber}_h`, zi.scrollLeft);
            }
          }, 1000);
        }
      }, { passive: true });
    }
  });
  // إخفاء عند التمرير، إظهار عند الضغط — بالوضعين
  let _tapTimeout = null;

  function _readerShowBars() {
    const topbar = document.querySelector(".reader-topbar");
    const footer = document.querySelector(".reader-progress-footer");
    if (topbar) topbar.classList.remove("hidden");
    if (footer) footer.classList.remove("hidden");
  }
  function _readerHideBars() {
    const topbar = document.querySelector(".reader-topbar");
    const footer = document.querySelector(".reader-progress-footer");
    if (topbar) topbar.classList.add("hidden");
    if (footer) footer.classList.add("hidden");
  }

  document.addEventListener("click", e => {
    if (currentPage !== "reader") return;
    if (e.target.closest("button, a, .reader-topbar, .reader-progress-footer, #chapters-dropdown, #mode-dropdown, #reader-overlay")) return;
    const topbar = document.querySelector(".reader-topbar");
    if (!topbar) return;
    clearTimeout(_tapTimeout);
    if (topbar.classList.contains("hidden")) {
      _readerShowBars();
      _tapTimeout = setTimeout(_readerHideBars, 3000);
    } else {
      _readerHideBars();
    }
  });

  // الوضع الأفقي — إخفاء عند السحب
  document.getElementById("reader-zoom-inner")?.addEventListener("scroll", () => {
    if (currentPage !== "reader" || _readingMode !== "horizontal") return;
    clearTimeout(_tapTimeout);
    _readerHideBars();
  }, { passive: true });

  window.addEventListener("scroll", () => {
    if (currentPage === "reader") {
      updateReaderProgress();
      clearTimeout(_scrollSaveTimer);
      _scrollSaveTimer = setTimeout(() => {
        const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
        if (data.mangaId && data.chapterNumber) {
          localStorage.setItem(`read_pos_${data.mangaId}_${data.chapterNumber}`, window.scrollY);
        }
      }, 1000);
      if (_readingMode === "horizontal") return;
      // تتبع الصفحة الأكثر ظهوراً بالشاشة
      const wrap2 = document.getElementById("reader-pages-wrap");
      if (wrap2) {
        const imgs2 = wrap2.querySelectorAll(".reader-page-img");
        let maxVisibleArea = 0;
        let mostVisibleIdx = _currentPageIdx;
        imgs2.forEach((img, i) => {
          const rect = img.getBoundingClientRect();
          const visibleHeight = Math.max(0, Math.min(rect.bottom, window.innerHeight) - Math.max(rect.top, 0));
          if (visibleHeight > maxVisibleArea) {
            maxVisibleArea = visibleHeight;
            mostVisibleIdx = i;
          }
        });
        if (maxVisibleArea > 0) _currentPageIdx = mostVisibleIdx;
      }
      const topbar = document.querySelector(".reader-topbar");
      if (!topbar) return;
      const currentY = window.scrollY;
      const footer = document.querySelector(".reader-progress-footer");
      if (currentY > _lastScrollY + 10) {
        clearTimeout(_tapTimeout);
        _readerHideBars();
      } else if (currentY < _lastScrollY - 5) {
        _readerShowBars();
      }
      _lastScrollY = currentY;
    }
  }, { passive: true });

  function closeReader() {
    clearTimeout(_readerTimer);
    // احفظ موضع السكرول قبل الخروج
    const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
    if (data.mangaId && data.chapterNumber) {
      const key = `read_pos_${data.mangaId}_${data.chapterNumber}`;
      localStorage.setItem(key, window.scrollY);
    }
    if (document.exitFullscreen && document.fullscreenElement) {
      document.exitFullscreen().catch(() => {});
    }
    goBack();
  }

  // ===== قوائم القارئ المنسدلة =====
  function closeReaderDropdowns() {
    const chapDd = document.getElementById("chapters-dropdown");
    const modeDd = document.getElementById("mode-dropdown");
    const overlay = document.getElementById("reader-overlay");
    const arrow = document.getElementById("chapters-drop-arrow");
    if (chapDd) chapDd.style.display = "none";
    if (modeDd) modeDd.style.display = "none";
    if (overlay) overlay.style.display = "none";
    if (arrow) arrow.style.transform = "";
  }

  function toggleChaptersDropdown() {
    const dd = document.getElementById("chapters-dropdown");
    const modeDd = document.getElementById("mode-dropdown");
    const overlay = document.getElementById("reader-overlay");
    const arrow = document.getElementById("chapters-drop-arrow");
    const isOpen = dd.style.display !== "none";
    if (modeDd) modeDd.style.display = "none";
    if (isOpen) {
      dd.style.display = "none";
      if (overlay) overlay.style.display = "none";
      if (arrow) arrow.style.transform = "";
    } else {
      populateReaderChapters();
      dd.style.display = "block";
      if (overlay) overlay.style.display = "block";
      if (arrow) arrow.style.transform = "rotate(180deg)";
    }
  }

  function toggleModeDropdown() {
    const dd = document.getElementById("mode-dropdown");
    const chapDd = document.getElementById("chapters-dropdown");
    const overlay = document.getElementById("reader-overlay");
    const isOpen = dd.style.display !== "none";
    chapDd.style.display = "none";
    document.getElementById("chapters-drop-arrow").style.transform = "";
    if (isOpen) {
      dd.style.display = "none";
      overlay.style.display = "none";
    } else {
      dd.style.display = "block";
      overlay.style.display = "block";
    }
  }

  function populateReaderChapters() {
    const listEl = document.getElementById("reader-chapters-list");
    if (!listEl || !selectedManga || !selectedManga.chaptersList) return;
    const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
    const sorted = [...selectedManga.chaptersList].sort((a, b) => Number(b.number) - Number(a.number));
    listEl.innerHTML = sorted.map(ch => {
      const isCurrent = Number(ch.number) === Number(data.chapterNumber);
      const isLight = document.documentElement.classList.contains('light-theme') || document.body.classList.contains('light-theme');
      const activeBg = isLight ? 'rgba(63,94,251,0.2)' : 'rgba(155,40,255,0.2)';
      const activeBorder = isLight ? 'rgba(63,94,251,0.45)' : 'rgba(155,40,255,0.45)';
      const activeColor = isLight ? '#3F5EFB' : '#C9B6F5';
      const activeDot = isLight ? '#3F5EFB' : '#9B5CF6';
      return `<div onclick="readerJumpToChapter(${ch.number})" style="padding:11px 12px;border-radius:10px;margin-bottom:5px;background:${isCurrent ? activeBg : 'rgba(255,255,255,0.03)'};border:1px solid ${isCurrent ? activeBorder : 'rgba(255,255,255,0.06)'};cursor:pointer;display:flex;justify-content:space-between;align-items:center;">
        <span style="font-size:13px;font-weight:${isCurrent ? '700' : '500'};color:${isCurrent ? activeColor : '#E2DEF0'};">${t("chapterWord")} ${ch.number}</span>
        ${isCurrent ? `<span style="width:7px;height:7px;border-radius:50%;background:${activeDot};display:inline-block;"></span>` : ''}
      </div>`;
    }).join("");
    // نسكرول للفصل الحالي
    setTimeout(() => {
      const cur = listEl.querySelector('[style*="rgba(155,40,255,0.2)"]');
      if (cur) cur.scrollIntoView({ block: "center" });
    }, 50);
  }

  function readerJumpToChapter(chapterNum) {
    if (!selectedManga || !selectedManga.chaptersList) return;
    const chapter = selectedManga.chaptersList.find(c => Number(c.number) === Number(chapterNum));
    if (!chapter) return;
    const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
    const sorted = [...selectedManga.chaptersList].sort((a, b) => Number(a.number) - Number(b.number));
    const idx = sorted.findIndex(c => Number(c.number) === Number(chapterNum));
    localStorage.setItem("reader_data", JSON.stringify({
      mangaTitle: data.mangaTitle, chapterNumber: chapter.number,
      pages: chapter.pages || [], mangaId: data.mangaId,
      prevChapterNumber: sorted[idx - 1]?.number || null,
      nextChapterNumber: sorted[idx + 1]?.number || null,
    }));
    closeReaderDropdowns();
    _openReaderContent();
    window.scrollTo({ top: 0, behavior: "instant" });
    applyReadingMode();
  }

  // ===== وضع القراءة =====
  let _readingMode = localStorage.getItem("reading_mode") || "vertical";
  let _currentPageIdx = 0; // يتتبع الصفحة الحالية بالوضعين

  function toggleModeDropdown() {
    const dd = document.getElementById("mode-dropdown");
    const overlay = document.getElementById("reader-overlay");
    if (!dd) return;
    const isOpen = dd.style.display !== "none";
    if (isOpen) {
      dd.style.display = "none";
      if (overlay) overlay.style.display = "none";
    } else {
      dd.style.display = "block";
      if (overlay) overlay.style.display = "block";
    }
  }

  function toggleReadingModeDirect() {
    const newMode = _readingMode === "vertical" ? "horizontal" : "vertical";
    setReadingMode(newMode);
  }

  function refreshModeButtons() {
    const toggle = document.getElementById("reader-mode-toggle");
    const svg = document.getElementById("mode-arrows-svg");
    if (_readingMode === "horizontal") {
      // دوّر السهمين 90° ليصيرا أفقيين
      if (svg) svg.style.transform = "rotate(90deg)";
      if (toggle) { toggle.style.borderColor = "rgba(155,40,255,0.6)"; toggle.style.background = "rgba(155,40,255,0.22)"; }
    } else {
      if (svg) svg.style.transform = "rotate(0deg)";
      if (toggle) { toggle.style.borderColor = "rgba(255,255,255,0.15)"; toggle.style.background = "rgba(255,255,255,0.07)"; }
    }
    // أزرار القائمة لو موجودة
    const vBtn = document.getElementById("mode-vertical-btn");
    const hBtn = document.getElementById("mode-horizontal-btn");
    if (vBtn && hBtn) {
      if (_readingMode === "vertical") {
        vBtn.style.border = "1.5px solid rgba(155,40,255,0.55)"; vBtn.style.background = "rgba(155,40,255,0.18)"; vBtn.style.color = "#E2DEF0";
        hBtn.style.border = "1.5px solid rgba(255,255,255,0.1)"; hBtn.style.background = "none"; hBtn.style.color = "#9B8FC0";
      } else {
        hBtn.style.border = "1.5px solid rgba(155,40,255,0.55)"; hBtn.style.background = "rgba(155,40,255,0.18)"; hBtn.style.color = "#E2DEF0";
        vBtn.style.border = "1.5px solid rgba(255,255,255,0.1)"; vBtn.style.background = "none"; vBtn.style.color = "#9B8FC0";
      }
    }
  }

  function setReadingMode(mode) {
    // استخدم الصفحة المحفوظة مباشرة
    const savedPage = _currentPageIdx;
    _readingMode = mode;
    localStorage.setItem("reading_mode", mode);
    const fillEl = document.getElementById("reader-progress-fill");
    if (fillEl) fillEl.style.width = "0%";
    applyReadingMode(savedPage);
    refreshModeButtons();
    const dd = document.getElementById("mode-dropdown");
    const overlay = document.getElementById("reader-overlay");
    if (dd) dd.style.display = "none";
    if (overlay) overlay.style.display = "none";
  }

  function applyReadingMode(pageIdx = 0) {
    const zi = document.getElementById("reader-zoom-inner");
    const wrap = document.getElementById("reader-pages-wrap");
    if (!zi) return;

    if (zi._hScrollHandler) {
      zi.removeEventListener("scroll", zi._hScrollHandler);
      zi._hScrollHandler = null;
    }

    if (_readingMode === "horizontal") {
      zi.classList.add("horizontal-mode");
      // بالإنجليزي الصور تمشي يسار لشمال (row)، بالعربي يمين لشمال (row-reverse)
      zi.style.flexDirection = _appLang === "en" ? "row" : "row-reverse";
      if (wrap) {
        wrap.style.padding = "0";
        wrap.style.height = "calc(100vh - 56px)";
        wrap.style.overflow = "hidden";
        wrap.style.display = "block";
      }
      // انتقل للصفحة المحفوظة بـ scrollIntoView - أدق من الحساب اليدوي
      setTimeout(() => {
        const allImgs = zi.querySelectorAll(".reader-page-img");
        if (allImgs[pageIdx]) {
          allImgs[pageIdx].scrollIntoView({ behavior: "instant", inline: "center", block: "nearest" });
          _currentPageIdx = pageIdx;
        }
      }, 100);
      const topbar = document.querySelector(".reader-topbar");
      const footer = document.querySelector(".reader-progress-footer");
      setTimeout(() => {
        if (topbar) topbar.classList.add("hidden");
        if (footer) footer.classList.add("hidden");
      }, 100);
      const handler = () => {
        updateReaderProgress();
        // تتبع الصفحة الحالية بالأفقي
        const pw = zi.clientWidth;
        const total = document.querySelectorAll(".reader-page-img").length || 1;
        if (pw > 0 && total > 1) {
          const scrollIdx = Math.round(Math.abs(zi.scrollLeft) / pw);
          // row-reverse (عربي): scrollLeft=0 → آخر صفحة
          // row (إنجليزي): scrollLeft=0 → أول صفحة
          _currentPageIdx = _appLang === "en" ? scrollIdx : total - 1 - scrollIdx;
        } else {
          _currentPageIdx = 0;
        }
      };
      zi._hScrollHandler = handler;
      zi.addEventListener("scroll", handler, { passive: true });
      setTimeout(updateReaderProgress, 300);
    } else {
      zi.classList.remove("horizontal-mode");
      if (wrap) {
        wrap.style.padding = "";
        wrap.style.height = "";
        wrap.style.overflow = "";
        wrap.style.display = "";
      }
      // انتقل للصفحة المحفوظة بالعمودي
      setTimeout(() => {
        const imgs = wrap ? wrap.querySelectorAll(".reader-page-img") : [];
        if (imgs[pageIdx]) {
          const top = imgs[pageIdx].getBoundingClientRect().top + window.scrollY - 70;
          window.scrollTo({ top: Math.max(0, top), behavior: "instant" });
          _currentPageIdx = pageIdx;
        }
      }, 50);
      const topbar = document.querySelector(".reader-topbar");
      const footer = document.querySelector(".reader-progress-footer");
      if (topbar) topbar.classList.remove("hidden");
      if (footer) footer.classList.remove("hidden");
      clearTimeout(_tapTimeout);
      setTimeout(updateReaderProgress, 100);
    }
  }

  function readerGoChapter(dir) {
    clearTimeout(_readerTimer);
    const data = JSON.parse(localStorage.getItem("reader_data") || "{}");
    if (!data.mangaId) return;

    const list = selectedManga && selectedManga.chaptersList ? selectedManga.chaptersList : null;
    if (!list || list.length === 0) return;

    const sortedAsc = [...list].sort((a, b) => Number(a.number) - Number(b.number));
    const currentIdx = sortedAsc.findIndex(c => Number(c.number) === Number(data.chapterNumber));
    if (currentIdx === -1) return;

    let targetIdx;
    if (dir === "prev") {
      if (currentIdx === 0) { goBack(); return; }
      targetIdx = currentIdx - 1;
    } else {
      if (currentIdx === sortedAsc.length - 1) return;
      targetIdx = currentIdx + 1;
    }

    const chapter = sortedAsc[targetIdx];
    if (!chapter) return;

    localStorage.setItem("reader_data", JSON.stringify({
      mangaTitle: data.mangaTitle,
      chapterNumber: chapter.number,
      pages: chapter.pages || [],
      prevChapterNumber: sortedAsc[targetIdx - 1]?.number || null,
      nextChapterNumber: sortedAsc[targetIdx + 1]?.number || null,
      mangaId: data.mangaId
    }));

    _openReaderContent();
    window.scrollTo({ top: 0, behavior: "instant" });

    // ابدأ عداد الحفظ للفصل الجديد
    clearTimeout(_readerTimer);
    _readerTimer = setTimeout(() => {
      const d = JSON.parse(localStorage.getItem("reader_data") || "{}");
      if (!d.mangaId) return;
      const continueList = getContinueReading();
      const existing = continueList.findIndex(c => c.mangaId === d.mangaId);
      const totalChapters = (mangaList || []).find(m => m.id === d.mangaId)?.chapters || "?";
      const entry = {
        mangaId: d.mangaId, mangaTitle: d.mangaTitle,
        cover: (mangaList || []).find(m => m.id === d.mangaId)?.cover || "",
        chapterNumber: d.chapterNumber, totalChapters, timestamp: Date.now()
      };
      if (existing >= 0) continueList.splice(existing, 1);
      continueList.unshift(entry);
      localStorage.setItem("continue_reading", JSON.stringify(continueList.slice(0, 10)));
    }, 10 * 1000);
  }

  /* ===== Firebase ===== */
  let pageHistory = ["home"];

  // goToPage العادي يضيف للسجل
  function goToPage(page) {
    _renderPage(page);
    if (pageHistory[pageHistory.length - 1] !== page) {
      pageHistory.push(page);
    }
  }

  // goBack لا يضيف للسجل (يستخدمه زر الرجوع فقط)
  function goBack() {
    if (pageHistory.length > 1) {
      pageHistory.pop();
      _renderPage(pageHistory[pageHistory.length - 1]);
    }
  }

  function _renderPage(page) {
    document.querySelectorAll(".page").forEach(p => p.classList.remove("active"));
    document.getElementById(page + "-page").classList.add("active");

    document.querySelectorAll(".nav-item").forEach(item => item.classList.remove("active"));
    const navMap = { home: "home", library: "library", search: "search", more: "more" };
    const activeNav = navMap[page];
    if (activeNav) document.querySelector(`.nav-item[data-page='${activeNav}']`)?.classList.add("active");

    document.body.classList.toggle("hide-nav", HIDE_NAV_PAGES.includes(page));
    currentPage = page;

    if (page === "home") {
      if (!mangaList || mangaList.length === 0) {
        setTimeout(() => loadMangaList(), 100);
      } else {
        setTimeout(() => loadHomeMangaList(), 50);
      }
    }
    if (page === "search") {
      // امسح البحث لو رجعنا من صفحة تفاصيل أو قارئ
      const prevPage = pageHistory[pageHistory.length - 2];
      if (prevPage === "details" || prevPage === "reader") {
        searchQuery = "";
        const inp = document.getElementById("search-input");
        const clr = document.getElementById("clear-btn");
        if (inp) inp.value = "";
        if (clr) clr.style.display = "none";
      }
      setTimeout(() => loadSearchLibrary(), 100);
    }
    if (page === "details") setTimeout(() => loadMangaDetails(), 100);
    if (page === "profile") onProfilePageOpen();
    if (page === "favorites") { updateFavoritesCount(); renderFavoritesPage(); }
    if (page === "timeline") setTimeout(() => renderTimeline(), 100);
    if (page === "more") updateMorePage();
    if (page === "library") setTimeout(() => renderLibraryPage(), 80);

    window.scrollTo({ top: 0, behavior: "instant" });
  }

  let _librarySortedByRating = false;

  function goToLibrarySorted() {
    _librarySortedByRating = true;
    goToPage("library");
  }

  function renderLibraryPage(list) {
    const grid = document.getElementById("library-full-grid");
    const countEl = document.getElementById("lib-count");
    const searchEl = document.getElementById("lib-search-input");
    if (searchEl) searchEl.value = "";
    let data = list || mangaList || [];
    if (_librarySortedByRating) {
      data = [...data].sort((a, b) => (parseFloat(b.rating) || 0) - (parseFloat(a.rating) || 0));
      _librarySortedByRating = false;
    }
    if (!grid) return;
    if (countEl) countEl.textContent = data.length + " مانغا";
    grid.innerHTML = data.map(m => renderGridItemV2(m)).join("");
    observeCovers(grid);
  }

  function filterLibrary(q) {
    const data = (mangaList || []).filter(m =>
      (m.title||"").toLowerCase().includes(q.toLowerCase()) ||
      (m.author||"").toLowerCase().includes(q.toLowerCase())
    );
    const grid = document.getElementById("library-full-grid");
    const countEl = document.getElementById("lib-count");
    if (countEl) countEl.textContent = data.length + " مانغا";
    if (grid) { grid.innerHTML = data.map(m => renderGridItemV2(m)).join(""); observeCovers(grid); }
  }

  /* ===== رسائل تختفي تلقائياً بعد ثانيتين ===== */
  function autoHideMsg(el, delay = 2000) {
    if (!el) return;
    clearTimeout(el._hideTimer);
    el._hideTimer = setTimeout(() => {
      el.style.transition = "opacity 0.4s ease";
      el.style.opacity = "0";
      setTimeout(() => { el.textContent = ""; el.style.opacity = "1"; el.style.transition = ""; }, 420);
    }, delay);
  }

  function updateMorePage() {
    setTimeout(() => updateUIText?.(), 50);
    const session = getSession();
    const favCount = getFavorites().length;

    // إظهار/إخفاء قسم المفضلة حسب تسجيل الدخول
    const favSection = document.getElementById("more-fav-section");
    if (favSection) {
      favSection.style.display = session ? "flex" : "none";
    }

    // عدد المفضلة
    const badge = document.getElementById("more-fav-badge");
    const favCountEl = document.getElementById("more-fav-count");
    if (badge) {
      badge.textContent = favCount;
      badge.style.display = favCount > 0 ? "block" : "none";
    }
    if (favCountEl) {
      favCountEl.textContent = favCount > 0 ? `${favCount} مانغا محفوظة` : "المانغا المحفوظة";
    }

    // معلومات المستخدم
    const nameEl = document.getElementById("more-username");
    const subEl = document.getElementById("more-usersub");
    const avatarWrap = document.getElementById("more-avatar-wrap");
    const avatarSvg = document.getElementById("more-avatar-svg");

    if (session) {
      if (nameEl) nameEl.textContent = session.displayName || session.name || "مستخدم";
      if (subEl) subEl.textContent = session.email || "إدارة الحساب";
      // صورة الحساب — نقرأها من الـ session مباشرة
      if (session.photoBase64 && avatarWrap) {
        avatarWrap.innerHTML = `<img src="${session.photoBase64}" style="width:100%;height:100%;object-fit:cover;border-radius:50%;">`;
      } else if (avatarSvg) {
        avatarSvg.style.display = "";
      }
    } else {
      if (nameEl) nameEl.textContent = t("loginTitle");
      if (subEl) subEl.textContent = t("createOrLogin");
      if (avatarSvg) avatarSvg.style.display = "";
    }
  }

  // نحافظ على history entry دائماً حتى يشتغل زر الرجوع بالأندرويد
  history.pushState(null, "", location.href);

  // زر الرجوع بالأندرويد — ضغة واحدة فقط، يرجع للصفحة السابقة
  document.addEventListener('keydown', (e) => {
    if (e.keyCode === 27) { e.preventDefault(); goBack(); }
  });

  let lastBackTime = 0;
  let backToast = null;

  function handleBackButton() {
    if (currentPage !== "home") {
      goBack();
      return;
    }
    const now = Date.now();
    if (now - lastBackTime < 2000) {
      if (backToast) { clearTimeout(backToast._timer); backToast.remove(); }
      window.history.go(-(window.history.length));
      return;
    }
    lastBackTime = now;
    if (backToast) { clearTimeout(backToast._timer); backToast.remove(); }
    backToast = document.createElement("div");
    backToast.textContent = "اضغط مجدداً للخروج";
    backToast.style.cssText = `
      position:fixed; bottom:100px; left:50%; transform:translateX(-50%);
      background:rgba(30,20,50,0.95); color:#fff;
      padding:10px 24px; border-radius:24px;
      font-size:13px; font-weight:700;
      border:1px solid rgba(139,92,246,0.4);
      box-shadow:0 4px 20px rgba(0,0,0,0.5);
      z-index:9999; white-space:nowrap;
    `;
    document.body.appendChild(backToast);
    backToast._timer = setTimeout(() => {
      if (backToast) { backToast.remove(); backToast = null; }
      lastBackTime = 0;
    }, 2000);
  }

  let _appVisible = true;
  document.addEventListener('visibilitychange', () => {
    _appVisible = !document.hidden;
  });

  window.addEventListener('popstate', (e) => {
    e.preventDefault();
    // لو رجع من خارج التطبيق (app resume) — لا تفعل شيء
    if (!_appVisible) {
      history.pushState(null, "", location.href);
      _appVisible = true;
      return;
    }
    handleBackButton();
    history.pushState(null, "", location.href);
  });

  function getSession() {
    try { return JSON.parse(localStorage.getItem("manga_auth")); }
    catch (e) { return null; }
  }
  function saveSession(data) { localStorage.setItem("manga_auth", JSON.stringify(data)); }
  function clearSession() {
    localStorage.removeItem("manga_auth");
    localStorage.removeItem("profile_avatar");
  }
  function patchSession(p) { saveSession({...getSession()||{}, ...p}); }

  document.addEventListener("DOMContentLoaded", () => {
    // data-page موجود مسبقاً في HTML

    const session = getSession();
    if (session && session.localId) {
      showEditState();
    } else {
      showGuestState();
    }

    let authMode = "login";

    // زر "تسجيل الدخول / إنشاء حساب"
    document.getElementById("submit-btn").addEventListener("click", async () => {
      const email = document.getElementById("login-email").value.trim();
      const password = document.getElementById("login-password").value;
      const msgEl = document.getElementById("auth-status-msg");
      if (!email || !password) { msgEl.textContent = t("enterEmailPass"); msgEl.style.color = "#E85C5C"; return; }
      msgEl.textContent = t("tryingMsg"); msgEl.style.color = "#7ED957";
      try {
        const endpoint = authMode === "login" ? "signInWithPassword" : "signUp";
        const res = await fetch(`${AUTH_BASE}:${endpoint}?key=${FIREBASE_API_KEY}`, {
          method: "POST", headers: { "Content-Type": "application/json" },
          body: JSON.stringify({ email, password, returnSecureToken: true })
        });
        const data = await res.json();
        if (!res.ok) {
          const errText = data.error?.message || "حاول مرة أخرى";
          const friendly = errText.includes("EMAIL_NOT_FOUND") || errText.includes("INVALID_PASSWORD") || errText.includes("INVALID_LOGIN_CREDENTIALS")
            ? "إيميل أو كلمة المرور غلط"
            : errText.includes("EMAIL_EXISTS") ? "الإيميل مسجل مسبقاً"
            : errText.includes("WEAK_PASSWORD") ? "كلمة المرور ضعيفة (6 أحرف على الأقل)"
            : "حدث خطأ، حاول مرة أخرى";
          msgEl.textContent = friendly; msgEl.style.color = "#E85C5C";
          autoHideMsg(msgEl);
          return;
        }

        // اذا حساب مختلف عن القديم نمسح البيانات القديمة أول
        const prevSession = getSession();
        const isSameUser = prevSession && prevSession.localId === data.localId;

        if (!isSameUser) {
          // حساب جديد — امسح كل البيانات القديمة تماماً
          clearSession();
          pendingPhotoBase64 = null;
          saveSession({ email: data.email, idToken: data.idToken, localId: data.localId, displayName: "", photoBase64: null });
        } else {
          saveSession({ email: data.email, idToken: data.idToken, localId: data.localId, displayName: prevSession.displayName || "", photoBase64: prevSession.photoBase64 || null });
        }

        document.getElementById("submit-btn").style.display = "none";
        msgEl.textContent = t("successMsg"); msgEl.style.color = "#7ED957";
        autoHideMsg(msgEl);

        // جيب الصورة والاسم من الخادم أولاً ثم حدّث الواجهة
        fetch(`${FIRESTORE_BASE}/users/${data.localId}`, {
          headers: { "Authorization": `Bearer ${data.idToken}` }
        }).then(r => r.ok ? r.json() : null).then(profileDoc => {
          if (profileDoc) {
            const savedName  = profileDoc.fields?.displayName?.stringValue || "";
            const savedPhoto = profileDoc.fields?.photoBase64?.stringValue || null;
            patchSession({ displayName: savedName, photoBase64: savedPhoto });
          }
        }).catch(() => {}).finally(() => {
          setTimeout(() => {
            refreshUserUI();
            showEditState();
            document.getElementById("submit-btn").style.display = "";
            document.getElementById("submit-btn").disabled = false;
          }, 300);
        });
      } catch (err) { msgEl.textContent = t("connFailed"); msgEl.style.color = "#E85C5C"; }
    });

    // تبديل وضع تسجيل/إنشاء حساب - event delegation
    document.getElementById("switch-mode-text").addEventListener("click", () => {
      authMode = authMode === "login" ? "signup" : "login";
      document.getElementById("form-title").textContent = authMode === "login" ? t("loginTitle") : t("registerTitle");
      document.getElementById("submit-btn").textContent = authMode === "login" ? t("loginTitle") : t("registerTitle");
      document.getElementById("switch-mode-text").innerHTML = authMode === "login"
        ? `${t("noAccountText")} <span id="switch-mode-link" style="color:var(--accent-neon);cursor:pointer;text-decoration:underline;">${t("createAccount")}</span>`
        : `${t("haveAccount")} <span id="switch-mode-link" style="color:var(--accent-neon);cursor:pointer;text-decoration:underline;">${t("signIn")}</span>`;
      document.getElementById("auth-status-msg").textContent = "";
    });

    // تسجيل الخروج
    document.getElementById("logout-btn").addEventListener("click", () => {
      clearSession(); refreshUserUI(); goToPage('more');
    });

    // حفظ البروفايل
    document.getElementById("save-btn").addEventListener("click", async () => {
      const name = document.getElementById("name-input").value.trim();
      const msgEl = document.getElementById("profile-status-msg");
      if (!name) { msgEl.textContent = t("enterName"); msgEl.style.color = "#E85C5C"; return; }
      msgEl.textContent = t("savingMsg"); msgEl.style.color = "#7ED957";
      document.getElementById("save-btn").disabled = true;

      const session = getSession();
      // تحديث فوري بالواجهة (البار العلوي وغيره) قبل ما ننتظر رد السيرفر
      patchSession({ displayName: name, photoBase64: pendingPhotoBase64 || session.photoBase64 });
      refreshUserUI();

      try {
        const fields = { displayName: { stringValue: name }, email: { stringValue: session.email || "" } };
        const mask = pendingPhotoBase64
          ? "updateMask.fieldPaths=displayName&updateMask.fieldPaths=email&updateMask.fieldPaths=photoBase64"
          : "updateMask.fieldPaths=displayName&updateMask.fieldPaths=email";
        if (pendingPhotoBase64) fields.photoBase64 = { stringValue: pendingPhotoBase64 };
        const res = await fetch(`${FIRESTORE_BASE}/users/${session.localId}?${mask}`, {
          method: "PATCH",
          headers: { "Content-Type": "application/json", "Authorization": `Bearer ${session.idToken}` },
          body: JSON.stringify({ fields })
        });
        if (!res.ok) { msgEl.textContent = t("saveFailed"); msgEl.style.color = "#E8B85C"; autoHideMsg(msgEl); document.getElementById("save-btn").disabled = false; return; }
        msgEl.textContent = t("savedMsg"); msgEl.style.color = "#7ED957";
        autoHideMsg(msgEl);
        document.getElementById("save-btn").disabled = false;
        document.getElementById("save-btn").style.display = "none";
        pendingPhotoBase64 = null;
        // reset الاسم الأصلي حتى يشتغل الـ checkProfileChanged صح بعدين
        const newName = document.getElementById("name-input").value.trim();
        // نحدّث _origName بشكل غير مباشر عبر إعادة تعريف checkProfileChanged
        document.getElementById("name-input").dataset.saved = newName;
        // امسح رسالة "تم الحفظ" بعد 2.5 ثانية
        setTimeout(() => { if (msgEl) { msgEl.textContent = ""; } }, 1000);
        // نبقى بصفحة "حسابي" بعد الحفظ (فوقها بياناته، وتحتها روابط التواصل) بدل الرجوع للرئيسية
      } catch (err) { msgEl.textContent = "فشل الاتصال (بس البيانات محفوظة عندك بالجهاز)"; msgEl.style.color = "#E8B85C"; document.getElementById("save-btn").disabled = false; }
    });

    // رفع الصورة
    document.getElementById("avatar-input").addEventListener("change", e => {
      const file = e.target.files[0]; if (!file) return;
      if (file.size > 5 * 1024 * 1024) { alert("الصورة كبيرة جداً (أكثر من 5MB)"); return; }
      const reader = new FileReader();
      reader.onload = ev => {
        const img = new Image();
        img.onload = () => {
          const canvas = document.createElement("canvas");
          canvas.width = canvas.height = 200;
          const ctx = canvas.getContext("2d");
          const min = Math.min(img.width, img.height);
          ctx.drawImage(img, (img.width-min)/2, (img.height-min)/2, min, min, 0, 0, 200, 200);
          pendingPhotoBase64 = canvas.toDataURL("image/jpeg", 0.75);
          setAvatarPreview(pendingPhotoBase64);
          if (typeof checkProfileChanged === "function") checkProfileChanged();
        };
        img.src = ev.target.result;
      };
      reader.readAsDataURL(file);
    });

    refreshUserUI();
    loadMangaList();
  });

  setInterval(refreshUserUI, 2000);



  /* ===== Pinch to Zoom في القارئ ===== */
  (function() {
    let scale = 1, startDist = 0, startScale = 1;
    let tx = 0, ty = 0, panStart = null, isPinching = false;
    const MAX = 1.5;

    function getDist(t) { return Math.hypot(t[0].clientX-t[1].clientX, t[0].clientY-t[1].clientY); }
    function getEl() { return document.getElementById("reader-zoom-inner"); }

    function clamp(el) {
      scale = Math.max(1, Math.min(MAX, scale));
      if (scale === 1) { tx = 0; ty = 0; return; }
      const maxTx = (el.offsetWidth  * (scale - 1)) / 2;
      const minTy = -(el.scrollHeight * (scale - 1));
      tx = Math.max(-maxTx, Math.min(maxTx, tx));
      ty = Math.min(0, Math.max(minTy, ty));
    }

    function applyTransform(el, anim) {
      clamp(el);
      if (anim) { el.style.transition = "transform 0.2s ease"; setTimeout(()=>el.style.transition="",220); }
      el.style.transform = scale === 1 ? "" : `translate(${tx}px,${ty}px) scale(${scale})`;
      el.style.transformOrigin = "top center";
    }

    document.addEventListener("touchstart", e => {
      if (currentPage !== "reader") return;
      const el = getEl(); if (!el) return;

      if (e.touches.length === 2) {
        isPinching = true;
        panStart = null;
        startDist = getDist(e.touches);
        startScale = scale;
        e.preventDefault();
      } else if (e.touches.length === 1 && !isPinching && scale > 1) {
        // ابدأ pan من الموقع الحالي
        panStart = { x: e.touches[0].clientX - tx, y: e.touches[0].clientY - ty };
      }
    }, { passive: false });

    document.addEventListener("touchmove", e => {
      if (currentPage !== "reader") return;
      const el = getEl(); if (!el) return;

      if (e.touches.length === 2 && isPinching) {
        scale = startScale * (getDist(e.touches) / startDist);
        applyTransform(el, false);
        e.preventDefault();
      } else if (e.touches.length === 1 && scale > 1 && panStart && !isPinching) {
        tx = e.touches[0].clientX - panStart.x;
        ty = e.touches[0].clientY - panStart.y;
        applyTransform(el, false);
        e.preventDefault();
      }
    }, { passive: false });

    document.addEventListener("touchend", e => {
      if (currentPage !== "reader") return;
      const el = getEl();

      if (e.touches.length === 1 && isPinching) {
        // انتهى الـ pinch وضل إصبع واحد - أعد حساب panStart من الموقع الحالي
        isPinching = false;
        if (scale > 1 && el) {
          panStart = { x: e.touches[0].clientX - tx, y: e.touches[0].clientY - ty };
        }
      } else if (e.touches.length === 0) {
        isPinching = false;
        panStart = null;
        // إذا رجع للـ 1 تقريباً، صغّره تماماً
        if (el && scale < 1.05) {
          scale = 1; tx = 0; ty = 0;
          applyTransform(el, true);
        }
      }
    }, { passive: true });
  })();

  /* ===== كيبورد: Enter + scroll ===== */
  document.querySelectorAll(".field-input").forEach(inp => {
    inp.addEventListener("focus", () => {
      setTimeout(() => inp.scrollIntoView({ behavior: "smooth", block: "center" }), 350);
    });
  });
  const _loginEmail = document.getElementById("login-email");
  const _loginPass  = document.getElementById("login-password");
  if (_loginEmail) _loginEmail.addEventListener("keydown", e => {
    if (e.key === "Enter") { e.preventDefault(); _loginPass && _loginPass.focus(); }
  });
  if (_loginPass) _loginPass.addEventListener("keydown", e => {
    if (e.key === "Enter") { e.preventDefault(); document.getElementById("submit-btn")?.click(); }
  });
  const _nameInp = document.getElementById("name-input");
  if (_nameInp) _nameInp.addEventListener("keydown", e => {
    if (e.key === "Enter") { e.preventDefault(); document.getElementById("save-btn")?.click(); }
  });

  // ===== نظام اللغات =====
  const translations = {
    ar: { appName:"تطبيق المانغا", continueReading:"أكمل القراءة", newChapters:"فصول جديدة", thisWeek:"هذا الأسبوع", older:"أقدم", latestChapters:"آخر الإصدارات", seeAll:"عرض الكل", topRated:"الأعلى تقييماً", library:"مكتبة المانغا", loadingLibrary:"جاري تحميل المكتبة...", allManga:"كل المانغا", noResults:"لا توجد نتائج", noResultsDesc:"ما لقينا مانغا بهذا الاسم", tryDifferent:"جرب كلمة مختلفة", filterBy:"تصنيف بواسطة", genre:"التصنيف", type:"النوع", manga:"مانغا", manhwa:"مانهوا", ongoing:"مستمرة", completed:"مكتملة", status:"الحالة", apply:"تطبيق", guest:"زائر", login:"تسجيل الدخول", register:"إنشاء حساب جديد", email:"الإيميل", password:"كلمة المرور", noAccount:"ليس لديك حساب؟", createAccount:"أنشئ حساباً", myAccount:"حسابي", logout:"خروج", name:"الاسم", saveChanges:"حفظ التعديلات", back:"رجوع", favorites:"المفضلة", cancelSelect:"إلغاء", deleteSelected:"حذف المحدد", all:"الكل", reading:"أقرأه", planRead:"سأقرأه", paused:"متوقف", completedCat:"مكتمل", emptyFavTitle:"قائمتك فارغة", emptyFavDesc:"ما أضفت أي مانغا للمفضلة بعد", mangaCategory:"تصنيف المانغا", currentlyReading:"أقرأه حالياً", pausedFull:"متوقف مؤقتاً", removeCategory:"إزالة التصنيف", loading:"جاري التحميل...", vertical:"عمودي", horizontal:"أفقي", more:"المزيد", settings:"إعدادات التطبيق", about:"عن التطبيق", version:"الإصدار 1.0.0", contactUs:"تواصل معنا", libraryNav:"المكتبة", home:"الرئيسية", search:"البحث", startReading:"ابدأ القراءة", chapterWord:"الفصل", chapters:"الفصول", showMore:"عرض المزيد", deleteFromFav:"حذف من المفضلة؟", deleteFromFavDesc:"سيتم حذف هذه المانغا من قائمة مفضلتك", delete:"حذف", addCategory:"+ تصنيف", savedManga:"المانغا المحفوظة", searchPlaceholder:"ابحث عن مانغا...", chapterSearch:"ابحث برقم الفصل...", avatarHint:"اضغط الصورة لتغييرها", appSettings:"إعدادات التطبيق", authSubtitle:"سجل دخولك لحفظ مفضلتك ومتابعة قراءتك", noAccountText:"ليس لديك حساب؟", haveAccount:"لديك حساب؟", signIn:"سجّل دخولك", loginTitle:"تسجيل الدخول", registerTitle:"إنشاء حساب", createOrLogin:"أنشئ حسابك أو سجّل دخولك", successMsg:"تم بنجاح ✓", savingMsg:"جاري الحفظ...", savedMsg:"تم الحفظ ✓", tryingMsg:"جاري المحاولة...", enterEmailPass:"اكتب الإيميل وكلمة المرور", connFailed:"فشل الاتصال", saveFailed:"فشل الحفظ (بياناتك محفوظة بالجهاز)", enterName:"اكتب اسمك", lightMode:"الوضع النهاري", darkMode:"الوضع الداكن", tapToEnable:"اضغط للتفعيل", activeLight:"مفعّل الآن: النهاري ☀️", lang:"English", langLabel:"عربي", langTitle:"اللغة" },
    en: { appName:"Manga App", continueReading:"Continue Reading", newChapters:"New Chapters", thisWeek:"This Week", older:"Older", latestChapters:"Latest Releases", seeAll:"See All", topRated:"Top Rated", library:"Manga Library", loadingLibrary:"Loading library...", allManga:"All Manga", noResults:"No Results", noResultsDesc:"No manga found with this name", tryDifferent:"Try a different word", filterBy:"Filter By", genre:"Genre", type:"Type", manga:"Manga", manhwa:"Manhwa", ongoing:"Ongoing", completed:"Completed", status:"Status", apply:"Apply", guest:"Guest", login:"Sign In", register:"Create Account", email:"Email", password:"Password", noAccount:"Don't have an account?", createAccount:"Create one", myAccount:"My Account", logout:"Sign Out", name:"Name", saveChanges:"Save Changes", back:"Back", favorites:"Favorites", cancelSelect:"Cancel", deleteSelected:"Delete Selected", all:"All", reading:"Reading", planRead:"Plan to Read", paused:"On Hold", completedCat:"Completed", emptyFavTitle:"Your list is empty", emptyFavDesc:"You haven't added any manga yet", mangaCategory:"Manga Category", currentlyReading:"Currently Reading", pausedFull:"On Hold", removeCategory:"Remove Category", loading:"Loading...", vertical:"Vertical", horizontal:"Horizontal", more:"More", settings:"App Settings", about:"About", version:"Version 1.0.0", contactUs:"Contact Us", libraryNav:"Library", home:"Home", search:"Search", startReading:"Start Reading", chapterWord:"Chapter", chapters:"Chapters", showMore:"Show More", deleteFromFav:"Remove from Favorites?", deleteFromFavDesc:"This manga will be removed from your favorites", delete:"Remove", addCategory:"+ Category", savedManga:"Saved Manga", searchPlaceholder:"Search manga...", chapterSearch:"Search by chapter number...", avatarHint:"Tap photo to change", appSettings:"App Settings", authSubtitle:"Sign in to save favorites and track reading", noAccountText:"Don't have an account?", haveAccount:"Have an account?", signIn:"Sign in", loginTitle:"Sign In", registerTitle:"Create Account", createOrLogin:"Create account or sign in", successMsg:"Done ✓", savingMsg:"Saving...", savedMsg:"Saved ✓", tryingMsg:"Please wait...", enterEmailPass:"Enter email and password", connFailed:"Connection failed", saveFailed:"Save failed (data saved locally)", enterName:"Enter your name", lightMode:"Light Mode", darkMode:"Dark Mode", tapToEnable:"Tap to enable", activeLight:"Active: Light Mode ☀️", lang:"عربي", langLabel:"English", langTitle:"Language" }
  };

  let _appLang = localStorage.getItem("app_lang") || "ar";

  function t(key) {
    return (translations[_appLang]?.[key]) || translations["ar"][key] || key;
  }

  function changeLanguage(lang) {
    _appLang = lang;
    localStorage.setItem("app_lang", lang);
    document.documentElement.dir = lang === "ar" ? "rtl" : "ltr";
    document.documentElement.lang = lang;
    updateUIText();
    const label = document.getElementById("lang-current-label");
    if (label) label.textContent = lang === "ar" ? "عربي" : "English";
    const badge = document.getElementById("lang-toggle-badge");
    if (badge) badge.textContent = lang === "ar" ? "English" : "عربي";
    // أعد رسم الصفحة الحالية
    if (typeof renderFavoritesPage === "function" && currentPage === "favorites") renderFavoritesPage();
    if (typeof updateMorePage === "function" && currentPage === "more") updateMorePage();
  }

  function updateUIText() {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.getAttribute("data-i18n");
      if (el.tagName === "INPUT") el.placeholder = t(key);
      else el.textContent = t(key);
    });
    const searchInput = document.querySelector("#search-input");
    if (searchInput) searchInput.placeholder = t("searchPlaceholder");
    const chapterInput = document.querySelector("#chapter-search-input");
    if (chapterInput) chapterInput.placeholder = t("chapterSearch");
  }

  // تطبيق اللغة عند التحميل
  document.addEventListener("DOMContentLoaded", () => {
    if (_appLang !== "ar") {
      document.documentElement.dir = "ltr";
      document.documentElement.lang = "en";
      updateUIText();
      const label = document.getElementById("lang-current-label");
      if (label) label.textContent = "English";
    }
  });


  // ══ الثيم النهاري ══
  function _applySocialColors() {
    document.querySelectorAll('.social-icon-wrap[data-social-bg]').forEach(el => {
      el.style.setProperty('background', el.getAttribute('data-social-bg'), 'important');
      el.style.setProperty('color', 'white', 'important');
    });
  }

  function toggleTheme() {
    var isLight = document.documentElement.classList.toggle('light-theme');
    document.body.classList.toggle('light-theme', isLight);
    localStorage.setItem('manga_theme', isLight ? 'light' : 'dark');
    _updateThemeUI(isLight);
    _fixHardcodedElements(isLight);
    setTimeout(_applySocialColors, 0);
  }

  function _updateThemeUI(isLight) {
    var label = document.getElementById('theme-row-label');
    var sub   = document.getElementById('theme-row-sub');
    var track = document.getElementById('theme-track');
    var thumb = document.getElementById('theme-thumb');
    var icon  = document.querySelector('#theme-svg-icon path');
    if (isLight) {
      if (label) label.textContent = t('darkMode');
      if (sub)   sub.textContent   = t('activeLight');
      if (track) { track.style.background = '#5B5BD6'; track.style.borderColor = 'rgba(91,91,214,0.4)'; }
      if (thumb) { thumb.style.transform = 'translateX(-22px)'; thumb.style.background = '#fff'; }
      if (icon)  icon.setAttribute('stroke', '#5B5BD6');
    } else {
      if (label) label.textContent = t('lightMode');
      if (sub)   sub.textContent   = t('tapToEnable');
      if (track) { track.style.background = '#1e1b4b'; track.style.borderColor = 'rgba(91,91,214,0.35)'; }
      if (thumb) { thumb.style.transform = 'translateX(0)'; thumb.style.background = '#5B5BD6'; }
      if (icon)  icon.setAttribute('stroke', '#5B5BD6');
    }
  }

  function _fixHardcodedElements(isLight) {
    // لا شيء - الثيم يعتمد على CSS فقط
    document.body.style.removeProperty('background');
  }

  // تطبيق الثيم المحفوظ
  (function() {
    document.body.style.removeProperty('background');
    if (localStorage.getItem('manga_theme') === 'light') {
      document.documentElement.classList.add('light-theme');
      document.body.classList.add('light-theme');
      window.addEventListener('load', function() {
        _updateThemeUI(true);
        _applySocialColors();
      });
    } else {
      window.addEventListener('load', function() {
        _applySocialColors();
      });
    }
  })();

