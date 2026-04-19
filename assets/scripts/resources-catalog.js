document.addEventListener("DOMContentLoaded", function () {
  const catalogRoot = document.getElementById("resource-catalog");
  const controlsRoot = document.querySelector(".controls-wrapper");
  if (!catalogRoot) {
    return;
  }

  const searchInput = document.getElementById("resource-search");
  const typeSelect = document.getElementById("type-filter");
  const clearBtn = document.getElementById("clear-filters");
  const noResultsClear = document.getElementById("no-results-clear");
  const noResultsMsg = document.getElementById("no-results-msg");
  const countEl = document.getElementById("resources-count");
  const paginationEl = document.getElementById("catalog-pagination");
  const sortSelect = document.getElementById("sort-select");
  const gridViewBtn = document.getElementById("grid-view-btn");
  const listViewBtn = document.getElementById("list-view-btn");
  const items = Array.from(catalogRoot.querySelectorAll(".catalog-item"));

  if (!controlsRoot || !searchInput || !typeSelect || !paginationEl || items.length === 0) {
    return;
  }

  const PAGE_SIZE = 50;
  const activeFilters = {
    language: new Set(),
    super: new Set(),
  };

  let currentPage = 1;
  let visibleIndices = [];

  function getTitle(item) {
    const anchor = item.querySelector(".resource-title a");
    return anchor ? anchor.textContent.toLowerCase() : "";
  }

  function getDescription(item) {
    const description = item.querySelector(".resource-desc");
    return description ? description.textContent.toLowerCase() : "";
  }

  function getHref(item) {
    const anchor = item.querySelector(".resource-title a");
    return anchor ? (anchor.getAttribute("href") || "").toLowerCase() : "";
  }

  function updateViewMode(mode) {
    catalogRoot.classList.toggle("catalog-view-grid", mode === "grid");
    catalogRoot.classList.toggle("catalog-view-list", mode === "list");
  }

  function sortVisibleIndices(mode) {
    if (mode === "default") {
      return;
    }

    visibleIndices.sort(function (leftIndex, rightIndex) {
      const leftDate = items[leftIndex].dataset.date || "";
      const rightDate = items[rightIndex].dataset.date || "";

      if (!leftDate && !rightDate) {
        return 0;
      }
      if (!leftDate) {
        return 1;
      }
      if (!rightDate) {
        return -1;
      }

      if (mode === "date-desc") {
        return leftDate < rightDate ? 1 : leftDate > rightDate ? -1 : 0;
      }
      if (mode === "date-asc") {
        return leftDate > rightDate ? 1 : leftDate < rightDate ? -1 : 0;
      }
      return 0;
    });
  }

  function renderPagination(total, page) {
    const totalPages = Math.ceil(total / PAGE_SIZE);
    paginationEl.innerHTML = "";

    if (totalPages <= 1) {
      return;
    }

    const nav = document.createElement("nav");
    nav.setAttribute("aria-label", "Resources pagination");

    const list = document.createElement("ul");
    list.className = "pagination";

    function makeItem(label, targetPage, isActive, isDisabled, ariaLabel) {
      const listItem = document.createElement("li");
      listItem.className =
        "page-item" +
        (isActive ? " active" : "") +
        (isDisabled ? " disabled" : "");

      const link = document.createElement("a");
      link.className = "page-link";
      link.href = "#";
      link.innerHTML = label;
      if (ariaLabel) {
        link.setAttribute("aria-label", ariaLabel);
      }
      if (isActive) {
        link.setAttribute("aria-current", "page");
      }

      if (!isDisabled && !isActive) {
        link.addEventListener("click", function (event) {
          event.preventDefault();
          renderPage(targetPage);
          controlsRoot.scrollIntoView({ behavior: "smooth", block: "start" });
        });
      } else {
        link.addEventListener("click", function (event) {
          event.preventDefault();
        });
      }

      listItem.appendChild(link);
      return listItem;
    }

    list.appendChild(makeItem("&laquo;", page - 1, false, page === 1, "Previous page"));

    const windowSize = 2;
    const rangeStart = Math.max(1, page - windowSize);
    const rangeEnd = Math.min(totalPages, page + windowSize);

    if (rangeStart > 1) {
      list.appendChild(makeItem("1", 1, false, false));
      if (rangeStart > 2) {
        const ellipsis = document.createElement("li");
        ellipsis.className = "page-item disabled";
        ellipsis.innerHTML = '<span class="page-link">&hellip;</span>';
        list.appendChild(ellipsis);
      }
    }

    for (let pageNumber = rangeStart; pageNumber <= rangeEnd; pageNumber += 1) {
      list.appendChild(makeItem(String(pageNumber), pageNumber, pageNumber === page, false));
    }

    if (rangeEnd < totalPages) {
      if (rangeEnd < totalPages - 1) {
        const ellipsis = document.createElement("li");
        ellipsis.className = "page-item disabled";
        ellipsis.innerHTML = '<span class="page-link">&hellip;</span>';
        list.appendChild(ellipsis);
      }
      list.appendChild(makeItem(String(totalPages), totalPages, false, false));
    }

    list.appendChild(makeItem("&raquo;", page + 1, false, page === totalPages, "Next page"));

    nav.appendChild(list);
    paginationEl.appendChild(nav);
  }

  function renderPage(page) {
    const totalPages = Math.ceil(visibleIndices.length / PAGE_SIZE);
    currentPage = Math.max(1, page);
    if (totalPages > 0) {
      currentPage = Math.min(currentPage, totalPages);
    }

    const start = (currentPage - 1) * PAGE_SIZE;
    const end = start + PAGE_SIZE;
    const pageSlice = new Set(visibleIndices.slice(start, end));

    items.forEach(function (item, index) {
      item.hidden = !pageSlice.has(index);
    });

    renderPagination(visibleIndices.length, currentPage);
  }

  function applyFilters(resetPage) {
    const query = searchInput.value.trim().toLowerCase();
    const typeValue = typeSelect.value.toLowerCase();

    visibleIndices = [];

    items.forEach(function (item, index) {
      let show = true;

      if (query) {
        const title = getTitle(item);
        const categories = (item.dataset.categories || "").toLowerCase();
        const description = getDescription(item);
        const href = getHref(item);
        show =
          title.includes(query) ||
          categories.includes(query) ||
          description.includes(query) ||
          href.includes(query);
      }

      if (show && typeValue) {
        show = (item.dataset.type || "") === typeValue;
      }

      if (show && activeFilters.language.size > 0) {
        const languages = (item.dataset.language || "")
          .split(";")
          .map(function (value) {
            return value.trim().toLowerCase();
          })
          .filter(Boolean);
        show = Array.from(activeFilters.language).some(function (filterValue) {
          return languages.includes(filterValue);
        });
      }

      if (show && activeFilters.super.size > 0) {
        show = activeFilters.super.has((item.dataset.super || "").toLowerCase());
      }

      if (show) {
        visibleIndices.push(index);
      }
    });

    sortVisibleIndices(sortSelect.value);

    if (countEl) {
      countEl.textContent = String(visibleIndices.length);
    }

    if (noResultsMsg) {
      noResultsMsg.style.display = visibleIndices.length === 0 ? "block" : "none";
    }

    if (resetPage !== false) {
      currentPage = 1;
    }

    renderPage(currentPage);
  }

  function clearAll() {
    searchInput.value = "";
    typeSelect.value = "";
    sortSelect.value = "default";
    activeFilters.language.clear();
    activeFilters.super.clear();
    document.querySelectorAll(".filter-chip.active").forEach(function (chip) {
      chip.classList.remove("active");
      chip.setAttribute("aria-pressed", "false");
    });
    applyFilters(true);
  }

  function debounce(callback, timeout) {
    let timerId;
    return function () {
      clearTimeout(timerId);
      timerId = setTimeout(callback, timeout);
    };
  }

  searchInput.addEventListener(
    "input",
    debounce(function () {
      applyFilters(true);
    }, 280)
  );

  typeSelect.addEventListener("change", function () {
    applyFilters(true);
  });

  sortSelect.addEventListener("change", function () {
    applyFilters(true);
  });

  if (clearBtn) {
    clearBtn.addEventListener("click", clearAll);
  }

  if (noResultsClear) {
    noResultsClear.addEventListener("click", clearAll);
  }

  controlsRoot.addEventListener("click", function (event) {
    const chip = event.target.closest(".filter-chip");
    if (chip) {
      const group = chip.dataset.filterGroup;
      const value = chip.dataset.filterValue;
      if (!group || !value) {
        return;
      }

      if (chip.classList.contains("active")) {
        chip.classList.remove("active");
        chip.setAttribute("aria-pressed", "false");
        activeFilters[group].delete(value);
      } else {
        chip.classList.add("active");
        chip.setAttribute("aria-pressed", "true");
        activeFilters[group].add(value);
      }

      applyFilters(true);
    }
  });

  catalogRoot.addEventListener("click", function (event) {
    const expandButton = event.target.closest(".category-expand-toggle");
    if (expandButton) {
      event.stopPropagation();
      const targetId = expandButton.getAttribute("data-id");
      catalogRoot.querySelectorAll('[data-extra="' + targetId + '"]').forEach(function (badge) {
        badge.classList.remove("d-none");
      });
      expandButton.style.display = "none";
    }
  });

  if (gridViewBtn) {
    gridViewBtn.addEventListener("change", function () {
      if (gridViewBtn.checked) {
        updateViewMode("grid");
      }
    });
  }

  if (listViewBtn) {
    listViewBtn.addEventListener("change", function () {
      if (listViewBtn.checked) {
        updateViewMode("list");
      }
    });
  }

  updateViewMode("grid");
  applyFilters(true);
});