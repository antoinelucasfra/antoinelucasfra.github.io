(() => {
  // ponytail: self-contained catalog controller, no deps

  var PAGE_SIZE = 50;

  function byId(id) {
    return document.getElementById(id);
  }

  var state = {
    search: "",
    type: "",
    language: {},
    super: {},
    sort: "default",
    page: 1,
  };

  var items = [];
  var visibleIndices = [];

  function init() {
    var catalogRoot = byId("resource-catalog");
    if (!catalogRoot) return;

    items = Array.from(catalogRoot.querySelectorAll(".catalog-item"));
    if (!items.length) return;

    var searchInput = byId("resource-search");
    var typeSelect = byId("type-filter");
    var sortSelect = byId("sort-select");
    var clearBtn = byId("clear-filters");
    var countEl = byId("resources-count");
    var noResultsMsg = byId("no-results-msg");
    var resultsContainer = byId("catalog-results");
    var paginationEl = byId("catalog-pagination");
    var controlsRoot = document.querySelector(".controls-wrapper");

    if (!searchInput || !countEl || !resultsContainer) return;

    state.search = searchInput.value.trim();
    if (typeSelect) state.type = typeSelect.value;
    if (sortSelect) state.sort = sortSelect.value;

    function applyFilters() {
      var query = state.search.toLowerCase();
      var typeVal = state.type;

      visibleIndices = items
        .map((item, index) => index)
        .filter((index) => {
          var item = items[index];
          var text = item.getAttribute("data-search") || "";
          if (query && text.indexOf(query) === -1) return false;
          if (typeVal && item.getAttribute("data-type") !== typeVal)
            return false;

          var langFilters = state.language;
          if (Object.keys(langFilters).length) {
            var lang = item.getAttribute("data-language") || "";
            var langs = lang
              .split(";")
              .map((s) => s.trim())
              .filter(Boolean);
            if (!langs.some((l) => langFilters[l])) return false;
          }

          var superFilters = state.super;
          if (Object.keys(superFilters).length) {
            var sv = item.getAttribute("data-super") || "";
            if (!superFilters[sv]) return false;
          }
          return true;
        });

      visibleIndices.sort((aIndex, bIndex) => {
        if (state.sort === "date-desc" || state.sort === "date-asc") {
          var da = items[aIndex].getAttribute("data-date") || "";
          var db = items[bIndex].getAttribute("data-date") || "";
          if (!da && !db) return 0;
          if (!da) return 1;
          if (!db) return -1;
          return state.sort === "date-desc"
            ? da < db
              ? 1
              : da > db
                ? -1
                : 0
            : da < db
              ? -1
              : da > db
                ? 1
                : 0;
        }
        var ta = (
          items[aIndex].getAttribute("data-search") || ""
        ).toLowerCase();
        var tb = (
          items[bIndex].getAttribute("data-search") || ""
        ).toLowerCase();
        return ta < tb ? -1 : ta > tb ? 1 : 0;
      });

      var total = visibleIndices.length;
      var startIndex = (state.page - 1) * PAGE_SIZE;
      var endIndex = startIndex + PAGE_SIZE;
      var pagedIndices = visibleIndices.slice(startIndex, endIndex);

      items.forEach((el) => {
        el.style.display = "none";
      });
      pagedIndices.forEach((index) => {
        items[index].style.display = "";
      });

      if (countEl) countEl.textContent = String(pagedIndices.length);
      if (noResultsMsg) noResultsMsg.style.display = total ? "none" : "";

      renderPagination(total);
    }

    function renderPagination(total) {
      if (!paginationEl) return;
      var totalPages = Math.ceil(total / PAGE_SIZE);
      if (totalPages <= 1) {
        paginationEl.innerHTML = "";
        return;
      }

      var remaining = total - state.page * PAGE_SIZE;
      if (remaining > 0) {
        var loadMore = document.createElement("button");
        loadMore.id = "load-more";
        loadMore.className = "btn btn-sm";
        loadMore.textContent = "Load more";
        loadMore.setAttribute("aria-label", "Load more resources");
        loadMore.addEventListener("click", () => {
          state.page += 1;
          applyFilters();
          var updated = byId("load-more");
          if (updated) updated.focus();
        });
        paginationEl.innerHTML = "";
        paginationEl.appendChild(loadMore);
      } else {
        paginationEl.innerHTML = "";
      }
    }

    function resetAll() {
      state.search = "";
      state.type = "";
      state.language = {};
      state.super = {};
      state.sort = "default";
      state.page = 1;
      if (searchInput) searchInput.value = "";
      if (typeSelect) typeSelect.value = "";
      if (sortSelect) sortSelect.value = "default";
      document.querySelectorAll(".filter-chip").forEach((el) => {
        el.setAttribute("aria-pressed", "false");
      });
      applyFilters();
    }

    if (controlsRoot) {
      controlsRoot.addEventListener("click", (e) => {
        var btn = e.target.closest(".filter-chip[data-filter-group]");
        if (!btn) return;
        var group = btn.getAttribute("data-filter-group");
        var value = btn.getAttribute("data-filter-value");
        var pressed = btn.getAttribute("aria-pressed") === "true";
        btn.setAttribute("aria-pressed", pressed ? "false" : "true");
        if (pressed) {
          delete state[group][value];
        } else {
          state[group][value] = true;
        }
        state.page = 1;
        applyFilters();
      });
    }

    if (searchInput) {
      searchInput.addEventListener("input", () => {
        state.search = searchInput.value.trim();
        state.page = 1;
        applyFilters();
      });
    }
    if (typeSelect) {
      typeSelect.addEventListener("change", () => {
        state.type = typeSelect.value;
        state.page = 1;
        applyFilters();
      });
    }
    if (sortSelect) {
      sortSelect.addEventListener("change", () => {
        state.sort = sortSelect.value;
        state.page = 1;
        applyFilters();
      });
    }
    if (clearBtn) {
      clearBtn.addEventListener("click", resetAll);
    }
    if (noResultsMsg) {
      var noResultsClear = noResultsMsg.querySelector("button");
      if (noResultsClear) {
        noResultsClear.addEventListener("click", resetAll);
      }
    }

    applyFilters();
  }

  document.addEventListener("DOMContentLoaded", init);
})();
