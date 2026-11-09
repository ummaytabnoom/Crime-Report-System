(function () {
  function hasClass(element, name) {
    return (
      (" " + element.className + " ").indexOf(" " + name + " ") !== -1
    );
  }

  function addClass(element, name) {
    if (!hasClass(element, name)) {
      element.className += " " + name;
    }
  }

  function removeClass(element, name) {
    element.className = (" " + element.className + " ")
      .replace(" " + name + " ", " ")
      .replace(/^\s+|\s+$/g, "");
  }

  function toggleClass(element, name) {
    if (hasClass(element, name)) {
      removeClass(element, name);
      return false;
    }

    addClass(element, name);
    return true;
  }

  function matches(element, selector) {
    var method =
      element.matches ||
      element.msMatchesSelector ||
      element.webkitMatchesSelector;

    return element.nodeType === 1 && method.call(element, selector);
  }

  function closest(element, selector) {
    while (element && element.nodeType === 1) {
      if (matches(element, selector)) {
        return element;
      }

      element = element.parentElement;
    }

    return null;
  }

  function removeElement(element) {
    if (element.parentNode) {
      element.parentNode.removeChild(element);
    }
  }

  function ready(callback) {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", callback);
    } else {
      callback();
    }
  }

  window.toggleMenu = function () {
    var menu = document.getElementById("dropdownMenu");

    if (menu) {
      toggleClass(menu, "show");
    }
  };

  ready(function () {
    var accountTrigger = document.querySelector(".account-trigger");
    var accountMenu = document.querySelector(".account-menu");

    if (accountTrigger && accountMenu) {
      accountTrigger.addEventListener("click", function (event) {
        event.stopPropagation();

        var open = toggleClass(accountMenu, "is-open");
        accountTrigger.setAttribute("aria-expanded", String(open));
      });
    }

    var mobileTrigger = document.querySelector(".mobile-menu");
    var mobileNav = document.getElementById("crsMobileNav");

    if (mobileTrigger && mobileNav) {
      mobileTrigger.addEventListener("click", function (event) {
        event.stopPropagation();

        var open = toggleClass(mobileNav, "is-open");
        mobileTrigger.setAttribute("aria-expanded", String(open));
      });
    }

    document.addEventListener("click", function (event) {
      var target = event.target;

      if (
        accountMenu &&
        accountTrigger &&
        !accountMenu.contains(target) &&
        !accountTrigger.contains(target)
      ) {
        removeClass(accountMenu, "is-open");
        accountTrigger.setAttribute("aria-expanded", "false");
      }

      if (
        mobileNav &&
        mobileTrigger &&
        !mobileNav.contains(target) &&
        !mobileTrigger.contains(target)
      ) {
        removeClass(mobileNav, "is-open");
        mobileTrigger.setAttribute("aria-expanded", "false");
      }

      var legacyMenu = document.getElementById("dropdownMenu");

      if (
        legacyMenu &&
        !closest(target, ".menu-icon") &&
        !closest(target, "#dropdownMenu")
      ) {
        removeClass(legacyMenu, "show");
      }
    });
  });

  /* Toast messages are inserted as plain text. */
  var stack;

  function toast(message, type) {
    if (!message || !String(message).replace(/^\s+|\s+$/g, "")) {
      return;
    }

    if (["success", "error", "info"].indexOf(type) === -1) {
      type = "info";
    }

    if (!document.body) {
      return;
    }

    if (!stack) {
      stack = document.createElement("div");
      stack.className = "toast-stack";
      document.body.appendChild(stack);
    }

    var item = document.createElement("div");
    item.className = "toast toast-" + type;
    item.setAttribute("role", type === "error" ? "alert" : "status");

    var icon = document.createElement("span");
    icon.className = "toast-icon";
    icon.setAttribute("aria-hidden", "true");
    icon.textContent = {
      success: "\u2713",
      error: "!",
      info: "i"
    }[type];

    var text = document.createElement("p");
    text.textContent = message;

    var close = document.createElement("button");
    close.type = "button";
    close.textContent = "\u00D7";
    close.setAttribute("aria-label", "Dismiss notification");

    var timer;

    function dismiss() {
      clearTimeout(timer);
      removeElement(item);
    }

    close.onclick = dismiss;

    item.appendChild(icon);
    item.appendChild(text);
    item.appendChild(close);
    stack.appendChild(item);

    while (stack.children.length > 4) {
      removeElement(stack.children[0]);
    }

    function schedule() {
      clearTimeout(timer);
      timer = setTimeout(dismiss, type === "error" ? 9000 : 5500);
    }

    function pause() {
      clearTimeout(timer);
    }

    item.addEventListener("mouseenter", pause);
    item.addEventListener("mouseleave", schedule);
    item.addEventListener("focusin", pause);
    item.addEventListener("focusout", schedule);

    schedule();
  }

  window.AppToast = {
    success: function (message) {
      toast(message, "success");
    },
    error: function (message) {
      toast(message, "error");
    },
    info: function (message) {
      toast(message, "info");
    }
  };

  function notify(node) {
    var text = node.textContent.replace(/^\s+|\s+$/g, "");

    if (
      node.getAttribute("data-toast-shown") ||
      !text ||
      !node.getClientRects().length
    ) {
      return;
    }

    node.setAttribute("data-toast-shown", "true");

    var type = "info";

    if (
      hasClass(node, "error") ||
      /error|failed|incorrect|not match|not found|invalid|unable/i.test(text)
    ) {
      type = "error";
    } else if (/success|verified|updated|approved/i.test(text)) {
      type = "success";
    }

    toast(text, type);
  }

  function notifyAll(container, selector) {
    var nodes = container.querySelectorAll(selector);
    var i;

    for (i = 0; i < nodes.length; i++) {
      notify(nodes[i]);
    }
  }

  ready(function () {
    notifyAll(
      document,
      ".message,.error-message,.logout-message,[data-toast]"
    );

    try {
      var pending = window.sessionStorage.getItem("app-toast");

      if (pending) {
        window.sessionStorage.removeItem("app-toast");

        var value = JSON.parse(pending);
        toast(value.message, value.type);
      }
    } catch (error) {
      /* Continue when browser storage is unavailable. */
    }

    if (/(?:^\?|&)msg=password_updated(?:&|$)/.test(window.location.search)) {
      toast("Password updated successfully.", "success");
    }

    if (window.MutationObserver) {
      var observer = new MutationObserver(function (records) {
        var i;
        var j;

        for (i = 0; i < records.length; i++) {
          var record = records[i];

          var element =
            record.target.nodeType === 1
              ? record.target
              : record.target.parentElement;

          var message = element
            ? closest(element, ".message,.error-message")
            : null;

          if (message) {
            message.removeAttribute("data-toast-shown");
            notify(message);
          }

          for (j = 0; j < record.addedNodes.length; j++) {
            var node = record.addedNodes[j];

            if (
              node.nodeType === 1 &&
              !closest(node, ".toast-stack")
            ) {
              if (matches(node, ".message,.error-message,[data-toast]")) {
                notify(node);
              }

              notifyAll(node, ".message,.error-message,[data-toast]");
            }
          }
        }
      });

      observer.observe(document.body, {
        subtree: true,
        childList: true,
        characterData: true
      });
    }
  });
})();